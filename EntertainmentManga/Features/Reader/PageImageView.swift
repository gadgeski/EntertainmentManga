//
//  PageImageView.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

//
//  PageImageView.swift
//  Features/Reader
//

import SwiftUI

/// 1ページ分の画像。ピンチズーム＆ダブルタップズーム対応。
struct PageImageView: View {
    let image: UIImage?
    let zoomEnabled: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastDrag: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.08))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                Text("ページを読み込めませんでした")
                                    .font(.caption)
                            }.foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(zoomEnabled ? zoomGesture : nil)
            .gesture(zoomEnabled ? dragGesture : nil)
            .onTapGesture(count: 2, perform: doubleTapZoom)
            .animation(.easeInOut(duration: 0.18), value: scale)
            .animation(.easeInOut(duration: 0.18), value: offset)
        }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                var newScale = scale * delta
                newScale = max(1.0, min(newScale, 3.0))
                scale = newScale
                lastScale = value
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale <= 1.01 { // ほぼ等倍なら位置もリセット
                    scale = 1.0
                    offset = .zero
                    lastDrag = .zero
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1.01 else { return }
                let translation = value.translation
                offset = CGSize(width: lastDrag.width + translation.width,
                                height: lastDrag.height + translation.height)
            }
            .onEnded { _ in
                lastDrag = offset
            }
    }

    private func doubleTapZoom() {
        guard zoomEnabled else { return }
        if scale > 1.01 {
            scale = 1.0
            offset = .zero
            lastDrag = .zero
        } else {
            scale = 2.0
        }
    }
}
