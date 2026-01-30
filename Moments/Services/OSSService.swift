//
//  OSSService.swift
//  Moments
//
//  阿里云 OSS 图片上传服务
//

import Foundation
import CryptoKit
import UIKit

actor OSSService {
    static let shared = OSSService()

    // MARK: - OSS 配置 (从 Secrets.swift 读取)

    private let accessKeyId = Secrets.ossAccessKeyId
    private let accessKeySecret = Secrets.ossAccessKeySecret
    private let bucket = Secrets.ossBucket
    private let endpoint = Secrets.ossEndpoint
    private let uploadDir = "moments"  // 上传目录

    private init() {}

    // MARK: - Public Methods

    /// 上传单张图片
    /// - Parameters:
    ///   - imageData: 图片数据
    ///   - width: 图片宽度
    ///   - height: 图片高度
    /// - Returns: ThoughtImage 包含 OSS URL
    func uploadImage(_ imageData: Data, width: Int, height: Int) async throws -> ThoughtImage {
        let fileName = generateFileName()
        let objectKey = "\(uploadDir)/\(fileName)"

        let url = try await putObject(data: imageData, objectKey: objectKey, contentType: "image/jpeg")

        return ThoughtImage(
            url: url,
            width: width,
            height: height,
            blurhash: nil
        )
    }

    /// 批量上传图片
    /// - Parameter images: (图片数据, 宽度, 高度) 元组数组
    /// - Returns: ThoughtImage 数组
    func uploadImages(_ images: [(data: Data, width: Int, height: Int)]) async throws -> [ThoughtImage] {
        var results: [ThoughtImage] = []

        for image in images {
            let thoughtImage = try await uploadImage(image.data, width: image.width, height: image.height)
            results.append(thoughtImage)
        }

        return results
    }

    // MARK: - Private Methods

    private func putObject(data: Data, objectKey: String, contentType: String) async throws -> String {
        let urlString = "\(endpoint)/\(objectKey)"

        guard let url = URL(string: urlString) else {
            print("[OSS] Invalid URL: \(urlString)")
            throw AppError.invalidURL
        }

        let date = httpDateString()
        let contentMD5 = ""  // 可选，留空

        // 构建签名字符串
        let stringToSign = "PUT\n\(contentMD5)\n\(contentType)\n\(date)\n/\(bucket)/\(objectKey)"
        let signature = hmacSHA1(stringToSign, key: accessKeySecret)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(date, forHTTPHeaderField: "Date")
        request.setValue("OSS \(accessKeyId):\(signature)", forHTTPHeaderField: "Authorization")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")

        print("[OSS] Uploading to: \(urlString)")
        print("[OSS] Data size: \(data.count) bytes")

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[OSS] Invalid response type")
                throw AppError.unknown
            }

            print("[OSS] Response status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                let responseBody = String(data: responseData, encoding: .utf8) ?? "N/A"
                print("[OSS] Upload failed - Status: \(httpResponse.statusCode)")
                print("[OSS] Response body: \(responseBody)")
                throw AppError.serverError(code: httpResponse.statusCode, message: "OSS 上传失败: \(responseBody)")
            }

            print("[OSS] Upload success: \(urlString)")
            return urlString
        } catch let error as AppError {
            throw error
        } catch {
            print("[OSS] Network error: \(error.localizedDescription)")
            throw AppError.networkError(underlying: error)
        }
    }

    private func generateFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let datePath = dateFormatter.string(from: Date())

        let uuid = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)

        return "\(datePath)/\(timestamp)_\(uuid.prefix(8)).jpg"
    }

    private func httpDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter.string(from: Date())
    }

    private func hmacSHA1(_ string: String, key: String) -> String {
        let keyData = Data(key.utf8)
        let messageData = Data(string.utf8)

        let symmetricKey = SymmetricKey(data: keyData)
        let signature = HMAC<Insecure.SHA1>.authenticationCode(for: messageData, using: symmetricKey)

        return Data(signature).base64EncodedString()
    }
}
