//
//  ReadingProgressStore.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

//
//  ReadingProgressStore.swift
//  Features/LibraryState
//

import Foundation
import SwiftUI

// 1作品の読書進捗
struct ReadingProgress: Codable, Equatable {
    var lastPage: Int         // 最後に開いたページ（0-based）
    var totalPages: Int       // 当時の総ページ数
    var updatedAt: Date

    var percentage: Double {
        guard totalPages > 0 else { return 0 }
        return min(1.0, Double(lastPage + 1) / Double(totalPages))
    }

    var isCompleted: Bool {
        totalPages > 0 && lastPage >= totalPages - 1
    }
}

@MainActor
final class ReadingProgressStore: ObservableObject {
    static let shared = ReadingProgressStore()
    private let defaults: UserDefaults
    private let key = "reading.progress.v1" // フォーマット変更時はキーを上げる

    // UUIDString -> ReadingProgress
    @Published private(set) var map: [String: ReadingProgress] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func load() {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: ReadingProgress].self, from: data) {
            self.map = decoded
        } else {
            self.map = [:]
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(map) {
            defaults.set(data, forKey: key)
        }
    }

    func progress(for id: UUID) -> ReadingProgress? {
        map[id.uuidString]
    }

    func saveProgress(id: UUID, lastPage: Int, totalPages: Int) {
        var p = map[id.uuidString] ?? ReadingProgress(lastPage: 0, totalPages: totalPages, updatedAt: Date())
        p.lastPage = max(0, min(lastPage, max(0, totalPages - 1)))
        p.totalPages = totalPages
        p.updatedAt = Date()
        map[id.uuidString] = p
        save()
        objectWillChange.send()
    }

    func markCompleted(id: UUID) {
        if let existing = map[id.uuidString] {
            map[id.uuidString] = ReadingProgress(lastPage: max(existing.totalPages - 1, 0),
                                                 totalPages: existing.totalPages,
                                                 updatedAt: Date())
        } else {
            map[id.uuidString] = ReadingProgress(lastPage: 0, totalPages: 1, updatedAt: Date())
        }
        save()
        objectWillChange.send()
    }
}
