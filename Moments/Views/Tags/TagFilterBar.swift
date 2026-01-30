//
//  TagFilterBar.swift
//  Moments
//
//  标签筛选栏 (横向滚动)
//

import SwiftUI

struct TagFilterBar: View {
    let tags: [String]
    let selectedTag: String?
    var onSelect: ((String?) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "全部" 选项
                TagChip(
                    tag: "全部",
                    isSelected: selectedTag == nil,
                    onTap: {
                        onSelect?(nil)
                    }
                )

                // 标签列表
                ForEach(tags, id: \.self) { tag in
                    TagChip(
                        tag: tag,
                        isSelected: selectedTag == tag,
                        onTap: {
                            if selectedTag == tag {
                                onSelect?(nil)
                            } else {
                                onSelect?(tag)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        TagFilterBar(
            tags: ["日常", "学习", "iOS", "读书", "摄影"],
            selectedTag: "学习"
        )

        TagFilterBar(
            tags: ["日常", "学习", "iOS", "读书", "摄影"],
            selectedTag: nil
        )
    }
}
