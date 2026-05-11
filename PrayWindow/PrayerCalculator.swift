//
//  PrayerCalculator.swift
//  PrayWindow
//
//  Created by Codex on 23/04/2026.
//

import Foundation

struct PrayerDaySchedule {
    let date: Date
    let moments: [PrayerMoment]

    var nextPrayer: PrayerMoment? {
        moments.first(where: { $0.prayer != .sunrise && $0.date > date })
    }
}

enum PrayerCalculator {
    private static let sunriseSunsetAngle = 0.833
    private static let alertWindowSeconds: TimeInterval = 600

    static func schedule(
        for date: Date,
        latitude: Double,
        longitude: Double,
        method: PrayerCalculationMethod = .ummAlQura,
        timeZone: TimeZone = .current
    ) -> PrayerDaySchedule {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let startOfDay = calendar.startOfDay(for: date)
        let components = solarComponents(for: startOfDay, latitude: latitude, longitude: longitude, timeZone: timeZone)
        let sunrise = solarEventTime(zenith: 90 + sunriseSunsetAngle, components: components, morning: true)
        let sunset = solarEventTime(zenith: 90 + sunriseSunsetAngle, components: components, morning: false)
        let solarNoon = (720 - 4 * longitude - components.equationOfTime + Double(timeZone.secondsFromGMT(for: startOfDay)) / 60) / 60
        let parameters = parameters(for: method, date: startOfDay)

        let fajr = solarEventTime(zenith: 90 + parameters.fajrAngle, components: components, morning: true)
        let dhuhr = solarNoon + (parameters.dhuhrOffsetMinutes / 60)
        let asr = asrTime(components: components, factor: parameters.asrShadowFactor)
        let maghrib = sunset
        let isha = parameters.ishaTimeHours(from: maghrib, components: components)

        let moments = [
            PrayerMoment(prayer: .fajr, date: combine(day: startOfDay, hours: fajr)),
            PrayerMoment(prayer: .sunrise, date: combine(day: startOfDay, hours: sunrise)),
            PrayerMoment(prayer: .dhuhr, date: combine(day: startOfDay, hours: dhuhr)),
            PrayerMoment(prayer: .asr, date: combine(day: startOfDay, hours: asr)),
            PrayerMoment(prayer: .maghrib, date: combine(day: startOfDay, hours: maghrib)),
            PrayerMoment(prayer: .isha, date: combine(day: startOfDay, hours: isha)),
        ]

        return PrayerDaySchedule(date: date, moments: moments)
    }

