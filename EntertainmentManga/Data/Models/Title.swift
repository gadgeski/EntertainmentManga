//
//  Title.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//
// Data/Models/Title.swift

import Foundation

struct Title: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let author: String
    let synopsis: String
    let genres: [String]
    let volumes: Int
    let updatedAt: Date
    let coverImageName: String? // Assets 参照用（任意）
}
