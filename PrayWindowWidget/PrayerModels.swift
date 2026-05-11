//
//  PrayerModels.swift
//  PrayWindowWidget
//
//  Created by Codex on 23/04/2026.
//

import Foundation
import SwiftUI
import UIKit

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case arabic
    case english

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .english: return "en"
        case .arabic: return "ar"
        }
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    var layoutDirection: LayoutDirection {
        self == .arabic ? .rightToLeft : .leftToRight
    }

    var isArabic: Bool {
        self == .arabic
    }

    func text(_ key: LocalizedTextKey) -> String {
        key.value(for: self)
    }
}

enum LocalizedTextKey {
    case nextPrayer
    case today
    case hijri
    case gregorian
    case location
    case prayerTimes
    case upcomingPrayers
    case fontSize
    case remainingTime
    case day
    case month
    case solarYear
    case wisdomOfTheDay

    func value(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.nextPrayer, .english): return "Next Prayer"
        case (.nextPrayer, .arabic): return "الصلاة القادمة"
        case (.today, .english): return "Today"
        case (.today, .arabic): return "اليوم"
        case (.hijri, .english): return "Hijri"
        case (.hijri, .arabic): return "هجري"
        case (.gregorian, .english): return "Gregorian"
        case (.gregorian, .arabic): return "ميلادي"
        case (.location, .english): return "Location"
        case (.location, .arabic): return "الموقع"
        case (.prayerTimes, .english): return "Prayer Times"
        case (.prayerTimes, .arabic): return "مواقيت الصلاة"
        case (.upcomingPrayers, .english): return "Upcoming Prayers"
        case (.upcomingPrayers, .arabic): return "الصلوات القادمة"
        case (.fontSize, .english): return "Font Size"
        case (.fontSize, .arabic): return "حجم الخط"
        case (.remainingTime, .english): return "Time Remaining"
        case (.remainingTime, .arabic): return "الوقت المتبقي"
        case (.day, .english): return "Day"
        case (.day, .arabic): return "اليوم"
        case (.month, .english): return "Month"
        case (.month, .arabic): return "الشهر"
        case (.solarYear, .english): return "Solar Year"
        case (.solarYear, .arabic): return "السنة الشمسية"
        case (.wisdomOfTheDay, .english): return "Wisdom of the Day"
        case (.wisdomOfTheDay, .arabic): return "حكمة اليوم"
        }
    }
}

enum WidgetTextScale: String, CaseIterable, Codable, Identifiable {
    case compact
    case regular
    case large

    var id: String { rawValue }

    var multiplier: CGFloat {
        switch self {
        case .compact: return 0.88
        case .regular: return 1
        case .large: return 1.14
        }
    }
}

enum Prayer: String, CaseIterable, Codable, Identifiable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.fajr, .english): return "Fajr"
        case (.fajr, .arabic): return "الفجر"
        case (.sunrise, .english): return "Sunrise"
        case (.sunrise, .arabic): return "الشروق"
        case (.dhuhr, .english): return "Dhuhr"
        case (.dhuhr, .arabic): return "الظهر"
        case (.asr, .english): return "Asr"
        case (.asr, .arabic): return "العصر"
        case (.maghrib, .english): return "Maghrib"
        case (.maghrib, .arabic): return "المغرب"
        case (.isha, .english): return "Isha"
        case (.isha, .arabic): return "العشاء"
        }
    }
}

struct PrayerMoment: Identifiable, Hashable {
    let prayer: Prayer
    let date: Date

    var id: String {
        "\(prayer.rawValue)-\(date.timeIntervalSince1970)"
    }
}

enum WidgetFontStyle: String, CaseIterable, Codable, Identifiable {
    case rubik
    case cairo
    case tajawal
    case playpenSansArabic

    var id: String { rawValue }

    var design: Font.Design {
        switch self {
        case .rubik, .cairo, .tajawal, .playpenSansArabic: return .default
        }
    }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let customName = fontName(for: weight), UIFont(name: customName, size: size) != nil {
            return .custom(customName, size: size)
        }

