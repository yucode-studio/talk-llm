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
    let modelContainer: ModelContainer?

    var modelContainerError: Bool = false

    init() {
        do {
            let schema = Schema(versionedSchema: AppSchemaV1.self)

            modelContainer = try ModelContainer(
                for: schema,
            )
        } catch {
            modelContainerError = true
            modelContainer = nil
            print("Failed to create model container: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer = modelContainer, !modelContainerError {
                ContentView()
                    .modelContainer(modelContainer)
            } else {
                VStack {
                    Text("Database is broken.")
                    Text("Sorry for the inconvenience 😭")
                    Text("Please reinstall the app.")
                }
            }
        }
    }
}
