//
//  Color+Theme.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

//
//  Color+Theme.swift
//  Support/Theme
//

//
//  Color+Theme.swift
//  Support/Theme
//
//  NOTE:
//  - Actor隔離エラー回避のため、Color拡張から ThemeStore.shared を参照しない。
//  - テーマ値は Environment(.appTheme) から取得して View/Modifier 内で使う。
//  - Color 側は「引数付きヘルパー」に変更。
//

import SwiftUI

// MARK: - Environment Key for AppTheme

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .system
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - Color semantic helpers (parameterized)

extension Color {
    // ✅ Changed: shared/theme を直接読まず、引数でテーマを受け取る
    static func appBackground(for theme: AppTheme) -> Color {
        switch theme {
        case .sepia:
            return Color(red: 0.98, green: 0.96, blue: 0.90) // セピア紙
        default:
            return Color(.systemBackground)
        }
    }

    static func appTextPrimary(for theme: AppTheme) -> Color {
        switch theme {
        case .sepia:
            return Color(red: 0.23, green: 0.19, blue: 0.13) // ダークブラウン
        default:
            return Color(.label)
        }
    }

    static func appCard(for theme: AppTheme) -> Color {
        switch theme {
        case .sepia:
            return Color(red: 0.94, green: 0.91, blue: 0.83)
        default:
            return Color.secondary.opacity(0.1)
        }
    }
}

// MARK: - View utilities

/// ✅ Changed: 環境からテーマを受け取って背景を塗る
struct ThemedBackground: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    func body(content: Content) -> some View {
        content
            .background(
                Color.appBackground(for: appTheme)
                    .ignoresSafeArea()
            )
    }
}

extension View {
    func themedBackground() -> some View { modifier(ThemedBackground()) }
}
