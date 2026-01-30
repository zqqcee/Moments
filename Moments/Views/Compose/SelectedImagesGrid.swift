//
//  SelectedImagesGrid.swift
//  Moments
//
//  已选图片预览
//

import SwiftUI
import Kingfisher

struct SelectedImagesGrid: View {
    let images: [SelectedImage]
    var onRemove: ((SelectedImage) -> Void)?
    var onMove: ((IndexSet, Int) -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(images) { image in
                imageCell(image)
            }
        }
    }

    @ViewBuilder
    private func imageCell(_ image: SelectedImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let uiImage = image.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let url = image.url {
                    KFImage(URL(string: url))
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 删除按钮
            Button {
                onRemove?(image)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Preview

#Preview {
    SelectedImagesGrid(images: [
        SelectedImage(id: UUID(), image: nil, url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400", width: 400, height: 300),
        SelectedImage(id: UUID(), image: nil, url: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=400", width: 400, height: 300)
    ])
    .padding()
}
