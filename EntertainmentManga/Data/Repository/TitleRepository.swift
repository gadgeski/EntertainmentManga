//
//  TitleRepository.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//
// Data/Repository/TitleRepository.swift

import Foundation
import Combine

final class TitleRepository: ObservableObject {
    @Published private(set) var titles: [Title] = []

    func load() {
        guard let url = Bundle.main.url(forResource: "titles", withExtension: "json") else {
            print("titles.json not found in bundle")
            self.titles = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder.iso8601.decode([Title].self, from: data)
            self.titles = decoded
        } catch {
            print("Failed to decode titles.json: \(error)")
            self.titles = []
        }
    }

    // 例：簡易ソート/フィルタ（必要なら）
    func sorted(by keyPath: KeyPath<Title, String>) -> [Title] {
        titles.sorted { $0[keyPath: keyPath].localizedCaseInsensitiveCompare($1[keyPath: keyPath]) == .orderedAscending }
    }
}
