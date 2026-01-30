//
//  TagChip.swift
//  Moments
//
//  标签 Chip 组件
//

import SwiftUI

struct TagChip: View {
    let tag: String
    var isSelected: Bool = false
    var size: Size = .medium
    var onTap: (() -> Void)?

    enum Size {
        case small
        case medium

        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8)
            case .medium: return EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
            }
        }
    }

    var body: some View {
        Text("#\(tag)")
            .font(size.font)
            .fontWeight(.medium)
            .foregroundStyle(isSelected ? .white : .secondary)
            .padding(size.padding)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .contentShape(Capsule())
            .onTapGesture {
                HapticManager.selection()
                onTap?()
            }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 8) {
        TagChip(tag: "日常", isSelected: true)
        TagChip(tag: "学习", isSelected: false)
        TagChip(tag: "iOS", isSelected: false, size: .small)
    }
    .padding()
}
