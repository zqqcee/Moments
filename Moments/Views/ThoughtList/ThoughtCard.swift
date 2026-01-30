//
//  ThoughtCard.swift
//  Moments
//
//  单条想法卡片
//

import SwiftUI

struct ThoughtCard: View {
    let thought: Thought
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 内容
            Text(thought.content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(6)
                .multilineTextAlignment(.leading)

            // 图片网格
            if !thought.images.isEmpty {
                ThoughtImageGrid(images: thought.images)
            }

            // 底部信息栏
            HStack(spacing: 12) {
                // 标签
                if !thought.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(thought.tags.prefix(3), id: \.self) { tag in
                            TagChip(tag: tag, isSelected: false, size: .small)
                        }

                        if thought.tags.count > 3 {
                            Text("+\(thought.tags.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // 时间
                Text(thought.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("删除", systemImage: "trash")
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
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复")
        }

        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            ThoughtCard(
                thought: Thought(
                    content: "今天天气真好，出去走了走，拍了几张照片。阳光洒在脸上，感觉整个人都温暖了起来。",
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

            ThoughtCard(
                thought: Thought(
                    content: "学习 SwiftUI 的第一天，感觉声明式 UI 和 React 很像。",
                    tags: ["学习", "iOS"]
                )
            )
        }
    }
}
