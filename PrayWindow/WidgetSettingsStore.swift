//
//  WidgetSettingsStore.swift
//  PrayWindow
//
//  Created by Codex on 23/04/2026.
//

import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers
#if canImport(WidgetKit)
import WidgetKit
#endif

enum SharedStore {
    static let appGroupID = "group.com.nahedh.apps.PrayWindow"
    static let settingsKey = "prayer_settings"
    static let customPhotoFilePrefix = "widget_custom_photo_"
    static let customPhotoDataKey = "widget_custom_photo_data"
}

final class WidgetSettingsStore {
    static let shared = WidgetSettingsStore()

    private let defaults = UserDefaults(suiteName: SharedStore.appGroupID) ?? .standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func load() -> PrayerSettings {
        guard let data = defaults.data(forKey: SharedStore.settingsKey),
              let settings = try? decoder.decode(PrayerSettings.self, from: data) else {
            return .default
        }
        return sanitized(settings)
    }

    func save(_ settings: PrayerSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: SharedStore.settingsKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    func saveCustomPhotoData(_ rawData: Data, replacing revision: String) -> String? {
        guard
            let preparedImage = preparedWidgetPhoto(from: rawData),
            let data = encodedWidgetPhotoData(from: preparedImage),
            let containerURL = customPhotoContainerURL
        else {
            return nil
        }

        let newRevision = UUID().uuidString.lowercased()
        let url = customPhotoURL(for: newRevision, containerURL: containerURL)

        do {
            try data.write(to: url, options: .atomic)
            defaults.set(data, forKey: SharedStore.customPhotoDataKey)
            if !revision.isEmpty {
                try? FileManager.default.removeItem(at: customPhotoURL(for: revision, containerURL: containerURL))
            }
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
            return newRevision
        } catch {
            return nil
        }
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

    func removeCustomPhoto(revision: String) {
        defaults.removeObject(forKey: SharedStore.customPhotoDataKey)
        if let containerURL = customPhotoContainerURL {
            if !revision.isEmpty {
                try? FileManager.default.removeItem(at: customPhotoURL(for: revision, containerURL: containerURL))
            } else {
                cleanupLegacyCustomPhotos(in: containerURL)
            }
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
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

    private func cleanupLegacyCustomPhotos(in containerURL: URL) {
        let urls = (try? FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)) ?? []
        for url in urls where url.lastPathComponent.hasPrefix(SharedStore.customPhotoFilePrefix) {
            try? FileManager.default.removeItem(at: url)
        }
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

    private func preparedWidgetPhoto(from rawData: Data, maxPixelSize: CGFloat = 1100) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(rawData as CFData, options) else {
            return UIImage(data: rawData)?.normalizedForWidgetStorage()?.scaledForWidgetStorage(maxDimension: maxPixelSize)
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize)
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return UIImage(data: rawData)?.normalizedForWidgetStorage()?.scaledForWidgetStorage(maxDimension: maxPixelSize)
        }

        let image = UIImage(cgImage: cgImage)
        return image.normalizedForWidgetStorage()
    }

    private func encodedWidgetPhotoData(from image: UIImage) -> Data? {
        if let cgImage = image.cgImage {
            let mutableData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
                return image.jpegData(compressionQuality: 0.74)
            }

            let options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: 0.74,
                kCGImagePropertyOrientation: CGImagePropertyOrientation.up.rawValue
            ]
            CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
            guard CGImageDestinationFinalize(destination) else {
                return image.jpegData(compressionQuality: 0.74)
            }
            return mutableData as Data
        }

        return image.jpegData(compressionQuality: 0.74)
    }
}

extension UIImage {
    func normalizedForWidgetStorage() -> UIImage? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func scaledForWidgetStorage(maxDimension: CGFloat = 1800) -> UIImage? {
        let longestSide = max(size.width, size.height)
        guard longestSide > 0 else { return nil }
        guard longestSide > maxDimension else { return self }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
