//
//  ImageCompressor.swift
//  Moments
//
//  图片压缩 (最大 1.5MB, 宽度 ≤1920) & BlurHash 生成
//

import UIKit

enum ImageCompressor {
    static let maxWidth: CGFloat = 1920
    static let maxFileSize: Int = 1_500_000  // 1.5MB
    static let initialQuality: CGFloat = 0.7
    static let minQuality: CGFloat = 0.3

    struct CompressResult {
        let image: UIImage
        let data: Data
        let size: CGSize
    }

    static func compress(_ image: UIImage) -> CompressResult {
        var currentImage = resizeIfNeeded(image, maxWidth: maxWidth)
        var quality = initialQuality
        var data = currentImage.jpegData(compressionQuality: quality) ?? Data()

        // 逐步降低质量直到满足大小限制
        while data.count > maxFileSize && quality > minQuality {
            quality -= 0.1
            data = currentImage.jpegData(compressionQuality: quality) ?? Data()
        }

        // 如果质量已最低但仍超限，继续缩小尺寸
        var currentMaxWidth = maxWidth
        while data.count > maxFileSize && currentMaxWidth > 800 {
            currentMaxWidth -= 200
            currentImage = resizeIfNeeded(image, maxWidth: currentMaxWidth)
            data = currentImage.jpegData(compressionQuality: minQuality) ?? Data()
        }

        // 确保尺寸有效，防止 NaN
        var size = currentImage.size
        if size.width <= 0 || size.width.isNaN || size.width.isInfinite {
            size.width = image.size.width > 0 ? image.size.width : 100
        }
        if size.height <= 0 || size.height.isNaN || size.height.isInfinite {
            size.height = image.size.height > 0 ? image.size.height : 100
        }

        print("[Compress] Final: \(Int(size.width))x\(Int(size.height)), quality: \(quality), size: \(data.count / 1024)KB")

        return CompressResult(
            image: currentImage,
            data: data,
            size: size
        )
    }

    static func compressToData(_ image: UIImage) -> Data? {
        return compress(image).data
    }

    private static func resizeIfNeeded(_ image: UIImage, maxWidth: CGFloat) -> UIImage {
        guard image.size.width > maxWidth else {
            return image
        }

        let ratio = maxWidth / image.size.width
        let newSize = CGSize(
            width: maxWidth,
            height: image.size.height * ratio
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - BlurHash

    /// 生成 blurhash（使用缩小的图片提高性能）
    static func generateBlurhash(_ image: UIImage) -> String? {
        // 缩小到 32x32 提高编码速度
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        let smallImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        return smallImage.blurHash(numberOfComponents: (4, 3))
    }
}
