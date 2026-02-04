//
//  BlurHash.swift
//  Moments
//
//  BlurHash 编码实现 (来自 woltapp/blurhash)
//

import UIKit

extension UIImage {
    func blurHash(numberOfComponents components: (Int, Int)) -> String? {
        let pixelWidth = Int(round(size.width * scale))
        let pixelHeight = Int(round(size.height * scale))

        let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: pixelWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        guard let context = context, let cgImage = cgImage else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))

        guard let data = context.data else { return nil }

        let pixels = data.bindMemory(to: UInt32.self, capacity: pixelWidth * pixelHeight)

        var factors: [(Float, Float, Float)] = []

        for j in 0 ..< components.1 {
            for i in 0 ..< components.0 {
                let factor = multiplyBasisFunction(pixels: pixels, width: pixelWidth, height: pixelHeight, from: (i, j))
                factors.append(factor)
            }
        }

        let dc = factors.first!
        let ac = factors.dropFirst()

        var hash = ""

        let sizeFlag = (components.0 - 1) + (components.1 - 1) * 9
        hash += sizeFlag.encode83(length: 1)

        let maximumValue: Float
        if ac.isEmpty {
            maximumValue = 1
            hash += 0.encode83(length: 1)
        } else {
            let actualMaximumValue = ac.map { max(abs($0.0), abs($0.1), abs($0.2)) }.max()!
            let quantisedMaximumValue = Int(max(0, min(82, floor(actualMaximumValue * 166 - 0.5))))
            maximumValue = Float(quantisedMaximumValue + 1) / 166
            hash += quantisedMaximumValue.encode83(length: 1)
        }

        hash += encodeDC(dc).encode83(length: 4)

        for factor in ac {
            hash += encodeAC(factor, maximumValue: maximumValue).encode83(length: 2)
        }

        return hash
    }
}

private func multiplyBasisFunction(pixels: UnsafePointer<UInt32>, width: Int, height: Int, from: (Int, Int)) -> (Float, Float, Float) {
    var r: Float = 0
    var g: Float = 0
    var b: Float = 0

    let basisX = from.0
    let basisY = from.1

    let scale = basisX == 0 && basisY == 0 ? 1 : 2

    for y in 0 ..< height {
        for x in 0 ..< width {
            let basis = Float(scale) * cos((Float.pi * Float(basisX) * Float(x)) / Float(width)) * cos((Float.pi * Float(basisY) * Float(y)) / Float(height))
            let pixel = pixels[y * width + x]
            r += basis * sRGBToLinear(pixel >> 0 & 255)
            g += basis * sRGBToLinear(pixel >> 8 & 255)
            b += basis * sRGBToLinear(pixel >> 16 & 255)
        }
    }

    let pixelCount = Float(width * height)

    return (r / pixelCount, g / pixelCount, b / pixelCount)
}

private func encodeDC(_ value: (Float, Float, Float)) -> Int {
    let roundedR = linearTosRGB(value.0)
    let roundedG = linearTosRGB(value.1)
    let roundedB = linearTosRGB(value.2)
    return (roundedR << 16) + (roundedG << 8) + roundedB
}

private func encodeAC(_ value: (Float, Float, Float), maximumValue: Float) -> Int {
    let quantR = Int(max(0, min(18, floor(signPow(value.0 / maximumValue, 0.5) * 9 + 9.5))))
    let quantG = Int(max(0, min(18, floor(signPow(value.1 / maximumValue, 0.5) * 9 + 9.5))))
    let quantB = Int(max(0, min(18, floor(signPow(value.2 / maximumValue, 0.5) * 9 + 9.5))))
    return quantR * 19 * 19 + quantG * 19 + quantB
}

private func signPow(_ value: Float, _ exp: Float) -> Float {
    copysign(pow(abs(value), exp), value)
}

private func linearTosRGB(_ value: Float) -> Int {
    let v = max(0, min(1, value))
    if v <= 0.0031308 { return Int(v * 12.92 * 255 + 0.5) }
    return Int((1.055 * pow(v, 1 / 2.4) - 0.055) * 255 + 0.5)
}

private func sRGBToLinear(_ value: UInt32) -> Float {
    let v = Float(value) / 255
    if v <= 0.04045 { return v / 12.92 }
    return pow((v + 0.055) / 1.055, 2.4)
}

private let encodeCharacters: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~")

private extension Int {
    func encode83(length: Int) -> String {
        var result = ""
        for i in 1 ... length {
            let digit = (self / Int(pow(83, Double(length - i)))) % 83
            result += String(encodeCharacters[digit])
        }
        return result
    }
}
