//
//  LibraryView.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//
//
//  LibraryView.swift
//  Features/Library
//
//  NOTE:
//  - テーマ切替UI（ツールバーの筆アイコン → メニュー → Picker）を追加
//  - 既存の検索・ジャンルフィルタ・ソート・グリッド表示・詳細遷移を維持
//  - セマンティックカラー＆背景モディファイアを適用
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var repo: TitleRepository
    @EnvironmentObject var themeStore: ThemeStore        // ✅ Added: テーマ管理（環境オブジェクト）

    @State private var query: String = ""
    @State private var selectedGenre: String? = nil
    @State private var sortByUpdatedDesc: Bool = true

    private var genres: [String] {
        let all = repo.titles.flatMap { $0.genres }
        return Array(Set(all)).sorted()
    }

    private var filtered: [Title] {
        var list = repo.titles
        if let g = selectedGenre { list = list.filter { $0.genres.contains(g) } }
        if !query.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.author.localizedCaseInsensitiveContains(query) ||
                $0.synopsis.localizedCaseInsensitiveContains(query)
            }
        }
        if sortByUpdatedDesc {
            list.sort { $0.updatedAt > $1.updatedAt }
        }
        return list
    }

    let columns: [GridItem] = [
        GridItem(.flexible(minimum: 120)),
        GridItem(.flexible(minimum: 120))
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                // 検索・フィルタバー
                HStack {
                    TextField("作品名/作者で検索", text: $query)
                        .textFieldStyle(.roundedBorder)

                    Menu {
                        Button("すべて", action: { selectedGenre = nil })
                        Divider()
                        ForEach(genres, id: \.self) { g in
                            Button(g, action: { selectedGenre = g })
                        }
                    } label: {
                        Label(selectedGenre ?? "ジャンル", systemImage: "line.3.horizontal.decrease.circle")
                    }

                    Button {
                        sortByUpdatedDesc.toggle()
                    } label: {
                        Image(systemName: sortByUpdatedDesc ? "arrow.down.circle" : "arrow.up.circle")
                            .help("更新日ソート切替")
                    }
                }
                .padding(.horizontal)

                if filtered.isEmpty {
                    ContentUnavailableView(
                        "作品が見つかりません",
                        systemImage: "book.closed",
                        description: Text("検索条件を変えてお試しください")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filtered) { title in
                                NavigationLink(value: title) {
                                    TitleCardView(title: title)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("ライブラリ")
            .navigationDestination(for: Title.self) { title in
                TitleDetailView(title: title)
            }
            // ✅ Added: テーマ切替UI（Toolbar）
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("テーマ", selection: $themeStore.theme) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.label).tag(t)
                            }
                        }
                    } label: {
                        Image(systemName: "paintbrush")
                    }
                }
            }
        }
        // ✅ Added: セマンティック背景（セピア等）
        .themedBackground()
        // ✅ Added: カラースキーム適用（sepiaはlight扱い）
        .preferredColorScheme(themeStore.theme.colorScheme)
    }
}
