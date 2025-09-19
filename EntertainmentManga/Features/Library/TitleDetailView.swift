//
//  TitleDetailView.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

//
//  TitleDetailView.swift
//  Features/Library
//
//  NOTE: iOS 16+（SwiftUI Layout API）
//
//  このファイルは、タグの折返しを iOS16+ の `Layout` API に刷新（前回）し、
//  さらに「読む」ボタンから ReaderView へ遷移する導線（今回）を追加しています。
//  変更箇所には `// ✅ Changed:` と `// ✅ Added:` を付与。
//  NavigationLink を使った最小遷移（スタック遷移）で、状態管理は不要です。
//

//
//  TitleDetailView.swift
//  Features/Library
//

//
//  TitleDetailView.swift
//  Features/Library
//

import SwiftUI

struct TitleDetailView: View {
    let title: Title

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // --- ヘッダー（省略なしで記載） ---
                HStack(alignment: .top, spacing: 16) {
                    if let name = title.coverImageName,
                       let uiImage = UIImage(named: name) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: 140, height: 200)
                            .overlay(Image(systemName: "book")
                                .foregroundStyle(.secondary))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(title.name)
                            .font(.title2.bold())
                        Text("作者: \(title.author)")
                            .foregroundStyle(.secondary)
                        Text("巻数: \(title.volumes)")
                            .foregroundStyle(.secondary)
                        Text("最終更新: \(formatted(date: title.updatedAt))")
                            .foregroundStyle(.secondary)
                    }
                }

                // --- タグ（FlowTagsLayout を利用） ---
                if !title.genres.isEmpty {
                    HStack { Text("ジャンル:").bold(); Spacer() }
                    WrapTags(tags: title.genres)
                }

                // --- あらすじ ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("あらすじ").font(.headline)
                    Text(title.synopsis)
                }

                // ✅ Changed: ReaderView に titleId を渡す
                // ✅ Added: 作品名から生成したスラッグをディレクトリに使用
                NavigationLink {
                    ReaderView(
                        directory: "Samples/works/\(slugify(title.name))/vol01/pages",
                        startIndex: 0,
                        titleId: title.id
                    )
                } label: {
                    Label("読む", systemImage: "book.pages")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
        .themedBackground()
    }

    private func formatted(date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}

// MARK: - Tags (Wrap + Layout)

private struct WrapTags: View {
    let tags: [String]
    var body: some View {
        FlowTagsLayout(spacing: 8) {
            ForEach(tags, id: \.self) { g in
                Text(g)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
            }
        }
        .animation(.default, value: tags)
    }
}

private struct FlowTagsLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        guard maxWidth.isFinite else {
            let totalHeight = subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).height } +
                              spacing * CGFloat(max(subviews.count - 1, 0))
            return CGSize(width: 0, height: totalHeight)
        }

        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            s.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                    proposal: ProposedViewSize(width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

// MARK: - Utility

// ✅ Added: 作品名から簡易スラッグを生成（英数字と -_ のみ）
// 例: "銀河 配達人ガール" -> "-------" になる可能性があるので、
// 実運用では Title.pagesDirectory を持たせる方が堅実です。
// ここでは“最小修正”として slugify を提供します。
private func slugify(_ s: String) -> String {
    // ダイアクリティカルマークを除去（é -> e など）
    let folded = s.folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: .current)
    // スペースをハイフンへ
    let replaced = folded.replacingOccurrences(of: " ", with: "-")
    // 許可文字セット（英数字と -_）
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    // 許可外はハイフンに置換
    var out = replaced.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }.joined()
    // 連続ハイフンの圧縮 & 両端ハイフン除去 & 小文字化
    while out.contains("--") { out = out.replacingOccurrences(of: "--", with: "-") }
    out = out.trimmingCharacters(in: CharacterSet(charactersIn: "-")).lowercased()
    return out.isEmpty ? "untitled" : out
}

// MARK: - Preview

#if DEBUG
struct TitleDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = Title(
            id: UUID(),
            name: "銀河 配達人ガール",
            author: "星見 ルカ",
            synopsis: "宇宙コロニー間を走る新人配達員が、失われた荷物の謎を追う爽快アドベンチャー。",
            genres: ["SF", "アドベンチャー", "スペース"],
            volumes: 3,
            updatedAt: ISO8601DateFormatter().date(from: "2025-08-20T00:00:00Z") ?? .now,
            coverImageName: nil
        )
        NavigationStack { TitleDetailView(title: sample) }
            .environment(\.colorScheme, .light)

        NavigationStack { TitleDetailView(title: sample) }
            .environment(\.colorScheme, .dark)
    }
}
#endif
