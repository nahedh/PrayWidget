//
//  WidgetSettingsStore.swift
//  PrayWindowWidget
//
//  Created by Codex on 23/04/2026.
//

import Foundation
import UIKit

enum SharedStore {
    static let appGroupID = "group.com.nahedh.apps.PrayWindow"
    static let settingsKey = "prayer_settings"
    static let customPhotoFilePrefix = "widget_custom_photo_"
    static let customPhotoDataKey = "widget_custom_photo_data"
}

final class WidgetSettingsStore {
    static let shared = WidgetSettingsStore()

    private let defaults = UserDefaults(suiteName: SharedStore.appGroupID) ?? .standard
    private let decoder = JSONDecoder()

    func load() -> PrayerSettings {
        guard let data = defaults.data(forKey: SharedStore.settingsKey),
              let settings = try? decoder.decode(PrayerSettings.self, from: data) else {
            return .default
        }
        return sanitized(settings)
    }

    private func sanitized(_ settings: PrayerSettings) -> PrayerSettings {
        var copy = settings
        if copy.theme.backgroundHex.uppercased() == "#00000000" {
            copy.theme.backgroundHex = WidgetTheme.default.backgroundHex
        }
        if copy.theme.textHex.uppercased() == "#00000000" {
            copy.theme.textHex = WidgetTheme.default.textHex
        }
        if copy.prePrayerAlertBarColorHex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            copy.prePrayerAlertBarColorHex = PrayerSettings.default.prePrayerAlertBarColorHex
        }
        copy.theme.fontSizeMultiplier = min(max(copy.theme.fontSizeMultiplier, 0.7), 1.6)
        copy.customPhotoFocusX = min(max(copy.customPhotoFocusX, 0), 1)
        copy.customPhotoFocusY = min(max(copy.customPhotoFocusY, 0), 1)
        return copy
    }

    func customPhotoImage(revision: String = "") -> UIImage? {
        if let containerURL = customPhotoContainerURL,
           let url = resolvedCustomPhotoURL(for: revision, containerURL: containerURL),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }

        if let data = defaults.data(forKey: SharedStore.customPhotoDataKey),
           let image = UIImage(data: data) {
            return image
        }

        return nil
    }

    private var customPhotoContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupID)
    }

    private func customPhotoURL(for revision: String, containerURL: URL) -> URL {
        containerURL.appendingPathComponent("\(SharedStore.customPhotoFilePrefix)\(revision).jpg")
    }

    private func resolvedCustomPhotoURL(for revision: String, containerURL: URL) -> URL? {
        if !revision.isEmpty {
            return customPhotoURL(for: revision, containerURL: containerURL)
        }

        return try? FileManager.default
            .contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
            .first(where: { $0.lastPathComponent.hasPrefix(SharedStore.customPhotoFilePrefix) })
    }
}
