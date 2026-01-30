//
//  TagInput.swift
//  Moments
//
//  标签输入组件
//

import SwiftUI

struct TagInput: View {
    let tags: [String]
    var onAdd: ((String) -> Void)?
    var onRemove: ((String) -> Void)?

    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    // 常用标签建议
    private let suggestions = ["日常", "学习", "工作", "读书", "摄影", "美食", "旅行", "随想"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            Text("标签")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 已选标签
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.caption)
                                .fontWeight(.medium)

                            Button {
                                onRemove?(tag)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                    }
                }
            }

            // 输入框
            HStack {
                TextField("添加标签", text: $inputText)
                    .font(.subheadline)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        submitTag()
                    }

                if !inputText.isEmpty {
                    Button {
                        submitTag()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )

            // 标签建议
            let availableSuggestions = suggestions.filter { !tags.contains($0) }
            if !availableSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableSuggestions, id: \.self) { suggestion in
                            Button {
                                onAdd?(suggestion)
                            } label: {
                                Text("#\(suggestion)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    private func submitTag() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        onAdd?(trimmed)
        inputText = ""
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Preview

#Preview {
    TagInput(tags: ["日常", "学习"])
        .padding()
}