        return .system(size: size, weight: weight, design: design)
    }

    private func fontName(for weight: Font.Weight) -> String? {
        switch self {
        case .rubik:
            switch weight {
            case .bold, .heavy, .black: return "Rubik-Light_Bold"
            case .semibold: return "Rubik-Light_SemiBold"
            case .medium: return "Rubik-Light_Medium"
            default: return "Rubik-Light_Regular"
            }
        case .cairo:
            switch weight {
            case .bold, .heavy, .black: return "Cairo-Regular_Bold"
            case .semibold: return "Cairo-Regular_SemiBold"
            case .medium: return "Cairo-Regular_Medium"
            default: return "Cairo-Regular"
            }
        case .tajawal:
            switch weight {
            case .bold, .heavy, .black, .semibold, .medium: return "Tajawal-Bold"
            default: return "Tajawal-Regular"
            }
        case .playpenSansArabic:
            switch weight {
            case .bold, .heavy, .black: return "PlaypenSansArabic-Bold"
            case .semibold: return "PlaypenSansArabic-SemiBold"
            case .medium: return "PlaypenSansArabic-Medium"
            default: return "PlaypenSansArabic-Regular"
            }
        }
    }
}

struct WidgetTheme: Codable, Hashable {
    var backgroundHex: String
    var textHex: String
    var fontStyle: WidgetFontStyle
    var textScale: WidgetTextScale
    var fontSizeMultiplier: Double

    enum CodingKeys: String, CodingKey {
        case backgroundHex
        case textHex
        case fontStyle
        case textScale
        case fontSizeMultiplier
    }

    init(
        backgroundHex: String,
        textHex: String,
        fontStyle: WidgetFontStyle,
        textScale: WidgetTextScale = .regular,
        fontSizeMultiplier: Double = 1
    ) {
        self.backgroundHex = backgroundHex
        self.textHex = textHex
        self.fontStyle = fontStyle
        self.textScale = textScale
        self.fontSizeMultiplier = fontSizeMultiplier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        backgroundHex = try container.decodeIfPresent(String.self, forKey: .backgroundHex) ?? "#123524"
        textHex = try container.decodeIfPresent(String.self, forKey: .textHex) ?? "#F9F7F1"
        fontStyle = try container.decodeIfPresent(WidgetFontStyle.self, forKey: .fontStyle) ?? .rubik
        textScale = try container.decodeIfPresent(WidgetTextScale.self, forKey: .textScale) ?? .regular
        fontSizeMultiplier = try container.decodeIfPresent(Double.self, forKey: .fontSizeMultiplier) ?? 1
    }

    static let `default` = WidgetTheme(
        backgroundHex: "#123524",
        textHex: "#F9F7F1",
        fontStyle: .rubik,
        textScale: .regular,
        fontSizeMultiplier: 1
    )
}

enum WidgetPhotoChoice: String, CaseIterable, Codable, Identifiable {
    case none
    case makkah
    case madinah
    case alquds
    case custom

    var id: String { rawValue }

    var assetName: String? {
        switch self {
        case .none, .custom: return nil
        case .makkah: return "makkah_photo"
        case .madinah: return "madinah_photo"
        case .alquds: return "alquds_photo"
        }
    }
}

enum PrayerCalculationMethod: String, CaseIterable, Codable, Identifiable {
    case ummAlQura
    case muslimWorldLeague
    case egyptian
    case karachi
    case northAmerica

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.ummAlQura, .english): return "Umm Al-Qura"
        case (.ummAlQura, .arabic): return "أم القرى"
        case (.muslimWorldLeague, .english): return "Muslim World League"
        case (.muslimWorldLeague, .arabic): return "رابطة العالم الإسلامي"
        case (.egyptian, .english): return "Egyptian"
        case (.egyptian, .arabic): return "الهيئة المصرية"
        case (.karachi, .english): return "Karachi"
        case (.karachi, .arabic): return "كراتشي"
        case (.northAmerica, .english): return "North America"
        case (.northAmerica, .arabic): return "أمريكا الشمالية"
        }
    }
}

