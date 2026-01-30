//
//  ThoughtDetailView.swift
//  Moments
//
//  详情页
//

import SwiftUI

struct ThoughtDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let thought: Thought
    var onEdit: ((Thought) -> Void)?
    var onDelete: (() -> Void)?

    @State private var selectedImageIndex: Int?
    @State private var showDeleteConfirm = false
    @State private var showEditSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 内容
                    Text(thought.content)
                        .font(.body)
                        .foregroundStyle(.primary)

                    // 图片
                    if !thought.images.isEmpty {
                        ThoughtImageGrid(images: thought.images) { index in
                            selectedImageIndex = index
                        }
                    }

                    // 标签
                    if !thought.tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(thought.tags, id: \.self) { tag in
                                TagChip(tag: tag, isSelected: false)
                            }
                        }
                    }

                    // 时间信息
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(thought.fullFormattedDate)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if thought.createdAt != thought.updatedAt {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                Text("编辑于 \(formatDate(thought.updatedAt))")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog(
                "确定要删除这条想法吗？",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("删除", role: .destructive) {
                    HapticManager.warning()
                    onDelete?()
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后无法恢复")
            }
            .sheet(isPresented: $showEditSheet) {
                ComposeView(editingThought: thought) { updatedThought in
                    onEdit?(updatedThought)
                }
            }
            .fullScreenCover(item: $selectedImageIndex) { index in
                ImageGalleryView(
                    images: thought.images,
                    initialIndex: index
                )
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Int Extension for Identifiable

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

// MARK: - Preview

#Preview {
    ThoughtDetailView(
        thought: Thought(
            content: "今天天气真好，出去走了走，拍了几张照片。阳光洒在脸上，感觉整个人都温暖了起来。\n\n这种感觉真的很棒。",
            images: [
                ThoughtImage(
                    url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                    width: 800,
                    height: 600,
                    blurhash: nil
                )
            ],
            tags: ["日常", "摄影", "心情"]
        )
    )
}
