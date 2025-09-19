//
//  ThemeStore.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

//
//  ThemeStore.swift
//  Features/LibraryState
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case system, light, dark, sepia
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "システム"
        case .light:  return "ライト"
        case .dark:   return "ダーク"
        case .sepia:  return "セピア"
        }
    }

    // SwiftUI の ColorScheme に対応（sepia は light ベース）
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light, .sepia: return .light
        case .dark:  return .dark
        }
    }
}

@MainActor
final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()
    private let defaults: UserDefaults
    private enum Keys { static let theme = "app.theme.v1" }

    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.string(forKey: Keys.theme) ?? AppTheme.system.rawValue
        self.theme = AppTheme(rawValue: raw) ?? .system
    }
}