struct PrayerSettings: Codable, Hashable {
    var city: String
    var latitude: Double
    var longitude: Double
    var usesCurrentLocation: Bool
    var language: AppLanguage
    var theme: WidgetTheme
    var photoChoice: WidgetPhotoChoice
    var customPhotoFocusX: Double
    var customPhotoFocusY: Double
    var customPhotoRevision: String
    var calculationMethod: PrayerCalculationMethod
    var showsPrePrayerAlertBar: Bool
    var prePrayerAlertBarColorHex: String

    enum CodingKeys: String, CodingKey {
        case city
        case latitude
        case longitude
        case usesCurrentLocation
        case language
        case theme
        case photoChoice
        case showsCustomPhoto
        case customPhotoFocusX
        case customPhotoFocusY
        case customPhotoRevision
        case calculationMethod
        case showsPrePrayerAlertBar
        case prePrayerAlertBarColorHex
    }

    init(
        city: String,
        latitude: Double,
        longitude: Double,
        usesCurrentLocation: Bool,
        language: AppLanguage,
        theme: WidgetTheme,
        photoChoice: WidgetPhotoChoice = .makkah,
        customPhotoFocusX: Double = 0.5,
        customPhotoFocusY: Double = 0.5,
        customPhotoRevision: String = "",
        calculationMethod: PrayerCalculationMethod = .ummAlQura,
        showsPrePrayerAlertBar: Bool = true,
        prePrayerAlertBarColorHex: String = "#D97706"
    ) {
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.usesCurrentLocation = usesCurrentLocation
        self.language = language
        self.theme = theme
        self.photoChoice = photoChoice
        self.customPhotoFocusX = customPhotoFocusX
        self.customPhotoFocusY = customPhotoFocusY
        self.customPhotoRevision = customPhotoRevision
        self.calculationMethod = calculationMethod
        self.showsPrePrayerAlertBar = showsPrePrayerAlertBar
        self.prePrayerAlertBarColorHex = prePrayerAlertBarColorHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? "Makkah"
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 21.3891
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 39.8579
        usesCurrentLocation = try container.decodeIfPresent(Bool.self, forKey: .usesCurrentLocation) ?? false
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .arabic
        theme = try container.decodeIfPresent(WidgetTheme.self, forKey: .theme) ?? .default
        if let decodedPhotoChoice = try container.decodeIfPresent(WidgetPhotoChoice.self, forKey: .photoChoice) {
            photoChoice = decodedPhotoChoice
        } else {
            photoChoice = (try container.decodeIfPresent(Bool.self, forKey: .showsCustomPhoto) ?? false) ? .custom : .makkah
        }
        customPhotoFocusX = try container.decodeIfPresent(Double.self, forKey: .customPhotoFocusX) ?? 0.5
        customPhotoFocusY = try container.decodeIfPresent(Double.self, forKey: .customPhotoFocusY) ?? 0.5
        customPhotoRevision = try container.decodeIfPresent(String.self, forKey: .customPhotoRevision) ?? ""
        calculationMethod = try container.decodeIfPresent(PrayerCalculationMethod.self, forKey: .calculationMethod) ?? .ummAlQura
        showsPrePrayerAlertBar = try container.decodeIfPresent(Bool.self, forKey: .showsPrePrayerAlertBar) ?? true
        prePrayerAlertBarColorHex = try container.decodeIfPresent(String.self, forKey: .prePrayerAlertBarColorHex) ?? "#D97706"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(city, forKey: .city)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(usesCurrentLocation, forKey: .usesCurrentLocation)
        try container.encode(language, forKey: .language)
        try container.encode(theme, forKey: .theme)
        try container.encode(photoChoice, forKey: .photoChoice)
        try container.encode(customPhotoFocusX, forKey: .customPhotoFocusX)
        try container.encode(customPhotoFocusY, forKey: .customPhotoFocusY)
        try container.encode(customPhotoRevision, forKey: .customPhotoRevision)
        try container.encode(calculationMethod, forKey: .calculationMethod)
        try container.encode(showsPrePrayerAlertBar, forKey: .showsPrePrayerAlertBar)
        try container.encode(prePrayerAlertBarColorHex, forKey: .prePrayerAlertBarColorHex)
    }

