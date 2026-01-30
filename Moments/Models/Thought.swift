//
//  Thought.swift
//  Moments
//
//  核心数据模型
//

import Foundation

struct Thought: Codable, Identifiable, Equatable {
    let id: String
    var content: String
    var images: [ThoughtImage]
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date
    var visibility: Visibility?

    init(
        id: String = UUID().uuidString,
        content: String,
        images: [ThoughtImage] = [],
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        visibility: Visibility? = .public
    ) {
        self.id = id
        self.content = content
        self.images = images
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.visibility = visibility
    }
}

struct ThoughtImage: Codable, Identifiable, Equatable {
    var id: String { url }
    let url: String
    let width: Int
    let height: Int
    var blurhash: String?

    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }
}

enum Visibility: String, Codable {
    case `public` = "public"
    case `private` = "private"
    case unlisted = "unlisted"
}

// MARK: - Date Formatting Extension

extension Thought {
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var fullFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: createdAt)
    }
}
