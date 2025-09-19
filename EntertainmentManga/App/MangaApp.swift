//
//  MangaApp.swift
//  EntertainmentManga
//
//  Created by Dev Tech on 2025/09/19.
//

// App/MangaApp.swift

import SwiftUI

@main
struct MangaApp: App {
    @StateObject private var repo = TitleRepository()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(repo)
                .onAppear { repo.load() }
        }
    }
}
