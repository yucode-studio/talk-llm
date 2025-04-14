//
//  ContentView.swift
//  Talk
//
//  Created by Yu on 2025/4/6.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var showingChatHistory = false
    @State private var showingSettings = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.backgroundColor().ignoresSafeArea()

                VStack {
                    HStack {
                        Spacer()

                        Button {
                            showingSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(ColorTheme.backgroundColor())
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(ColorTheme.textColor())
                                )
                        }
                    }

                    Spacer()
                    VoiceChatView()
                    Spacer()

                    HStack {
                        Spacer()

                        Button {
                            showingChatHistory.toggle()
                        } label: {
                            Image(systemName: "archivebox.fill")
                                .foregroundColor(ColorTheme.backgroundColor())
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(ColorTheme.textColor())
                                )
                        }
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showingChatHistory) {
                ChatHistoryView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(modelContext: modelContext)
            }
            .navigationTitle("Voice Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ChatMessage.self, SettingsModel.self, configurations: config)

        return ContentView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
