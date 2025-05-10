//
//  Migration.swift
//  Talk
//
//  Created by Yu on 2025/5/10.
//
import SwiftData

enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [ChatMessage.self, SettingsModel.self]
    }
}
