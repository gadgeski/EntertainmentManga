//
//  MangaApp.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

//
//  MangaApp.swift
//  App
//

import SwiftUI

@main
struct MangaApp: App {
    @StateObject private var repo = TitleRepository()
    @StateObject private var progressStore = ReadingProgressStore.shared
    @StateObject private var themeStore = ThemeStore.shared

    var body: some Scene {
        WindowGroup {
            // ✅ Changed: ルートを LibraryView → ContentView に変更
            ContentView() // ← ここがメインビューになります
                .environmentObject(repo)
                .environmentObject(progressStore)
                .environmentObject(themeStore)
                .environment(\.appTheme, themeStore.theme)     // ✅ Added: テーマを Environment へ
                .preferredColorScheme(themeStore.theme.colorScheme)
                .themedBackground()
                .onAppear { repo.load() }
        }
    }
}


