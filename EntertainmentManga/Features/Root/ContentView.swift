//
//  ContentView.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

//
//  ContentView.swift
//  Features/Root
//
//  NOTE:
//   - 動作確認しやすいタブ構成（ライブラリ／リーダー／設定）
//   - ここに Xcode Previews を追加（Environment 注入込み）
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var repo: TitleRepository
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.appTheme) private var appTheme

    // リーダーデモ用の固定パス（実際の配置に合わせて変更可）
    private let demoDirectory = "Samples/works/demo/vol01/pages"
    private let demoTitleId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()

    var body: some View {
        TabView {
            // --- Tab 1: ライブラリ ---
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("ライブラリ", systemImage: "books.vertical")
            }

            // --- Tab 2: リーダーデモ ---
            NavigationStack {
                ReaderDemoView(directory: demoDirectory, titleId: demoTitleId)
            }
            .tabItem {
                Label("リーダー", systemImage: "book")
            }

            // --- Tab 3: 設定（テーマ） ---
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
        .themedBackground()
        .preferredColorScheme(themeStore.theme.colorScheme)
        .onAppear {
            // ライブラリ未ロードなら読み込む（バンドルJSONが無ければ空でもOK）
            if repo.titles.isEmpty { repo.load() }
        }
    }
}

// MARK: - リーダーデモ（サンプルをすぐ開ける）

private struct ReaderDemoView: View {
    let directory: String
    let titleId: UUID
    var body: some View {
        VStack(spacing: 12) {
            Text("リーダー動作確認")
                .font(.title3.bold())

            Text("下のボタンから同梱サンプルを表示します。\nパス: \(directory)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                ReaderView(directory: directory, startIndex: 0, titleId: titleId)
            } label: {
                Label("サンプルを読む", systemImage: "book.pages")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .navigationTitle("リーダー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 設定（テーマ切替）

private struct SettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    var body: some View {
        Form {
            Section("テーマ") {
                Picker("外観", selection: $themeStore.theme) {
                    ForEach(AppTheme.allCases) { t in
                        Text(t.label).tag(t)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("現在の適用")
                    Spacer()
                    Text(themeStore.theme.label)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("Tips: ライブラリ画面のツールバーからもテーマ変更できます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("設定")
    }
}

// MARK: - Xcode Previews

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // ✅ Added: プレビュー用の最小セットアップ
        let repo = TitleRepository()
        let progress = ReadingProgressStore.shared
        let theme = ThemeStore.shared
        // （必要ならここで theme.theme = .sepia など変更可能）
        // theme.theme = .sepia  // ←お好みで

        // ✅ Added: 環境注入つきで ContentView を表示
        ContentView()
            .environmentObject(repo)
            .environmentObject(progress)
            .environmentObject(theme)
            .environment(\.appTheme, theme.theme)    // ✅ Added: Color+Theme の Environment
            .preferredColorScheme(theme.theme.colorScheme)
            .themedBackground()
            .previewDisplayName("Default Theme")

        ContentView()
            .environmentObject(repo)
            .environmentObject(progress)
            .environmentObject(theme)
            .environment(\.appTheme, AppTheme.sepia) // ✅ Added: Sepia プレビュー
            .preferredColorScheme(AppTheme.sepia.colorScheme)
            .themedBackground()
            .previewDisplayName("Sepia Theme")
    }
}
#endif