    static func nextPrayer(
        from date: Date,
        latitude: Double,
        longitude: Double,
        method: PrayerCalculationMethod = .ummAlQura,
        timeZone: TimeZone = .current
    ) -> PrayerMoment {
        let today = schedule(for: date, latitude: latitude, longitude: longitude, method: method, timeZone: timeZone)
        if let next = today.nextPrayer {
            return next
        }

        let tomorrow = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: date) ?? date
        let tomorrowSchedule = schedule(for: tomorrow, latitude: latitude, longitude: longitude, method: method, timeZone: timeZone)
        return tomorrowSchedule.moments.first(where: { $0.prayer != .sunrise }) ?? PrayerMoment(prayer: .fajr, date: tomorrow)
    }

    static func alertProgress(
        at date: Date,
        for nextPrayer: PrayerMoment,
        isEnabled: Bool
    ) -> Double? {
        guard isEnabled else { return nil }
        let remaining = nextPrayer.date.timeIntervalSince(date)
        guard remaining > 0, remaining <= alertWindowSeconds else { return nil }
        return min(max(remaining / alertWindowSeconds, 0), 1)
    }

    private static func solarComponents(for date: Date, latitude: Double, longitude: Double, timeZone: TimeZone) -> SolarComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let gamma = 2.0 * Double.pi / 365.0 * (Double(dayOfYear) - 1.0)
        let equationOfTime = 229.18 * (
            0.000075 +
            0.001868 * cos(gamma) -
            0.032077 * sin(gamma) -
            0.014615 * cos(2 * gamma) -
            0.040849 * sin(2 * gamma)
        )
        let declination = (
            0.006918 -
            0.399912 * cos(gamma) +
            0.070257 * sin(gamma) -
            0.006758 * cos(2 * gamma) +
            0.000907 * sin(2 * gamma) -
            0.002697 * cos(3 * gamma) +
            0.00148 * sin(3 * gamma)
        )

        return SolarComponents(
            latitudeRadians: latitude * Double.pi / 180,
            longitude: longitude,
            declination: declination,
            equationOfTime: equationOfTime,
            timeZoneOffsetMinutes: Double(timeZone.secondsFromGMT(for: date)) / 60
        )
    }

    fileprivate static func solarEventTime(zenith: Double, components: SolarComponents, morning: Bool) -> Double {
        let zenithRadians = zenith * Double.pi / 180
        let cosineHourAngle = (
            cos(zenithRadians) - sin(components.latitudeRadians) * sin(components.declination)
        ) / (cos(components.latitudeRadians) * cos(components.declination))
        let clamped = min(max(cosineHourAngle, -1), 1)
        let hourAngleDegrees = acos(clamped) * 180 / Double.pi
        let direction = morning ? hourAngleDegrees : -hourAngleDegrees
        let minutes = 720 - 4 * (components.longitude + direction) - components.equationOfTime + components.timeZoneOffsetMinutes
        return minutes / 60
    }

    private static func asrTime(components: SolarComponents, factor: Double) -> Double {
        let altitude = atan(1 / (factor + tan(abs(components.latitudeRadians - components.declination))))
        let cosineHourAngle = (
            sin(altitude) - sin(components.latitudeRadians) * sin(components.declination)
        ) / (cos(components.latitudeRadians) * cos(components.declination))
        let clamped = min(max(cosineHourAngle, -1), 1)
        let hourAngleDegrees = acos(clamped) * 180 / Double.pi
        let minutes = 720 - 4 * (components.longitude - hourAngleDegrees) - components.equationOfTime + components.timeZoneOffsetMinutes
        return minutes / 60
    }

    private static func parameters(for method: PrayerCalculationMethod, date: Date) -> CalculationParameters {
        switch method {
        case .ummAlQura:
            let hijriMonth = Calendar(identifier: .islamicUmmAlQura).component(.month, from: date)
            return CalculationParameters(
                fajrAngle: 18.5,
                ishaRule: .fixedHours(hijriMonth == 9 ? 2 : 1.5),
                dhuhrOffsetMinutes: 1,
                asrShadowFactor: 1
            )
        case .muslimWorldLeague:
            return CalculationParameters(fajrAngle: 18, ishaRule: .angle(17), dhuhrOffsetMinutes: 1, asrShadowFactor: 1)
        case .egyptian:
            return CalculationParameters(fajrAngle: 19.5, ishaRule: .angle(17.5), dhuhrOffsetMinutes: 1, asrShadowFactor: 1)
        case .karachi:
            return CalculationParameters(fajrAngle: 18, ishaRule: .angle(18), dhuhrOffsetMinutes: 1, asrShadowFactor: 1)
        case .northAmerica:
            return CalculationParameters(fajrAngle: 15, ishaRule: .angle(15), dhuhrOffsetMinutes: 1, asrShadowFactor: 1)
        }
    }

    private static func combine(day: Date, hours: Double) -> Date {
        let seconds = Int((hours * 3600).rounded())
        return day.addingTimeInterval(TimeInterval(seconds))
    }
}

private struct CalculationParameters {
    let fajrAngle: Double
    let ishaRule: IshaRule
    let dhuhrOffsetMinutes: Double
    let asrShadowFactor: Double

    func ishaTimeHours(from maghrib: Double, components: SolarComponents) -> Double {
        switch ishaRule {
        case let .fixedHours(hours):
            return maghrib + hours
        case let .angle(angle):
            return PrayerCalculator.solarEventTime(zenith: 90 + angle, components: components, morning: false)
        }
    }
}

private enum IshaRule {
    case fixedHours(Double)
    case angle(Double)
}

private struct SolarComponents {
    let latitudeRadians: Double
    let longitude: Double
    let declination: Double
    let equationOfTime: Double
    let timeZoneOffsetMinutes: Double
}

enum PrayerDateFormatter {
    static func timeString(for date: Date, locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    static func gregorianDayMonth(for date: Date, locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter.string(from: date)
    }

    static func hijriDayMonth(for date: Date, locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter.string(from: date)
    }
}
