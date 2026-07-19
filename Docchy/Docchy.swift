//
//  Docchy.swift
//  Docchy
//
//  Created by Vittorio Monfrecola on 11/07/2026.
//

import SwiftUI
import SwiftData

@main
struct ScannerApp: App {
    var body: some Scene {
        WindowGroup {
            AppLockView {
                LibraryView()
            }
        }
        .modelContainer(for: ScannedDocument.self)
    }
}
