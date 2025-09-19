//
//  ReaderView.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

//
//  ReaderView.swift
//  Features/Reader
//
//  概要:
//   - 横読み(ページング) / 縦読み(連続) をトグル
//   - RTL/LTR をトグル（横読み時は配列を反転）
//   - ズーム ON/OFF
//   - ページインジケータ
//   - ローカル同梱の画像を「指定ディレクトリ」から読み込む最小実装
//
//  想定ディレクトリ例 (Bundle内):
//   Resources/Samples/works/001/vol01/pages/0001.jpg ... 0020.jpg
//
//  使い方:
//   ReaderView(directory: "Samples/works/001/vol01/pages")
//

import SwiftUI

struct ReaderView: View {
    @StateObject private var settings = ReaderSettings.shared
    @State private var pages: [UIImage] = []
    @State private var currentIndex: Int = 0

    let directory: String
    let startIndex: Int

    init(directory: String, startIndex: Int = 0) {
        self.directory = directory
        self.startIndex = startIndex
    }

    var body: some View {
        Group {
            if pages.isEmpty {
                ProgressView("ページを読み込み中…")
                    .task { await loadPages() }
            } else {
                contentView
            }
        }
        .navigationTitle("リーダー")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onChange(of: settings.readMode) {        snapToIndex(currentIndex) }
        .onChange(of: settings.readDirection) {        snapToIndex(mappedIndexForDirection(currentIndex)) }
    }

    // MARK: - メイン表示

    @ViewBuilder
    private var contentView: some View {
        switch settings.readMode {
        case .horizontalPaged:
            HorizontalPager(
                images: orderedImages(),
                currentIndex: $currentIndex,
                zoomEnabled: settings.zoomEnabled
            )
        case .verticalScroll:
            VerticalScroller(
                images: orderedImages(),
                currentIndex: $currentIndex,
                zoomEnabled: settings.zoomEnabled
            )
        }
    }

    private func orderedImages() -> [UIImage] {
        settings.readDirection == .rtl ? pages.reversed() : pages
    }

    private func mappedIndexForDirection(_ idx: Int) -> Int {
        guard settings.readMode == .horizontalPaged else { return idx }
        // 方向切り替え時にページ位置が概ね維持されるよう、反転対応
        let count = pages.count
        return (count - 1) - idx
    }

    private func snapToIndex(_ idx: Int) {
        currentIndex = min(max(0, idx), max(0, pages.count - 1))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            // 読み方向
            Menu {
                Picker("読み方向", selection: $settings.readDirection) {
                    ForEach(ReadingDirection.allCases) { dir in
                        Label(dir.label, systemImage: dir.systemImage).tag(dir)
                    }
                }
            } label: {
                Image(systemName: settings.readDirection.systemImage)
            }

            // 表示モード
            Menu {
                Picker("表示モード", selection: $settings.readMode) {
                    ForEach(ReadMode.allCases) { mode in
                        Label(mode.label, systemImage: mode.systemImage).tag(mode)
                    }
                }
            } label: {
                Image(systemName: settings.readMode.systemImage)
            }

            // ズーム
            Button {
                settings.zoomEnabled.toggle()
            } label: {
                Image(systemName: settings.zoomEnabled ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
            }
            .help("ズーム \(settings.zoomEnabled ? "ON" : "OFF")")
        }

        ToolbarItem(placement: .principal) {
            if !pages.isEmpty {
                Text("\(currentDisplayIndex + 1) / \(pages.count)")
                    .font(.subheadline.monospacedDigit())
            }
        }
    }

    private var currentDisplayIndex: Int {
        // 表示上のインデックス（RTL時は反転）
        if settings.readMode == .horizontalPaged, settings.readDirection == .rtl {
            return (pages.count - 1) - currentIndex
        }
        return currentIndex
    }

    // MARK: - ロード

    private func loadPagesFromBundle(in directory: String) -> [UIImage] {
        guard let dirURL = Bundle.main.url(forResource: directory, withExtension: nil) else { return [] }
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return []
        }
        // 0001.jpg, 0002.png ... のようなファイル名順で並ぶようにソート
        let sorted = urls
            .filter { ["jpg","jpeg","png","webp","gif"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        return sorted.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let img = UIImage(data: data) else { return nil }
            return img
        }
    }

    private func loadPages() async {
        let imgs = loadPagesFromBundle(in: directory)
        await MainActor.run {
            self.pages = imgs
            self.currentIndex = min(max(0, startIndex), max(0, imgs.count - 1))
        }
    }
}

// MARK: - 横ページング

private struct HorizontalPager: View {
    let images: [UIImage]
    @Binding var currentIndex: Int
    let zoomEnabled: Bool

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(images.indices, id: \.self) { i in
                PageImageView(image: images[i], zoomEnabled: zoomEnabled)
                    .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color.black.opacity(0.95).ignoresSafeArea())
    }
}

// MARK: - 縦連続スクロール

private struct VerticalScroller: View {
    let images: [UIImage]
    @Binding var currentIndex: Int
    let zoomEnabled: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(images.indices, id: \.self) { i in
                        PageImageView(image: images[i], zoomEnabled: zoomEnabled)
                            .frame(maxWidth: .infinity)
                            .id(i)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onChange(of: geo.frame(in: .global).midY) {
                                            // 簡易的に「中央に近い要素」を現在ページっぽく採用
                                            // 正確な算出が必要なら可視領域判定を追加
                                        }
                                }
                            )
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal)
            }
            .background(Color.black.opacity(0.95).ignoresSafeArea())
        }
    }
}
