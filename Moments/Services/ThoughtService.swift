//
//  ThoughtService.swift
//  Moments
//
//  Thought CRUD 接口
//

import Foundation

protocol ThoughtServiceProtocol {
    func getThoughts(page: Int, pageSize: Int, tag: String?) async throws -> PaginatedResponse<Thought>
    func getThought(id: String) async throws -> Thought
    func createThought(_ thought: CreateThoughtRequest) async throws -> Thought
    func updateThought(id: String, _ thought: UpdateThoughtRequest) async throws -> Thought
    func deleteThought(id: String) async throws
}

// MARK: - Request Types

struct CreateThoughtRequest: Encodable {
    let content: String
    let images: [ThoughtImage]
    let tags: [String]
    let visibility: Visibility?
}

struct UpdateThoughtRequest: Encodable {
    let content: String?
    let images: [ThoughtImage]?
    let tags: [String]?
    let visibility: Visibility?
}

// MARK: - Mock Implementation

final class MockThoughtService: ThoughtServiceProtocol {
    private var thoughts: [Thought]
    private let delay: UInt64 = 500_000_000 // 0.5 秒模拟网络延迟

    init() {
        self.thoughts = MockDataProvider.generateThoughts(count: 30)
    }

    func getThoughts(page: Int, pageSize: Int = 10, tag: String? = nil) async throws -> PaginatedResponse<Thought> {
        try await Task.sleep(nanoseconds: delay)

        var filtered = thoughts

        if let tag = tag, !tag.isEmpty {
            filtered = thoughts.filter { $0.tags.contains(tag) }
        }

        let sorted = filtered.sorted { $0.createdAt > $1.createdAt }
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, sorted.count)

        let items = startIndex < sorted.count ? Array(sorted[startIndex..<endIndex]) : []
        let totalPages = max(1, Int(ceil(Double(sorted.count) / Double(pageSize))))

        return PaginatedResponse(
            items: items,
            page: page,
            limit: pageSize,
            total: sorted.count,
            totalPages: totalPages,
            hasMore: page < totalPages
        )
    }

    func getThought(id: String) async throws -> Thought {
        try await Task.sleep(nanoseconds: delay)

        guard let thought = thoughts.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }

        return thought
    }

    func createThought(_ request: CreateThoughtRequest) async throws -> Thought {
        try await Task.sleep(nanoseconds: delay)

        let thought = Thought(
            id: "mock_\(UUID().uuidString.prefix(8))",
            content: request.content,
            images: request.images,
            tags: request.tags,
            createdAt: Date(),
            updatedAt: Date(),
            visibility: request.visibility ?? .public
        )

        thoughts.insert(thought, at: 0)
        return thought
    }

    func updateThought(id: String, _ request: UpdateThoughtRequest) async throws -> Thought {
        try await Task.sleep(nanoseconds: delay)

        guard let index = thoughts.firstIndex(where: { $0.id == id }) else {
            throw AppError.notFound
        }

        var thought = thoughts[index]

        if let content = request.content { thought.content = content }
        if let images = request.images { thought.images = images }
        if let tags = request.tags { thought.tags = tags }
        if let visibility = request.visibility { thought.visibility = visibility }

        thought.updatedAt = Date()
        thoughts[index] = thought

        return thought
    }

    func deleteThought(id: String) async throws {
        try await Task.sleep(nanoseconds: delay)

        guard let index = thoughts.firstIndex(where: { $0.id == id }) else {
            throw AppError.notFound
        }

        thoughts.remove(at: index)
    }
}

// MARK: - Real Implementation (TODO)

final class ThoughtService: ThoughtServiceProtocol {
    private let client = APIClient.shared

    func getThoughts(page: Int, pageSize: Int = 10, tag: String? = nil) async throws -> PaginatedResponse<Thought> {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(pageSize))
        ]

        if let tag = tag, !tag.isEmpty {
            queryItems.append(URLQueryItem(name: "tag", value: tag))
        }

        let response: ThoughtListResponse = try await client.get("/moments", queryItems: queryItems)

        guard response.isSuccess, let data = response.data else {
            throw AppError.serverError(code: response.code, message: response.msg)
        }

        return data
    }

    func getThought(id: String) async throws -> Thought {
        let response: ThoughtResponse = try await client.get("/moments/\(id)")

        guard response.isSuccess, let data = response.data else {
            throw AppError.serverError(code: response.code, message: response.msg)
        }

        return data
    }

    func createThought(_ request: CreateThoughtRequest) async throws -> Thought {
        let response: ThoughtResponse = try await client.post("/moments", body: request)

        guard response.isSuccess, let data = response.data else {
            throw AppError.serverError(code: response.code, message: response.msg)
        }

        return data
    }

    func updateThought(id: String, _ request: UpdateThoughtRequest) async throws -> Thought {
        let response: ThoughtResponse = try await client.put("/moments/\(id)", body: request)

        guard response.isSuccess, let data = response.data else {
            throw AppError.serverError(code: response.code, message: response.msg)
        }

        return data
    }

    func deleteThought(id: String) async throws {
        let response: EmptyResponse = try await client.delete("/moments/\(id)")

        guard response.isSuccess else {
            throw AppError.serverError(code: response.code, message: response.msg)
        }
    }
}
