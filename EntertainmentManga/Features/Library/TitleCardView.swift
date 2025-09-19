//
//  TitleCardView.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

//
//  TitleCardView.swift
//  Features/Library
//

import SwiftUI

struct TitleCardView: View {
    let title: Title
    @EnvironmentObject private var progress: ReadingProgressStore // ✅ Added
    @Environment(\.appTheme) private var appTheme   // ✅ Added
    
    var body: some View {
        let p = progress.progress(for: title.id) // ✅ Added

        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCard(for: appTheme)) // ✅ Changed: セマンティックカラー
                    .aspectRatio(3/4, contentMode: .fit)

                if let name = title.coverImageName,
                   let uiImage = UIImage(named: name) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "book")
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                // ✅ Added: 進捗/既読バッジ
                if let p {
                    HStack(spacing: 6) {
                        if p.isCompleted {
                            Label("既読", systemImage: "checkmark.circle.fill")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(.green.opacity(0.9)))
                                .foregroundStyle(.white)
                        } else if p.percentage > 0 {
                            Text("\(Int(p.percentage * 100))%")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(.blue.opacity(0.9)))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(6)
                }
            }

            Text(title.name)
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary(for: appTheme)) // ✅ Changed
                .lineLimit(2)

            Text(title.author)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 6) {
                ForEach(title.genres.prefix(3), id: \.self) { g in
                    Text(g)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                }
            }
        }
        .contentShape(Rectangle())
    }
}
