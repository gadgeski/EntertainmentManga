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
    // ✅ Added: 環境オブジェクト
    @StateObject private var progressStore = ReadingProgressStore.shared
    @StateObject private var themeStore = ThemeStore.shared

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(repo)
                .environmentObject(progressStore) // ✅ Added
                .environmentObject(themeStore)    // ✅ Added
                .onAppear { repo.load() }
            // ✅ Added: AppTheme を Environment に流す（ThemeStore を触らず参照可能に）
                .environment(\.appTheme, themeStore.theme)
                // ✅ Added: カラースキーム適用（sepiaはlight扱い）
                .preferredColorScheme(themeStore.theme.colorScheme)
                .themedBackground() // ✅ Added: セピア背景など
        }
    }
}

