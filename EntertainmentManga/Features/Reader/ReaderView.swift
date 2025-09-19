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
//   - 横読み(ページング) / 縦読み(連続) 切替
//   - RTL/LTR 切替（横読み時は配列を反転）
//   - ズーム ON/OFF
//   - ページインジケータ
//   - バンドル内ディレクトリからページ画像を読み込み
//

import SwiftUI

struct ReaderView: View {
    @StateObject private var settings = ReaderSettings.shared
    @EnvironmentObject private var progressStore: ReadingProgressStore // ✅ Added

    @State private var pages: [UIImage] = []
    @State private var currentIndex: Int = 0

    let directory: String
    let startIndex: Int
    let titleId: UUID  // このリーディングが属する作品のID

    init(directory: String, startIndex: Int = 0, titleId: UUID) {
        self.directory = directory
        self.startIndex = startIndex
        self.titleId = titleId
    }

    var body: some View {
        Group {
            if pages.isEmpty {
                ProgressView("ページを読み込み中…")
                    .task { await loadPages() } // ✅ Added: 非同期ローダ
            } else {
                contentView // ✅ Changed: ContentView → contentView（小文字の計算プロパティ）
            }
        }
        .navigationTitle("リーダー")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent } // ✅ Added: ツールバー中身を分離
        .onChange(of: settings.readMode) {        snapToIndex(currentIndex) } // ✅ Added
        .onChange(of: settings.readDirection) {   snapToIndex(mappedIndexForDirection(currentIndex)) } // ✅ Added
        // ページ移動ごとに進捗保存
        .onChange(of: currentIndex) { saveProgress() } // ✅ Added
        // 閉じるときも最終進捗を保存
        .onDisappear { saveProgress() } // ✅ Added
    }

    // MARK: - メイン表示

    // ✅ Added: 画面本体（横/縦で出し分け）
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

    // ✅ Added: 読み方向に応じて配列順を調整（横ページング時のみ反転）
    private func orderedImages() -> [UIImage] {
        settings.readMode == .horizontalPaged && settings.readDirection == .rtl
        ? pages.reversed()
        : pages
    }

    // ✅ Added: 読み方向変更時にインデックスを合わせるためのマッピング
    private func mappedIndexForDirection(_ idx: Int) -> Int {
        guard settings.readMode == .horizontalPaged else { return idx }
        let count = pages.count
        return (count - 1) - idx
    }

    // ✅ Added: 範囲内に丸めて currentIndex を更新
    private func snapToIndex(_ idx: Int) {
        currentIndex = min(max(0, idx), max(0, pages.count - 1))
    }

    // ✅ Added: 表示上のインデックス（RTL時は反転）
    private var currentDisplayIndex: Int {
        if settings.readMode == .horizontalPaged, settings.readDirection == .rtl {
            return (pages.count - 1) - currentIndex
        }
        return currentIndex
    }

    // MARK: - Toolbar

    // ✅ Added: ツールバーコンテンツ
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

    // MARK: - 永続化（進捗）

    // ✅ Added: 進捗保存
    private func saveProgress() {
        let total = pages.count
        guard total > 0 else { return }
        let displayIndex = currentDisplayIndex
        progressStore.saveProgress(id: titleId, lastPage: displayIndex, totalPages: total)
    }

    // MARK: - ローディング

    // ✅ Added: ディレクトリから画像を読み込む
    private func loadPagesFromBundle(in directory: String) -> [UIImage] {
        guard let dirURL = Bundle.main.url(forResource: directory, withExtension: nil) else { return [] }
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return []
        }
        let sorted = urls
            .filter { ["jpg", "jpeg", "png", "webp", "gif"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        return sorted.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let img = UIImage(data: data) else { return nil }
            return img
        }
    }

    // ✅ Added: 非同期で読み込み・初期ページへ移動
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
        ScrollViewReader { _ in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(images.indices, id: \.self) { i in
                        PageImageView(image: images[i], zoomEnabled: zoomEnabled)
                            .frame(maxWidth: .infinity)
                            .id(i)
                            // 中央要素の検出など高度な現在ページ推定は必要に応じて追加
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal)
            }
            .background(Color.black.opacity(0.95).ignoresSafeArea())
        }
    }
}
