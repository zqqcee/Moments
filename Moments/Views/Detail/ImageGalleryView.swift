//
//  ImageGalleryView.swift
//  Moments
//
//  全屏图片浏览 (捏合缩放、双击放大、滑动切换)
//

import SwiftUI
import Kingfisher

struct ImageGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    let images: [ThoughtImage]
    let initialIndex: Int

    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showControls = true

    init(images: [ThoughtImage], initialIndex: Int = 0) {
        self.images = images
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()

            // 图片轮播
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ZoomableImageView(
                        url: image.url,
                        scale: index == currentIndex ? $scale : .constant(1.0),
                        offset: index == currentIndex ? $offset : .constant(.zero)
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentIndex) { _, _ in
                resetZoom()
            }

            // 控制层
            if showControls {
                controlOverlay
            }
        }
        .statusBarHidden(!showControls)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
            }
        }
    }

    // MARK: - Control Overlay

    private var controlOverlay: some View {
        VStack {
            // 顶部栏
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }

                Spacer()

                // 页码指示
                if images.count > 1 {
                    Text("\(currentIndex + 1) / \(images.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                }

                Spacer()

                // 更多操作
                Menu {
                    Button {
                        saveImage()
                    } label: {
                        Label("保存到相册", systemImage: "square.and.arrow.down")
                    }

                    Button {
                        shareImage()
                    } label: {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
            }
            .padding()

            Spacer()
        }
    }

    // MARK: - Actions

    private func resetZoom() {
        withAnimation(.spring(response: 0.3)) {
            scale = 1.0
            offset = .zero
            lastScale = 1.0
            lastOffset = .zero
        }
    }

    private func saveImage() {
        guard let url = URL(string: images[currentIndex].url) else { return }

        KingfisherManager.shared.retrieveImage(with: url) { result in
            if case .success(let value) = result {
                UIImageWriteToSavedPhotosAlbum(value.image, nil, nil, nil)
                HapticManager.success()
            }
        }
    }

    private func shareImage() {
        guard let url = URL(string: images[currentIndex].url) else { return }

        KingfisherManager.shared.retrieveImage(with: url) { result in
            if case .success(let value) = result {
                let activityVC = UIActivityViewController(
                    activityItems: [value.image],
                    applicationActivities: nil
                )

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            }
        }
    }
}

// MARK: - Zoomable Image View

struct ZoomableImageView: View {
    let url: String
    @Binding var scale: CGFloat
    @Binding var offset: CGSize

    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        KFImage(URL(string: url))
            .placeholder {
                ProgressView()
                    .tint(.white)
            }
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale = min(max(scale * delta, 1), 4)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                        if scale < 1.2 {
                            withAnimation(.spring(response: 0.3)) {
                                scale = 1.0
                                offset = .zero
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if scale > 1 {
                            offset = CGSize(
                                width: value.translation.width,
                                height: value.translation.height
                            )
                        }
                    }
                    .onEnded { _ in
                        if scale <= 1 {
                            withAnimation(.spring(response: 0.3)) {
                                offset = .zero
                            }
                        }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3)) {
                    if scale > 1 {
                        scale = 1.0
                        offset = .zero
                    } else {
                        scale = 2.0
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ImageGalleryView(
        images: [
            ThoughtImage(url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200", width: 1200, height: 800, blurhash: nil),
            ThoughtImage(url: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1200", width: 1200, height: 800, blurhash: nil)
        ],
        initialIndex: 0
    )
}