    var customPhotoFocusPoint: CGPoint {
        CGPoint(x: customPhotoFocusX, y: customPhotoFocusY)
    }

    static let `default` = PrayerSettings(
        city: "Makkah",
        latitude: 21.3891,
        longitude: 39.8579,
        usesCurrentLocation: false,
        language: .arabic,
        theme: WidgetTheme(
            backgroundHex: "#123524",
            textHex: "#F9F7F1",
            fontStyle: .rubik
        ),
        photoChoice: .makkah,
        customPhotoFocusX: 0.5,
        customPhotoFocusY: 0.5,
        customPhotoRevision: "",
        calculationMethod: .ummAlQura,
        showsPrePrayerAlertBar: true,
        prePrayerAlertBarColorHex: "#D97706"
    )
}

struct SaudiSolarHijriDate: Hashable {
    let day: Int
    let monthNameArabic: String
    let year: Int

    func monthName(for language: AppLanguage) -> String {
        guard !language.isArabic else { return monthNameArabic }

        switch monthNameArabic {
        case "الحمل": return "Aries"
        case "الثور": return "Taurus"
        case "الجوزاء": return "Gemini"
        case "السرطان": return "Cancer"
        case "الأسد": return "Leo"
        case "السنبلة": return "Virgo"
        case "الميزان": return "Libra"
        case "العقرب": return "Scorpio"
        case "القوس": return "Sagittarius"
        case "الجدي": return "Capricorn"
        case "الدلو": return "Aquarius"
        case "الحوت": return "Pisces"
        default: return monthNameArabic
        }
    }

    static func from(gregorian date: Date) -> SaudiSolarHijriDate {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard
            let gregorianYear = components.year,
            let month = components.month,
            let day = components.day
        else {
            return SaudiSolarHijriDate(day: 1, monthNameArabic: "الحمل", year: 1400)
        }

        let solarYear = (month > 3 || (month == 3 && day >= 21))
            ? gregorianYear - 621
            : gregorianYear - 622

        let boundaries: [(month: Int, day: Int, name: String)] = [
            (3, 21, "الحمل"),
            (4, 21, "الثور"),
            (5, 22, "الجوزاء"),
            (6, 22, "السرطان"),
            (7, 23, "الأسد"),
            (8, 23, "السنبلة"),
            (9, 23, "الميزان"),
            (10, 23, "العقرب"),
            (11, 22, "القوس"),
            (12, 22, "الجدي"),
            (1, 21, "الدلو"),
            (2, 20, "الحوت"),
        ]

        let currentKey = month * 100 + day
        let ordered = boundaries.sorted {
            ($0.month * 100 + $0.day) < ($1.month * 100 + $1.day)
        }

        var selected = ordered.last { currentKey >= ($0.month * 100 + $0.day) }
        if selected == nil {
            selected = ordered.last
        }

        guard let active = selected else {
            return SaudiSolarHijriDate(day: 1, monthNameArabic: "الحمل", year: solarYear)
        }

        let startYear = active.month > month ? gregorianYear - 1 : gregorianYear
        let startDate = calendar.date(from: DateComponents(year: startYear, month: active.month, day: active.day)) ?? date
        let dayNumber = (calendar.dateComponents([.day], from: startDate, to: date).day ?? 0) + 1

        return SaudiSolarHijriDate(day: max(dayNumber, 1), monthNameArabic: active.name, year: solarYear)
    }
}

extension Color {
    init(hex: String) {
        let sanitized = hex
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red, green, blue, alpha: UInt64
        switch sanitized.count {
        case 8:
            (alpha, red, green, blue) = (
                (value >> 24) & 0xFF,
                (value >> 16) & 0xFF,
                (value >> 8) & 0xFF,
                value & 0xFF
            )
        default:
            (alpha, red, green, blue) = (255, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "#%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}
