//
//  AppError.swift
//  Moments
//
//  错误类型定义
//

import Foundation

enum AppError: LocalizedError {
    case networkError(underlying: Error)
    case serverError(code: Int, message: String)
    case decodingError(underlying: Error)
    case invalidURL
    case unauthorized
    case notFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "网络连接失败: \(error.localizedDescription)"
        case .serverError(_, let message):
            return message
        case .decodingError:
            return "数据解析失败"
        case .invalidURL:
            return "无效的请求地址"
        case .unauthorized:
            return "请重新登录"
        case .notFound:
            return "内容不存在"
        case .unknown:
            return "发生未知错误"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "请检查网络连接后重试"
        case .serverError:
            return "请稍后重试"
        case .decodingError:
            return "请更新应用后重试"
        case .invalidURL:
            return "请联系开发者"
        case .unauthorized:
            return "请重新登录后重试"
        case .notFound:
            return "该内容可能已被删除"
        case .unknown:
            return "请稍后重试"
        }
    }
}
