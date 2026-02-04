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
    let items: [T]
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasMore: Bool

    // 兼容旧代码
    var data: [T] { items }
    var pagination: Pagination {
        Pagination(page: page, pageSize: limit, total: total, totalPages: totalPages, hasMore: hasMore)
    }
}

struct Pagination: Codable {
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int
    let hasMore: Bool
}

// MARK: - Convenience Types

typealias ThoughtListResponse = APIResponse<PaginatedResponse<Thought>>
typealias ThoughtResponse = APIResponse<Thought>
typealias EmptyResponse = APIResponse<EmptyData>

struct EmptyData: Codable {}
