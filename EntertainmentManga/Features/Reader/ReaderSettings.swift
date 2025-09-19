//
//  ReaderSettings.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

//
//  ReaderSettings.swift
//  Features/Reader
//
//  NOTE:
//  - @AppStorage は View では便利だが、ObservableObject の init で読むと
//    初期化順問題（self 参照）でエラーになりやすい。
//  - ここでは UserDefaults 直アクセスに変更して解決。
//    （Published の didSet で保存）
//

import SwiftUI

@MainActor
final class ReaderSettings: ObservableObject {

    static let shared = ReaderSettings()

    // ✅ Changed: @AppStorage を廃止し、UserDefaults に置換
    private let defaults: UserDefaults
    private enum Keys {
        static let readMode      = "reader.readMode"
        static let readDirection = "reader.readDirection"
        static let zoomEnabled   = "reader.zoomEnabled"
    }

    @Published var readMode: ReadMode {
        didSet {
            // ✅ Changed: 変更時に保存
            defaults.set(readMode.rawValue, forKey: Keys.readMode)
        }
    }

    @Published var readDirection: ReadingDirection {
        didSet {
            // ✅ Changed: 変更時に保存
            defaults.set(readDirection.rawValue, forKey: Keys.readDirection)
        }
    }

    @Published var zoomEnabled: Bool {
        didSet {
            // ✅ Changed: 変更時に保存
            defaults.set(zoomEnabled, forKey: Keys.zoomEnabled)
        }
    }

    // ✅ Changed: init で UserDefaults から読み込む（self 参照なし）
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // 初期値読み出し（存在しなければデフォルト）
        let rawMode = defaults.string(forKey: Keys.readMode) ?? ReadMode.horizontalPaged.rawValue
        self.readMode = ReadMode(rawValue: rawMode) ?? .horizontalPaged

        let rawDir = defaults.string(forKey: Keys.readDirection) ?? ReadingDirection.rtl.rawValue
        self.readDirection = ReadingDirection(rawValue: rawDir) ?? .rtl

        let storedZoom = defaults.object(forKey: Keys.zoomEnabled) as? Bool ?? true
        self.zoomEnabled = storedZoom
    }
}

// そのまま（既存）
enum ReadMode: String, CaseIterable, Identifiable {
    case horizontalPaged
    case verticalScroll
    var id: String { rawValue }
    var label: String {
        switch self {
        case .horizontalPaged: return "横(ページ)"
        case .verticalScroll:  return "縦(連続)"
        }
    }
    var systemImage: String {
        switch self {
        case .horizontalPaged: return "square.fill.on.square.fill"
        case .verticalScroll:  return "rectangle.portrait.on.rectangle.portrait"
        }
    }
}

enum ReadingDirection: String, CaseIterable, Identifiable {
    case ltr
    case rtl
    var id: String { rawValue }
    var label: String { self == .ltr ? "LTR" : "RTL" }
    var systemImage: String { self == .ltr ? "arrow.forward" : "arrow.backward" }
}
