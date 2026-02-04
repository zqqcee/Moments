//
//  APIClient.swift
//  Moments
//
//  基础网络请求封装
//

import Foundation

actor APIClient {
    static let shared = APIClient()

    // TODO: 替换为真实的 API 地址
//    private let baseURL = "https://api.luckycc.cc"
    private let baseURL = "http://localhost:1234"
    private var authToken: String?

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) {
                return date
            }
            // 兜底：不带毫秒的格式
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
        }
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private init() {}

    // MARK: - Configuration

    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    // MARK: - Request Methods

    func get<T: Codable>(_ endpoint: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: "GET", queryItems: queryItems)
        return try await performRequest(request)
    }

    func post<T: Codable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: "POST")
        request.httpBody = try encoder.encode(body)
        return try await performRequest(request)
    }

    func put<T: Codable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: "PUT")
        request.httpBody = try encoder.encode(body)
        return try await performRequest(request)
    }

    func delete<T: Codable>(_ endpoint: String) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: "DELETE")
        return try await performRequest(request)
    }

    // MARK: - Private Helpers

    private func buildRequest(
        endpoint: String,
        method: String,
        queryItems: [URLQueryItem]? = nil
    ) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + endpoint) else {
            throw AppError.invalidURL
        }

        if let queryItems = queryItems {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw AppError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func performRequest<T: Codable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AppError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.unknown
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw AppError.unauthorized
        case 404:
            throw AppError.notFound
        default:
            throw AppError.serverError(code: httpResponse.statusCode, message: "服务器错误")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decodingError(underlying: error)
        }
    }
}
