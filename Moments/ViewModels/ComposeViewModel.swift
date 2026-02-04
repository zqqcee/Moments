//
//  ComposeViewModel.swift
//  Moments
//
//  发布状态管理
//

import Foundation
import SwiftUI
import PhotosUI

@Observable
final class ComposeViewModel {
    // MARK: - State

    var content: String = ""
    var selectedImages: [SelectedImage] = []
    var tags: [String] = []
    var isPublishing = false
    var error: AppError?

    // 编辑模式
    var editingThought: Thought?
    var isEditing: Bool { editingThought != nil }

    // MARK: - Service

    private let service: ThoughtServiceProtocol

    init(service: ThoughtServiceProtocol = ThoughtService()) {
        self.service = service
    }

    // MARK: - Configuration

    func configure(for thought: Thought?) {
        guard let thought = thought else { return }

        editingThought = thought
        content = thought.content
        tags = thought.tags

        // 转换已有图片
        selectedImages = thought.images.map { image in
            SelectedImage(
                id: UUID(),
                image: nil,
                url: image.url,
                width: image.width,
                height: image.height
            )
        }
    }

    // MARK: - Actions

    @MainActor
    func publish() async -> Thought? {
        guard canPublish else { return nil }

        isPublishing = true
        error = nil

        do {
            // 上传图片到 OSS
            var images: [ThoughtImage] = []

            for selected in selectedImages {
                if let url = selected.url {
                    // 已有 URL（编辑模式下的已有图片）
                    images.append(ThoughtImage(
                        url: url,
                        width: selected.width,
                        height: selected.height,
                        blurhash: nil
                    ))
                } else if let uiImage = selected.image {
                    // 新图片，需要压缩并上传到 OSS
                    let compressed = ImageCompressor.compress(uiImage)
                    let blurhash = ImageCompressor.generateBlurhash(uiImage)
                    print("[Publish] Compressed image - size: \(compressed.size), data: \(compressed.data.count) bytes, blurhash: \(blurhash ?? "nil")")

                    guard !compressed.data.isEmpty else {
                        print("[Publish] ERROR: Compressed data is empty!")
                        continue
                    }

                    let thoughtImage = try await OSSService.shared.uploadImage(
                        compressed.data,
                        width: Int(compressed.size.width),
                        height: Int(compressed.size.height),
                        blurhash: blurhash
                    )
                    images.append(thoughtImage)
                }
            }

            let thought: Thought

            if let editing = editingThought {
                // 更新
                let request = UpdateThoughtRequest(
                    content: content,
                    images: images,
                    tags: tags,
                    visibility: nil
                )
                thought = try await service.updateThought(id: editing.id, request)
            } else {
                // 创建
                let request = CreateThoughtRequest(
                    content: content,
                    images: images,
                    tags: tags,
                    visibility: .public
                )
                thought = try await service.createThought(request)
            }

            HapticManager.success()
            reset()
            isPublishing = false
            return thought

        } catch let appError as AppError {
            error = appError
            HapticManager.error()
        } catch {
            self.error = .networkError(underlying: error)
            HapticManager.error()
        }

        isPublishing = false
        return nil
    }

    func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }

        HapticManager.selection()
        tags.append(trimmed)
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    func addImage(_ image: SelectedImage) {
        guard selectedImages.count < 9 else { return }
        selectedImages.append(image)
    }

    func removeImage(_ image: SelectedImage) {
        selectedImages.removeAll { $0.id == image.id }
    }

    func moveImage(from source: IndexSet, to destination: Int) {
        selectedImages.move(fromOffsets: source, toOffset: destination)
    }

    func reset() {
        content = ""
        selectedImages = []
        tags = []
        editingThought = nil
    }

    // MARK: - Computed Properties

    var canPublish: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isPublishing
    }

    var characterCount: Int {
        content.count
    }

    var remainingImageSlots: Int {
        9 - selectedImages.count
    }
}

// MARK: - Selected Image

struct SelectedImage: Identifiable, Equatable {
    let id: UUID
    var image: UIImage?
    var url: String?
    var width: Int
    var height: Int

    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }

    static func == (lhs: SelectedImage, rhs: SelectedImage) -> Bool {
        lhs.id == rhs.id
    }
}
