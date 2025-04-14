//
//  TalkApp.swift
//  Talk
//
//  Created by Yu on 2025/4/6.
//

import SwiftData
import SwiftUI

@main
struct TalkApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // 同时支持ChatMessage和SettingsModel
            modelContainer = try ModelContainer(for: ChatMessage.self, SettingsModel.self)
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
