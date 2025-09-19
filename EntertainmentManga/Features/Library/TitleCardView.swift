//
//  TitleCardView.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

// Features/Library/TitleCardView.swift

import SwiftUI

struct TitleCardView: View {
    let title: Title

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .aspectRatio(3/4, contentMode: .fit)
                if let name = title.coverImageName, !name.isEmpty, let uiImage = UIImage(named: name) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "book")
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                }
            }
            Text(title.name)
                .font(.headline)
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
