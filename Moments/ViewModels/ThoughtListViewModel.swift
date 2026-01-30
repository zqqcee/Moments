//
//  ThoughtListViewModel.swift
//  Moments
//
//  列表状态管理
//

import Foundation
import SwiftUI

enum SlideDirection {
    case left
    case right
    case none
}

@Observable
final class ThoughtListViewModel {
    // MARK: - State

    var thoughts: [Thought] = []
    var isLoading = false
    var isLoadingMore = false
    var error: AppError?
    var selectedTag: String?
    var slideDirection: SlideDirection = .none

    // 保存所有可用标签（不受过滤影响）
    private var _allAvailableTags: [String] = []

    // MARK: - Pagination

    private var currentPage = 1
    private var hasMore = true
    private let pageSize = 10

    // MARK: - Service

    private let service: ThoughtServiceProtocol

    init(service: ThoughtServiceProtocol = MockThoughtService()) {
        self.service = service
    }

    // MARK: - Actions

    @MainActor
    func loadThoughts() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let response = try await service.getThoughts(page: 1, pageSize: pageSize, tag: selectedTag)
            withAnimation(.easeOut(duration: 0.4)) {
                thoughts = response.data
            }
            hasMore = response.pagination.hasMore
            currentPage = 1

            // 只在未过滤时更新所有可用标签
            if selectedTag == nil {
                _allAvailableTags = Array(Set(thoughts.flatMap { $0.tags })).sorted()
            }
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .networkError(underlying: error)
        }

        isLoading = false
    }

    @MainActor
    func loadMore() async {
        guard !isLoading, !isLoadingMore, hasMore else { return }

        isLoadingMore = true

        do {
            let nextPage = currentPage + 1
            let response = try await service.getThoughts(page: nextPage, pageSize: pageSize, tag: selectedTag)

            thoughts.append(contentsOf: response.data)
            hasMore = response.pagination.hasMore
            currentPage = nextPage

            // 只在未过滤时更新所有可用标签
            if selectedTag == nil {
                let newTags = Set(response.data.flatMap { $0.tags })
                _allAvailableTags = Array(Set(_allAvailableTags).union(newTags)).sorted()
            }
        } catch {
            // 加载更多失败时静默处理
        }

        isLoadingMore = false
    }

    @MainActor
    func refresh() async {
        await loadThoughts()
    }

    @MainActor
    func filterByTag(_ tag: String?) async {
        // 计算滑动方向
        let oldIndex = selectedTag.flatMap { _allAvailableTags.firstIndex(of: $0) } ?? -1
        let newIndex = tag.flatMap { _allAvailableTags.firstIndex(of: $0) } ?? -1

        if newIndex > oldIndex {
            slideDirection = .right
        } else if newIndex < oldIndex {
            slideDirection = .left
        } else {
            slideDirection = .none
        }

        // 先清空旧内容并触发离开动画
        withAnimation(.easeInOut(duration: 0.25)) {
            thoughts = []
        }

        // 等待离开动画完成
        try? await Task.sleep(nanoseconds: 250_000_000)

        selectedTag = tag
        await loadThoughts()
    }

    @MainActor
    func deleteThought(_ thought: Thought) async -> Bool {
        do {
            try await service.deleteThought(id: thought.id)

            withAnimation(.easeOut(duration: 0.3)) {
                thoughts.removeAll { $0.id == thought.id }
            }

            HapticManager.notification(.success)
            return true
        } catch {
            HapticManager.notification(.error)
            return false
        }
    }

    @MainActor
    func addThought(_ thought: Thought) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            thoughts.insert(thought, at: 0)
        }
    }

    @MainActor
    func updateThought(_ thought: Thought) {
        if let index = thoughts.firstIndex(where: { $0.id == thought.id }) {
            thoughts[index] = thought
        }
    }

    // MARK: - Computed Properties

    var allTags: [String] {
        _allAvailableTags
    }

    var isEmpty: Bool {
        thoughts.isEmpty && !isLoading
    }

    var canLoadMore: Bool {
        !isLoading && !isLoadingMore && hasMore && !thoughts.isEmpty
    }
}
