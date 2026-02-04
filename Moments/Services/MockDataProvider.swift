//
//  MockDataProvider.swift
//  Moments
//
//  Mock 数据提供器 (开发阶段使用)
//

import Foundation

enum MockDataProvider {
    // MARK: - Sample Images (Unsplash)

    private static let sampleImages: [[ThoughtImage]] = [
        // 单张图片
        [
            ThoughtImage(
                url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200",
                width: 1200,
                height: 800,
                blurhash: nil
            )
        ],
        // 两张图片
        [
            ThoughtImage(
                url: "https://images.unsplash.com/photo-1682687220742-aba13b6e50ba?w=800",
                width: 800,
                height: 800,
                blurhash: nil
            ),
            ThoughtImage(
                url: "https://images.unsplash.com/photo-1682687221038-404670f01d03?w=800",
                width: 800,
                height: 800,
                blurhash: nil
            )
        ],
        // 三张图片
        [
            ThoughtImage(url: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=600", width: 600, height: 900, blurhash: nil),
            ThoughtImage(url: "https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=600", width: 600, height: 400, blurhash: nil),
            ThoughtImage(url: "https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=600", width: 600, height: 400, blurhash: nil)
        ],
        // 四张图片
        [
            ThoughtImage(url: "https://images.unsplash.com/photo-1518173946687-a4c036bc9a5e?w=500", width: 500, height: 500, blurhash: nil),
            ThoughtImage(url: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500", width: 500, height: 500, blurhash: nil),
            ThoughtImage(url: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500", width: 500, height: 500, blurhash: nil),
            ThoughtImage(url: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=500", width: 500, height: 500, blurhash: nil)
        ],
        // 无图片
        []
    ]

    // MARK: - Sample Content

    private static let sampleContents: [String] = [
        "今天天气真好，出去走了走，拍了几张照片。阳光洒在脸上，感觉整个人都温暖了起来。",
        "学习 SwiftUI 第三天了，感觉声明式 UI 的思路和 React 确实很像。@State 就是 useState，.task 就是 useEffect。",
        "突然想到一个点子：用 AI 来自动整理笔记，根据内容自动打标签。回头研究一下怎么实现。",
        "深夜写代码，窗外下着小雨。这种安静的氛围特别适合思考。",
        "今天读完了《黑客与画家》，Paul Graham 的很多观点现在看来依然很有启发性。创业就像跑马拉松，重要的不是起跑速度，而是持续前进。",
        "周末尝试做了一道新菜，红烧肉。虽然卖相一般，但味道还不错！下次改进一下火候。",
        "公司的项目终于上线了！熬了几个通宵，看到用户的正面反馈，感觉一切都值得。",
        "整理了一下书架，发现好多书都没读完。制定了一个计划，每周至少读完一本。"
    ]

    private static let sampleTags: [[String]] = [
        ["日常", "摄影"],
        ["学习", "iOS", "编程"],
        ["想法", "AI"],
        ["夜晚", "编程"],
        ["读书", "思考"],
        ["美食", "周末"],
        ["工作", "成就"],
        ["读书", "计划"]
    ]

    // MARK: - Generate Mock Data

    static func generateThoughts(count: Int = 10) -> [Thought] {
        var thoughts: [Thought] = []

        for i in 0..<count {
            let contentIndex = i % sampleContents.count
            let imageIndex = i % sampleImages.count
            let tagIndex = i % sampleTags.count

            let daysAgo = Double(i)
            let createdAt = Date().addingTimeInterval(-daysAgo * 86400 - Double.random(in: 0...43200))

            let thought = Thought(
                id: "mock_\(UUID().uuidString.prefix(8))",
                content: sampleContents[contentIndex],
                images: sampleImages[imageIndex],
                tags: sampleTags[tagIndex],
                createdAt: createdAt,
                updatedAt: createdAt,
                visibility: .public
            )

            thoughts.append(thought)
        }

        return thoughts.sorted { $0.createdAt > $1.createdAt }
    }

    static func generatePaginatedResponse(page: Int, pageSize: Int = 10) -> PaginatedResponse<Thought> {
        let allThoughts = generateThoughts(count: 30)
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, allThoughts.count)

        let items = startIndex < allThoughts.count
            ? Array(allThoughts[startIndex..<endIndex])
            : []

        let totalPages = Int(ceil(Double(allThoughts.count) / Double(pageSize)))

        return PaginatedResponse(
            items: items,
            page: page,
            limit: pageSize,
            total: allThoughts.count,
            totalPages: totalPages,
            hasMore: page < totalPages
        )
    }
}
