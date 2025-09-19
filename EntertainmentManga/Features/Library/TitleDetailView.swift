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
//  このファイルは「タグの折返し」を旧FlowLayout実装から
//  iOS16+の `Layout` API を使う実装へ最小差分で置き換えています。
//  変更箇所は `// ✅ Changed:` のコメントを付けています。
//

import SwiftUI

// MARK: - TitleDetailView

struct TitleDetailView: View {
    let title: Title  // Models/Title.swift で定義済みの型を使用

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // ヘッダー：カバー・基本情報
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

                // ジャンル（タグの折返し表示）
                if !title.genres.isEmpty {
                    HStack {
                        Text("ジャンル:").bold()
                        Spacer()
                    }

                    // ✅ Changed: 旧 FlowLayout 呼び出しを廃止し、
                    // iOS16+ Layout API ベースの FlowTagsLayout に置換。
                    WrapTags(tags: title.genres)
                }

                // あらすじ
                VStack(alignment: .leading, spacing: 8) {
                    Text("あらすじ").font(.headline)
                    Text(title.synopsis)
                }
            }
            .padding()
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
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

// ✅ Changed: タグ群の表示を iOS16+ の `Layout` API で実装した FlowTagsLayout に一新。
// これにより `buildExpression … does not conform to 'View'` エラーが解消されます。
// 旧 FlowLayout/_FlowLayout と GeometryReader 内の未使用変数(width/height)を完全撤去。

private struct WrapTags: View {
    let tags: [String]
    var body: some View {

        // ✅ Changed: FlowTagsLayout は Layout 準拠の「レイアウト」として View ビルダーで使う
        FlowTagsLayout(spacing: 8) {
            ForEach(tags, id: \.self) { g in
                Text(g)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
            }
        }
        .animation(.default, value: tags) // 任意：タグ変更時の見た目の滑らかさ
    }
}

/// iOS16+ の Layout API を用いた「横幅に応じて折り返す」シンプルなフローレイアウト。
private struct FlowTagsLayout: Layout {
    var spacing: CGFloat = 8

    // レイアウト計算：必要な全体サイズを返す
    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        guard maxWidth.isFinite else {
            // 幅が未定義なら、縦に積んだ仮サイズ（フォールバック）
            let totalHeight = subviews.reduce(0) { partial, s in
                partial + s.sizeThatFits(.unspecified).height
            } + spacing * CGFloat(max(subviews.count - 1, 0))
            return CGSize(width: 0, height: totalHeight)
        }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for s in subviews {
            let size = s.sizeThatFits(.unspecified)

            // 改行判定：次を置くと最大幅を超えるなら折返し
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    // 実際の配置
    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {
        let maxWidth = bounds.width

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for s in subviews {
            let size = s.sizeThatFits(.unspecified)

            // 改行判定
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            s.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

// MARK: - Preview（任意）

#if DEBUG
struct TitleDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // プレビュー用のダミーデータ
        let sample = Title(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "銀河配達人ガール",
            author: "星見 ルカ",
            synopsis: "宇宙コロニー間を走る新人配達員が、失われた荷物の謎を追う爽快アドベンチャー。",
            genres: ["SF", "アドベンチャー", "スペース", "友情", "成長"],
            volumes: 3,
            updatedAt: ISO8601DateFormatter().date(from: "2025-08-20T00:00:00Z") ?? .now,
            coverImageName: nil
        )

        NavigationStack {
            TitleDetailView(title: sample)
        }
        .environment(\.colorScheme, .light)

        NavigationStack {
            TitleDetailView(title: sample)
        }
        .environment(\.colorScheme, .dark)
    }
}
#endif
