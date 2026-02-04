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
    var hasMore = true

    // MARK: - Pagination

    private var currentPage = 1
    private let pageSize = 20

    // 保存所有可用标签（不受过滤影响）
    private var _allAvailableTags: [String] = []

    // MARK: - Service

    private let service: ThoughtServiceProtocol

    init(service: ThoughtServiceProtocol = ThoughtService()) {
        self.service = service
    }

    // MARK: - Actions

    @MainActor
    func loadThoughts() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil
        currentPage = 1

        do {
            let response = try await service.getThoughts(page: currentPage, pageSize: pageSize, tag: selectedTag)

            withAnimation(.easeOut(duration: 0.4)) {
                thoughts = response.items
            }
            hasMore = response.hasMore

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
    func loadMoreThoughts() async {
        guard !isLoading && !isLoadingMore && hasMore else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            let response = try await service.getThoughts(page: currentPage, pageSize: pageSize, tag: selectedTag)

            withAnimation(.easeOut(duration: 0.3)) {
                thoughts.append(contentsOf: response.items)
            }
            hasMore = response.hasMore
        } catch {
            currentPage -= 1
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
}
