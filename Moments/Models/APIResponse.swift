//
//  APIResponse.swift
//  Moments
//
//  API 响应包装
//

import Foundation

struct APIResponse<T: Codable>: Codable {
    let code: Int
    let msg: String
    let data: T?

    var isSuccess: Bool {
        code == 0
    }
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int

    var hasMore: Bool {
        page < totalPages
    }
}

// MARK: - Convenience Types

typealias ThoughtListResponse = APIResponse<PaginatedResponse<Thought>>
typealias ThoughtResponse = APIResponse<Thought>
typealias EmptyResponse = APIResponse<EmptyData>

struct EmptyData: Codable {}
