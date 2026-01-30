//
//  ComposeView.swift
//  Moments
//
//  发布主界面 (Sheet 模态)
//

import SwiftUI
import PhotosUI

struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ComposeViewModel()
    @State private var showImagePicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @FocusState private var isContentFocused: Bool

    var editingThought: Thought?
    var onPublished: ((Thought) -> Void)?
    var onUpdated: ((Thought) -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 文字输入区
                    contentEditor

                    // 已选图片预览
                    if !viewModel.selectedImages.isEmpty {
                        selectedImagesGrid
                    }

                    // 标签输入
                    TagInput(tags: viewModel.tags) { tag in
                        viewModel.addTag(tag)
                    } onRemove: { tag in
                        viewModel.removeTag(tag)
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(viewModel.isEditing ? "编辑想法" : "记录想法")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    publishButton
                }

                ToolbarItem(placement: .keyboard) {
                    keyboardToolbar
                }
            }
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $selectedPhotoItems,
                maxSelectionCount: viewModel.remainingImageSlots,
                matching: .images
            )
            .onChange(of: selectedPhotoItems) { _, newItems in
                Task {
                    await loadSelectedImages(newItems)
                }
            }
            .onAppear {
                viewModel.configure(for: editingThought)
                isContentFocused = true
            }
        }
        .interactiveDismissDisabled(viewModel.isPublishing)
    }

    // MARK: - Content Editor

    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(
                "记录此刻的想法...",
                text: $viewModel.content,
                axis: .vertical
            )
            .font(.body)
            .lineLimit(3...15)
            .focused($isContentFocused)

            HStack {
                Spacer()
                Text("\(viewModel.characterCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Selected Images Grid

    private var selectedImagesGrid: some View {
        SelectedImagesGrid(
            images: viewModel.selectedImages,
            onRemove: { image in
                withAnimation {
                    viewModel.removeImage(image)
                }
            },
            onMove: { source, destination in
                viewModel.moveImage(from: source, to: destination)
            }
        )
    }

    // MARK: - Publish Button

    private var publishButton: some View {
        Button {
            Task {
                if let thought = await viewModel.publish() {
                    if viewModel.isEditing {
                        onUpdated?(thought)
                    } else {
                        onPublished?(thought)
                    }
                    dismiss()
                }
            }
        } label: {
            if viewModel.isPublishing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Text("发布")
                    .fontWeight(.semibold)
            }
        }
        .disabled(!viewModel.canPublish)
    }

    // MARK: - Keyboard Toolbar

    private var keyboardToolbar: some View {
        HStack {
            Button {
                showImagePicker = true
            } label: {
                Image(systemName: "photo")
                    .font(.system(size: 20))
            }
            .disabled(viewModel.remainingImageSlots <= 0)

            Text("\(viewModel.selectedImages.count)/9")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                isContentFocused = false
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
            }
        }
    }

    // MARK: - Load Images

    private func loadSelectedImages(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                // 验证图片尺寸有效
                guard uiImage.size.width > 0, uiImage.size.height > 0 else {
                    continue
                }

                // 强制重绘为标准 sRGB，避免 HDR 处理错误
                let normalizedImage = normalizeImage(uiImage)
                let compressed = ImageCompressor.compress(normalizedImage)

                // 确保宽高有效
                let width = max(1, Int(compressed.size.width))
                let height = max(1, Int(compressed.size.height))

                let selected = SelectedImage(
                    id: UUID(),
                    image: compressed.image,
                    url: nil,
                    width: width,
                    height: height
                )
                await MainActor.run {
                    viewModel.addImage(selected)
                }
            }
        }

        await MainActor.run {
            selectedPhotoItems = []
        }
    }

    /// 将图片重绘为标准 sRGB 格式，消除 HDR 元数据
    private func normalizeImage(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.preferredRange = .standard  // 强制使用标准色彩范围
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

// MARK: - Preview

#Preview {
    ComposeView()
}
