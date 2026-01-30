//
//  ThoughtImageGrid.swift
//  Moments
//
//  图片网格布局 (支持 1-9 张不同布局)
//

import SwiftUI
import Kingfisher

struct ThoughtImageGrid: View {
    let images: [ThoughtImage]
    var onImageTap: ((Int) -> Void)?

    private let spacing: CGFloat = 4
    private let cornerRadius: CGFloat = 8
    private let maxHeight: CGFloat = 300

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            Group {
                switch images.count {
                case 1:
                    singleImage(width: width)
                case 2:
                    twoImages(width: width)
                case 3:
                    threeImages(width: width)
                case 4:
                    fourImages(width: width)
                default:
                    gridImages(width: width)
                }
            }
        }
        .frame(height: calculateHeight())
    }

    // MARK: - Layout Calculations

    private func calculateHeight() -> CGFloat {
        switch images.count {
        case 1:
            let ratio = images[0].aspectRatio
            let height = UIScreen.main.bounds.width / ratio
            return min(height, maxHeight)
        case 2:
            return 150
        case 3:
            return 200
        case 4:
            return 200
        default:
            let rows = ceil(Double(images.count) / 3.0)
            return CGFloat(rows) * 100 + CGFloat(rows - 1) * spacing
        }
    }

    // MARK: - Single Image

    private func singleImage(width: CGFloat) -> some View {
        imageView(images[0], index: 0)
            .frame(width: width, height: calculateHeight())
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // MARK: - Two Images (并排 1:1)

    private func twoImages(width: CGFloat) -> some View {
        let itemWidth = (width - spacing) / 2

        return HStack(spacing: spacing) {
            imageView(images[0], index: 0)
                .frame(width: itemWidth, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            imageView(images[1], index: 1)
                .frame(width: itemWidth, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    // MARK: - Three Images (左1大右2小)

    private func threeImages(width: CGFloat) -> some View {
        let leftWidth = width * 0.6 - spacing / 2
        let rightWidth = width * 0.4 - spacing / 2
        let rightHeight = (200 - spacing) / 2

        return HStack(spacing: spacing) {
            imageView(images[0], index: 0)
                .frame(width: leftWidth, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            VStack(spacing: spacing) {
                imageView(images[1], index: 1)
                    .frame(width: rightWidth, height: rightHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                imageView(images[2], index: 2)
                    .frame(width: rightWidth, height: rightHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
    }

    // MARK: - Four Images (2x2 网格)

    private func fourImages(width: CGFloat) -> some View {
        let itemSize = (width - spacing) / 2
        let itemHeight = (200 - spacing) / 2

        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                imageView(images[0], index: 0)
                    .frame(width: itemSize, height: itemHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                imageView(images[1], index: 1)
                    .frame(width: itemSize, height: itemHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }

            HStack(spacing: spacing) {
                imageView(images[2], index: 2)
                    .frame(width: itemSize, height: itemHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                imageView(images[3], index: 3)
                    .frame(width: itemSize, height: itemHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
    }

    // MARK: - Grid Images (5-9张: 3列网格)

    private func gridImages(width: CGFloat) -> some View {
        let columns = 3
        let itemSize = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)

        return VStack(spacing: spacing) {
            ForEach(0..<Int(ceil(Double(images.count) / Double(columns))), id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < images.count {
                            imageView(images[index], index: index)
                                .frame(width: itemSize, height: itemSize)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        } else {
                            Color.clear
                                .frame(width: itemSize, height: itemSize)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Image View

    @ViewBuilder
    private func imageView(_ image: ThoughtImage, index: Int) -> some View {
        KFImage(URL(string: image.url))
            .placeholder {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        ProgressView()
                    }
            }
            .fade(duration: 0.3)
            .resizable()
            .scaledToFill()
            .contentShape(Rectangle())
            .onTapGesture {
                onImageTap?(index)
            }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // 1张
            ThoughtImageGrid(images: [
                ThoughtImage(url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800", width: 800, height: 600, blurhash: nil)
            ])
            .padding(.horizontal)

            // 2张
            ThoughtImageGrid(images: [
                ThoughtImage(url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800", width: 800, height: 800, blurhash: nil),
                ThoughtImage(url: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800", width: 800, height: 800, blurhash: nil)
            ])
            .padding(.horizontal)

            // 3张
            ThoughtImageGrid(images: [
                ThoughtImage(url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800", width: 800, height: 600, blurhash: nil),
                ThoughtImage(url: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800", width: 800, height: 800, blurhash: nil),
                ThoughtImage(url: "https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=800", width: 800, height: 800, blurhash: nil)
            ])
            .padding(.horizontal)
        }
    }
}
