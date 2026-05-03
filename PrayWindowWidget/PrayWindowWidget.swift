//
//  PrayWindowWidget.swift
//  PrayWindowWidget
//
//  Created by Codex on 23/04/2026.
//

import SwiftUI
import UIKit
import WidgetKit

struct PrayWindowEntry: TimelineEntry {
    let date: Date
    let settings: PrayerSettings
    let nextPrayer: PrayerMoment
}

struct PrayWindowTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayWindowEntry {
        sampleEntry(at: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayWindowEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayWindowEntry>) -> Void) {
        let now = Date()
        let entry = entry(at: now)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func entry(at date: Date) -> PrayWindowEntry {
        let settings = WidgetSettingsStore.shared.load()
        let nextPrayer = PrayerCalculator.nextPrayer(
            from: date,
            latitude: settings.latitude,
            longitude: settings.longitude
        )
        return PrayWindowEntry(date: date, settings: settings, nextPrayer: nextPrayer)
    }

    private func sampleEntry(at date: Date) -> PrayWindowEntry {
        let settings = PrayerSettings.default
        let nextPrayer = PrayerCalculator.nextPrayer(
            from: date,
            latitude: settings.latitude,
            longitude: settings.longitude
        )
        return PrayWindowEntry(date: date, settings: settings, nextPrayer: nextPrayer)
    }
}

struct PrayWindowWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: PrayWindowEntry

    var body: some View {
        let schedule = PrayerCalculator.schedule(
            for: entry.date,
            latitude: entry.settings.latitude,
            longitude: entry.settings.longitude
        )

        PrayerWidgetChrome(entry: entry, family: family, moments: schedule.moments)
            .environment(\.layoutDirection, entry.settings.language.layoutDirection)
    }
}

struct PrayWindowCountdownWidgetEntryView: View {
    let entry: PrayWindowEntry

    var body: some View {
        PrayerCountdownSmallView(entry: entry)
            .environment(\.layoutDirection, entry.settings.language.layoutDirection)
    }
}

struct PrayWindowImagePrayerWidgetEntryView: View {
    let entry: PrayWindowEntry

    var body: some View {
        let schedule = PrayerCalculator.schedule(
            for: entry.date,
            latitude: entry.settings.latitude,
            longitude: entry.settings.longitude
        )

        PrayerImageMediumView(entry: entry, moments: schedule.moments)
            .environment(\.layoutDirection, entry.settings.language.layoutDirection)
    }
}

struct PrayWindowDateWisdomWidgetEntryView: View {
    let entry: PrayWindowEntry

    var body: some View {
        PrayerDateWisdomMediumView(entry: entry)
            .environment(\.layoutDirection, entry.settings.language.layoutDirection)
    }
}

struct PrayWindowLockScreenCountdownWidgetEntryView: View {
    let entry: PrayWindowEntry

    var body: some View {
        PrayerLockScreenCountdownCircularView(entry: entry)
            .environment(\.layoutDirection, entry.settings.language.layoutDirection)
    }
}

struct PrayWindowLockScreenPrayerWidgetEntryView: View {
    let entry: PrayWindowEntry

    var body: some View {
        PrayerLockScreenPrayerRectangularView(entry: entry)
            .environment(\.layoutDirection, entry.settings.language.layoutDirection)
    }
}

private struct WidgetMetrics {
    let size: CGSize
    let multiplier: CGFloat

    private var widthScale: CGFloat { size.width / 329 }
    private var heightScale: CGFloat { size.height / 345 }
    private var baseScale: CGFloat { max(0.76, min(1.28, min(widthScale, heightScale))) }

    func font(_ base: CGFloat) -> CGFloat {
        base * baseScale * multiplier
    }

    func inset(_ base: CGFloat) -> CGFloat {
        base * baseScale
    }
}

private struct PrayerLockScreenCountdownCircularView: View {
    let entry: PrayWindowEntry

    private var language: AppLanguage { entry.settings.language }
    private var locale: Locale { language.locale }

    var body: some View {
        VStack(spacing: 2) {
            Text(shortPrayerName)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .widgetTextFit(lines: 1, minScale: 0.6)

            Text(entry.nextPrayer.date, style: .timer)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .widgetTextFit(lines: 1, minScale: 0.4)

            Text(PrayerDateFormatter.timeString(for: entry.nextPrayer.date, locale: locale))
                .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .widgetTextFit(lines: 1, minScale: 0.65)
                .opacity(0.82)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
        .background {
            Circle()
                .stroke(Color.primary.opacity(0.2), lineWidth: 2)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var shortPrayerName: String {
        let title = entry.nextPrayer.prayer.title(for: language)
        return title.count > 10 ? String(title.prefix(10)) : title
    }
}

private struct PrayerLockScreenPrayerRectangularView: View {
    let entry: PrayWindowEntry

    private var language: AppLanguage { entry.settings.language }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(entry.nextPrayer.prayer.title(for: language))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .widgetTextFit(lines: 1, minScale: 0.65)

            Text(entry.nextPrayer.date, style: .timer)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .widgetTextFit(lines: 1, minScale: 0.5)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

private enum WeekdaySealAsset {
    static func imageName(for date: Date) -> String {
        switch Calendar(identifier: .gregorian).component(.weekday, from: date) {
        case 1: return "weekday_sun"
        case 2: return "weekday_mon"
        case 3: return "weekday_tue"
        case 4: return "weekday_wed"
        case 5: return "weekday_thu"
        case 6: return "weekday_fri"
        default: return "weekday_sat"
        }
    }

    static func uiImage(for date: Date) -> UIImage? {
        let name = imageName(for: date)
        if let image = UIImage(named: name) {
            return image
        }

        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "WeekdaySeals"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }

        return nil
    }
}

private struct WeekdaySealImageView: View {
    let date: Date
    let side: CGFloat

    var body: some View {
        Group {
            if let uiImage = WeekdaySealAsset.uiImage(for: date) {
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            } else {
                VStack(spacing: 2) {
                    Text(weekdayFallbackArabic)
                        .font(.custom("Cairo-Regular_Bold", size: side * 0.16))
                    Text(weekdayFallbackEnglish)
                        .font(.system(size: side * 0.16, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(Color(hex: "#2C2A1D"))
                .background(
                    RoundedRectangle(cornerRadius: side * 0.24, style: .continuous)
                        .fill(Color(hex: "#E6EDC7"))
                        .overlay(RoundedRectangle(cornerRadius: side * 0.24, style: .continuous).stroke(Color(hex: "#8E8B74"), lineWidth: 1))
                )
            }
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }

    private var weekdayFallbackArabic: String {
        switch Calendar(identifier: .gregorian).component(.weekday, from: date) {
        case 1: return "الأحد"
        case 2: return "الإثنين"
        case 3: return "الثلاثاء"
        case 4: return "الأربعاء"
        case 5: return "الخميس"
        case 6: return "الجمعة"
        default: return "السبت"
        }
    }

    private var weekdayFallbackEnglish: String {
        switch Calendar(identifier: .gregorian).component(.weekday, from: date) {
        case 1: return "SUN"
        case 2: return "MON"
        case 3: return "TUE"
        case 4: return "WED"
        case 5: return "THU"
        case 6: return "FRI"
        default: return "SAT"
        }
    }
}

private struct CalendarStarSectionItem: Identifiable {
    let id: String
    let title: String
    let value: String
    let secondary: String?

    init(title: String, value: String, secondary: String? = nil) {
        self.id = title
        self.title = title
        self.value = value
        self.secondary = secondary
    }
}

private struct CalendarStarSectionRow: View {
    let items: [CalendarStarSectionItem]
    let metrics: WidgetMetrics
    let background: Color
    let foreground: Color

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                VStack(spacing: metrics.inset(1.2)) {
                    Text(item.title)
                        .font(WidgetFontStyle.cairo.font(size: metrics.font(11.5), weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(item.value)
                        .font(WidgetFontStyle.cairo.font(size: metrics.font(11.5), weight: .bold))
                    if let secondary = item.secondary {
                        Text(secondary)
                            .font(WidgetFontStyle.cairo.font(size: metrics.font(8.8), weight: .regular))
                            .foregroundStyle(Color(hex: "#615A42"))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: metrics.inset(item.secondary == nil ? 34 : 44))
                .foregroundStyle(foreground)
                .background(background.opacity(0.82))
            }
        }
    }
}

private enum WidgetPhotoSource {
    static func uiImage(for settings: PrayerSettings) -> UIImage? {
        switch settings.photoChoice {
        case .none:
            return nil
        case .custom:
            return WidgetSettingsStore.shared.customPhotoImage(revision: settings.customPhotoRevision)
        case .makkah, .madinah, .alquds:
            guard let assetName = settings.photoChoice.assetName else { return nil }
            return UIImage(named: assetName)
        }
    }
}

private struct WidgetPhotoLayout {
    let scaledSize: CGSize
    let center: CGPoint

    init(imageSize: CGSize, containerSize: CGSize, focalPoint: CGPoint) {
        let safeImageSize = CGSize(width: max(imageSize.width, 1), height: max(imageSize.height, 1))
        let safeContainerSize = CGSize(width: max(containerSize.width, 1), height: max(containerSize.height, 1))
        let scale = max(safeContainerSize.width / safeImageSize.width, safeContainerSize.height / safeImageSize.height)

        scaledSize = CGSize(width: safeImageSize.width * scale, height: safeImageSize.height * scale)

        let clampedX = min(max(focalPoint.x, 0), 1)
        let clampedY = min(max(focalPoint.y, 0), 1)
        let extraX = max((scaledSize.width - safeContainerSize.width) / 2, 0)
        let extraY = max((scaledSize.height - safeContainerSize.height) / 2, 0)

        center = CGPoint(
            x: safeContainerSize.width / 2 + (0.5 - clampedX) * extraX * 2,
            y: safeContainerSize.height / 2 + (0.5 - clampedY) * extraY * 2
        )
    }
}

private struct WidgetPhotoFillView: View {
    let image: UIImage
    let focalPoint: CGPoint

    var body: some View {
        GeometryReader { proxy in
            let layout = WidgetPhotoLayout(
                imageSize: image.size,
                containerSize: proxy.size,
                focalPoint: focalPoint
            )

            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .frame(width: layout.scaledSize.width, height: layout.scaledSize.height)
                .position(layout.center)
        }
        .clipped()
    }
}

private struct WidgetPhotoBackground: View {
    let settings: PrayerSettings
    let tint: Color
    let tintOpacity: Double

    var body: some View {
        if let image = WidgetPhotoSource.uiImage(for: settings) {
            ZStack {
                WidgetPhotoFillView(image: image, focalPoint: settings.customPhotoFocusPoint)
                tint.opacity(min(tintOpacity, 0.62))
                LinearGradient(
                    colors: [Color.black.opacity(0.02), Color.black.opacity(0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        } else {
            tint
        }
    }
}

struct PrayerWidgetChrome: View {
    let entry: PrayWindowEntry
    let family: WidgetFamily
    let moments: [PrayerMoment]

    private var language: AppLanguage { entry.settings.language }
    private var locale: Locale { language.locale }
    private var background: Color { Color(hex: entry.settings.theme.backgroundHex) }
    private var foreground: Color { Color(hex: entry.settings.theme.textHex) }
    private var panelBackground: Color { background.opacity(0.42) }
    private var panelBorder: Color { foreground.opacity(0.16) }
    private var prayerMoments: [PrayerMoment] {
        moments.filter { $0.prayer != .sunrise }
    }
    var body: some View {
        GeometryReader { proxy in
            let metrics = WidgetMetrics(
                size: proxy.size,
                multiplier: entry.settings.theme.textScale.multiplier * CGFloat(entry.settings.theme.fontSizeMultiplier)
            )

            ZStack {
                WidgetPhotoBackground(
                    settings: entry.settings,
                    tint: background,
                    tintOpacity: 0.78
                )

                content(metrics: metrics)
                    .padding(widgetContentPadding(metrics: metrics))
            }
            .foregroundStyle(foreground)
        }
        .containerBackground(for: .widget) { background }
    }

    @ViewBuilder
    private func content(metrics: WidgetMetrics) -> some View {
        switch family {
        case .systemSmall:
            smallLayout(metrics: metrics)
        case .systemMedium:
            mediumLayout(metrics: metrics)
        case .systemLarge:
            largeLayout(metrics: metrics)
        default:
            mediumLayout(metrics: metrics)
        }
    }

    private var weekdayTitle: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter.string(from: entry.date)
    }

    private var gregorianDay: String {
        String(Calendar(identifier: .gregorian).component(.day, from: entry.date))
    }

    private var hijriDay: String {
        String(Calendar(identifier: .islamicUmmAlQura).component(.day, from: entry.date))
    }

    private var gregorianMonth: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: entry.date)
    }

    private var hijriMonth: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: entry.date)
    }

    private func smallLayout(metrics: WidgetMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.inset(6)) {
            headerStrip(metrics: metrics)
            VStack(alignment: .leading, spacing: metrics.inset(3)) {
                Text(language.text(.nextPrayer))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .opacity(0.74)
                    .widgetTextFit(minScale: 0.84)

                Text(entry.nextPrayer.prayer.title(for: language))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .widgetTextFit(lines: 1, minScale: 0.68)

                Text(PrayerDateFormatter.timeString(for: entry.nextPrayer.date, locale: locale))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(18), weight: .bold))
                    .monospacedDigit()
                    .widgetTextFit(lines: 1, minScale: 0.6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .padding(metrics.inset(10))
        .background(panelBackground)
        .overlay(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous).stroke(panelBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func mediumLayout(metrics: WidgetMetrics) -> some View {
        HStack(spacing: metrics.inset(12)) {
            VStack(alignment: .leading, spacing: metrics.inset(8)) {
                headerStrip(metrics: metrics)

                Spacer(minLength: 0)

                Text(language.text(.nextPrayer))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .opacity(0.74)
                Text(entry.nextPrayer.prayer.title(for: language))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .widgetTextFit(minScale: 0.72)
                Text(PrayerDateFormatter.timeString(for: entry.nextPrayer.date, locale: locale))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(19), weight: .bold))
                    .monospacedDigit()
                    .widgetTextFit(minScale: 0.62)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(metrics.inset(14))
            .background(panelBackground)
            .overlay(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous).stroke(panelBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous))

            VStack(alignment: .leading, spacing: metrics.inset(7)) {
                Text(language.text(.prayerTimes))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(10), weight: .semibold))
                    .opacity(0.74)

                ForEach(Array(prayerMoments.prefix(5)), id: \.id) { moment in
                    prayerLine(moment: moment, metrics: metrics, compact: true)
                }
            }
            .frame(width: proxySideWidth(for: metrics), alignment: .leading)
            .padding(metrics.inset(10))
            .background(panelBackground)
            .overlay(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous).stroke(panelBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous))
        }
    }

    private func largeLayout(metrics: WidgetMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.inset(12)) {
            HStack(spacing: metrics.inset(8)) {
                infoPanel(day: gregorianDay, title: gregorianMonth, subtitle: language.text(.gregorian), metrics: metrics)
                infoPanel(day: weekdayTitle, title: PrayerDateFormatter.gregorianDayMonth(for: entry.date, locale: locale), subtitle: language.text(.today), metrics: metrics, centered: true)
                infoPanel(day: hijriDay, title: hijriMonth, subtitle: language.text(.hijri), metrics: metrics)
            }

            HStack(alignment: .top, spacing: metrics.inset(10)) {
                VStack(alignment: .leading, spacing: metrics.inset(9)) {
                    Text(language.text(.nextPrayer))
                        .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                        .opacity(0.74)
                    Text(entry.nextPrayer.prayer.title(for: language))
                        .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                        .widgetTextFit(minScale: 0.74)
                    Text(PrayerDateFormatter.timeString(for: entry.nextPrayer.date, locale: locale))
                        .font(entry.settings.theme.fontStyle.font(size: metrics.font(20), weight: .bold))
                        .monospacedDigit()
                        .widgetTextFit(minScale: 0.6)

                    Spacer(minLength: 0)

                    Label(language.text(.prayerTimes), systemImage: "clock.fill")
                        .font(entry.settings.theme.fontStyle.font(size: metrics.font(13), weight: .semibold))
                        .padding(.horizontal, metrics.inset(10))
                        .padding(.vertical, metrics.inset(8))
                }
                .frame(maxWidth: .infinity, minHeight: metrics.inset(184), alignment: .leading)
                .padding(metrics.inset(18))
                .background(panelBackground)
                .overlay(RoundedRectangle(cornerRadius: metrics.inset(20), style: .continuous).stroke(panelBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: metrics.inset(20), style: .continuous))

                VStack(alignment: .leading, spacing: metrics.inset(7)) {
                    HStack {
                        Text(language.text(.prayerTimes))
                            .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                        Spacer()
                        Text(language.text(.today))
                            .font(entry.settings.theme.fontStyle.font(size: metrics.font(10), weight: .medium))
                            .opacity(0.72)
                    }

                    ForEach(Array(prayerMoments), id: \.id) { moment in
                        prayerLine(moment: moment, metrics: metrics, compact: false)
                    }
                }
                .frame(width: metrics.inset(150), alignment: .leading)
                .padding(metrics.inset(12))
                .background(panelBackground)
                .overlay(RoundedRectangle(cornerRadius: metrics.inset(20), style: .continuous).stroke(panelBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: metrics.inset(20), style: .continuous))
            }
        }
    }

    private func headerStrip(metrics: WidgetMetrics) -> some View {
        HStack(alignment: .top, spacing: metrics.inset(8)) {
            VStack(alignment: .leading, spacing: metrics.inset(2)) {
                Text(weekdayTitle)
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .opacity(0.82)
                    .widgetTextFit(minScale: 0.82)
                Text(PrayerDateFormatter.gregorianDayMonth(for: entry.date, locale: locale))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .medium))
                    .opacity(0.72)
                    .widgetTextFit(minScale: 0.82)
            }
            Spacer(minLength: metrics.inset(6))
            Text(PrayerDateFormatter.hijriDayMonth(for: entry.date, locale: locale))
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .medium))
                .multilineTextAlignment(.trailing)
                .widgetTextFit(lines: 2, minScale: 0.78)
        }
    }

    private func infoPanel(day: String, title: String, subtitle: String, metrics: WidgetMetrics, centered: Bool = false) -> some View {
        VStack(alignment: centered ? .center : .leading, spacing: metrics.inset(4)) {
            Text(day)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                .widgetTextFit(minScale: 0.62)
            Text(title)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                .widgetTextFit(minScale: 0.78)
            Text(subtitle)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .medium))
                .opacity(0.72)
                .widgetTextFit(minScale: 0.82)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .padding(.horizontal, metrics.inset(11))
        .padding(.vertical, metrics.inset(10))
    }

    private func prayerLine(moment: PrayerMoment, metrics: WidgetMetrics, compact: Bool) -> some View {
        HStack(spacing: metrics.inset(6)) {
            Text(moment.prayer.title(for: language))
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                .widgetTextFit(minScale: 0.78)
            Spacer(minLength: metrics.inset(5))
            Text(PrayerDateFormatter.timeString(for: moment.date, locale: locale))
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                .monospacedDigit()
                .widgetTextFit(minScale: 0.86)
        }
        .padding(.vertical, metrics.inset(compact ? 2 : 3))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(foreground.opacity(0.18))
                .frame(height: 1)
                .offset(y: metrics.inset(4))
        }
    }

    private func proxySideWidth(for metrics: WidgetMetrics) -> CGFloat {
        metrics.inset(124)
    }

    private func widgetContentPadding(metrics: WidgetMetrics) -> CGFloat {
        switch family {
        case .systemSmall:
            return metrics.inset(22)
        case .systemMedium:
            return metrics.inset(16)
        case .systemLarge:
            return metrics.inset(17)
        default:
            return metrics.inset(16)
        }
    }
}

private struct PrayerCountdownSmallView: View {
    let entry: PrayWindowEntry

    private var language: AppLanguage { entry.settings.language }
    private var locale: Locale { language.locale }
    private var background: Color { Color(hex: entry.settings.theme.backgroundHex) }
    private var foreground: Color { Color(hex: entry.settings.theme.textHex) }
    var body: some View {
        GeometryReader { proxy in
            let metrics = WidgetMetrics(
                size: proxy.size,
                multiplier: entry.settings.theme.textScale.multiplier * CGFloat(entry.settings.theme.fontSizeMultiplier)
            )

            VStack(alignment: .leading, spacing: metrics.inset(8)) {
                Text(language.text(.remainingTime))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .opacity(0.78)

                Text(entry.nextPrayer.date, style: .timer)
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(34), weight: .bold))
                    .monospacedDigit()
                    .widgetTextFit(minScale: 0.6)

                Text(language.text(.nextPrayer))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .opacity(0.7)

                Text(entry.nextPrayer.prayer.title(for: language))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .widgetTextFit(minScale: 0.72)

                Text(PrayerDateFormatter.timeString(for: entry.nextPrayer.date, locale: locale))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .monospacedDigit()
                    .widgetTextFit(minScale: 0.72)
                    .opacity(0.92)

                Spacer(minLength: 0)
            }
            .foregroundStyle(foreground)
            .padding(metrics.inset(14))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                WidgetPhotoBackground(
                    settings: entry.settings,
                    tint: background,
                    tintOpacity: 0.8
                )
            )
        }
        .containerBackground(for: .widget) { background }
    }
}

private struct PrayerImageMediumView: View {
    let entry: PrayWindowEntry
    let moments: [PrayerMoment]

    private var language: AppLanguage { entry.settings.language }
    private var locale: Locale { language.locale }
    private var background: Color { Color(hex: entry.settings.theme.backgroundHex) }
    private var foreground: Color { Color(hex: entry.settings.theme.textHex) }
    private var lowerSectionBackground: Color { background.opacity(0.78) }
    private var prayerMoments: [PrayerMoment] {
        moments.filter { $0.prayer != .sunrise }
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = WidgetMetrics(
                size: proxy.size,
                multiplier: entry.settings.theme.textScale.multiplier * CGFloat(entry.settings.theme.fontSizeMultiplier)
            )

            VStack(spacing: 0) {
                if let image = WidgetPhotoSource.uiImage(for: entry.settings) {
                    WidgetPhotoFillView(image: image, focalPoint: entry.settings.customPhotoFocusPoint)
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.5)
                } else {
                    Color.clear
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.5)
                }

                VStack(alignment: .leading, spacing: metrics.inset(6)) {
                    Spacer(minLength: 0)

                    HStack(alignment: .top, spacing: metrics.inset(4)) {
                        ForEach(Array(prayerMoments.prefix(5)), id: \.id) { moment in
                            prayerMomentCell(moment: moment, metrics: metrics)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(lowerSectionBackground)
            }
            .background(background)
        }
        .containerBackground(for: .widget) { background }
    }

    private func prayerMomentCell(moment: PrayerMoment, metrics: WidgetMetrics) -> some View {
        VStack(spacing: metrics.inset(3.5)) {
            Text(moment.prayer.title(for: language))
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                .widgetTextFit(lines: 2, minScale: 0.72)
                .multilineTextAlignment(.center)

            Text(PrayerDateFormatter.timeString(for: moment.date, locale: locale))
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(14), weight: .bold))
                .monospacedDigit()
                .widgetTextFit(lines: 1, minScale: 0.74)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

private struct PrayerDateWisdomMediumView: View {
    let entry: PrayWindowEntry

    private var language: AppLanguage { entry.settings.language }
    private var locale: Locale { language.locale }
    private var background: Color { Color(hex: entry.settings.theme.backgroundHex) }
    private var foreground: Color { Color(hex: entry.settings.theme.textHex) }
    private var panelBackground: Color { background.opacity(0.76) }
    private var panelBorder: Color { foreground.opacity(0.14) }

    var body: some View {
        GeometryReader { proxy in
            let metrics = WidgetMetrics(
                size: proxy.size,
                multiplier: entry.settings.theme.textScale.multiplier * CGFloat(entry.settings.theme.fontSizeMultiplier)
            )

            HStack(spacing: 0) {
                infoPanel(metrics: metrics)
                    .frame(width: proxy.size.width * 0.52)

                imagePanel(metrics: metrics)
                    .frame(maxWidth: .infinity)
            }
            .environment(\.layoutDirection, .leftToRight)
            .background(background)
        }
        .containerBackground(for: .widget) { background }
    }

    private func infoPanel(metrics: WidgetMetrics) -> some View {
        VStack(alignment: .center, spacing: metrics.inset(18)) {
            Text(weekdayTitle)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(24), weight: .bold))
                .widgetTextFit(lines: 1, minScale: 0.6)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(alignment: .top, spacing: metrics.inset(12)) {
                dateColumn(
                    day: gregorianDay,
                    month: gregorianMonth,
                    year: gregorianYear,
                    metrics: metrics,
                    emphasized: false
                )
                dateColumn(
                    day: hijriDay,
                    month: hijriMonth,
                    year: hijriYear,
                    metrics: metrics,
                    emphasized: true
                )
            }
            .environment(\.layoutDirection, .leftToRight)
            .frame(maxWidth: .infinity)

            Spacer(minLength: metrics.inset(8))

            Text(nextPrayerText)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11.4), weight: .semibold))
                .widgetTextFit(lines: 1, minScale: 0.72)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, metrics.inset(14))
        .padding(.vertical, metrics.inset(16))
        .background(panelBackground)
        .overlay(Rectangle().fill(panelBorder).frame(width: 1), alignment: .trailing)
        .environment(\.layoutDirection, language.layoutDirection)
    }

    private func dateColumn(day: String, month: String, year: String, metrics: WidgetMetrics, emphasized: Bool) -> some View {
        VStack(spacing: metrics.inset(3)) {
            Text(day)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(emphasized ? 21 : 19), weight: .bold))
                .widgetTextFit(lines: 1, minScale: 0.7)

            Text(month)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(emphasized ? 14.4 : 13.4), weight: .semibold))
                .widgetTextFit(lines: 2, minScale: 0.72)
                .multilineTextAlignment(.center)

            Text(year)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(12), weight: .medium))
                .widgetTextFit(lines: 1, minScale: 0.78)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func imagePanel(metrics: WidgetMetrics) -> some View {
        ZStack {
            if let image = WidgetPhotoSource.uiImage(for: entry.settings) {
                WidgetPhotoFillView(image: image, focalPoint: entry.settings.customPhotoFocusPoint)
            } else {
                LinearGradient(
                    colors: [background.opacity(0.92), background.opacity(0.68)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .clipped()
    }

    private var weekdayTitle: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter.string(from: entry.date)
    }

    private var gregorianDay: String {
        String(Calendar(identifier: .gregorian).component(.day, from: entry.date))
    }

    private var gregorianMonth: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: entry.date)
    }

    private var gregorianYear: String {
        String(Calendar(identifier: .gregorian).component(.year, from: entry.date))
    }

    private var hijriDay: String {
        String(Calendar(identifier: .islamicUmmAlQura).component(.day, from: entry.date))
    }

    private var hijriMonth: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: entry.date)
    }

    private var hijriYear: String {
        String(Calendar(identifier: .islamicUmmAlQura).component(.year, from: entry.date))
    }

    private var nextPrayerText: String {
        let prayerName = entry.nextPrayer.prayer.title(for: language)
        let prayerTime = PrayerDateFormatter.timeString(for: entry.nextPrayer.date, locale: locale)
        if language.isArabic {
            return "\(prayerName) \(prayerTime)"
        }
        return "\(prayerName) \(prayerTime)"
    }
}

private struct CalendarCityRow: Identifiable {
    let id = UUID()
    let nameArabic: String
    let latitude: Double
    let longitude: Double
}

private struct PrayerCalendarLargeView: View {
    let entry: PrayWindowEntry

    private var background: Color { Color(hex: entry.settings.theme.backgroundHex) }
    private var foreground: Color { Color(hex: entry.settings.theme.textHex) }
    private var rowFillA: Color { .clear }
    private var rowFillB: Color { .clear }

    var body: some View {
        GeometryReader { proxy in
            let metrics = WidgetMetrics(
                size: proxy.size,
                multiplier: 0.94 * CGFloat(entry.settings.theme.fontSizeMultiplier)
            )
            let language = entry.settings.language
            let locale = language.locale

            ZStack {
                WidgetPhotoBackground(
                    settings: entry.settings,
                    tint: background,
                    tintOpacity: 0.78
                )

                VStack(spacing: metrics.inset(10)) {
                    HStack(spacing: 0) {
                        calendarHeadBlock(day: gregorianDay, top: gregorianMonth(locale: locale), middle: gregorianYear, bottom: language.text(.gregorian), metrics: metrics)
                        centerSeal(metrics: metrics)
                        calendarHeadBlock(day: hijriDay, top: hijriMonth(locale: locale), middle: hijriYear, bottom: language.text(.hijri), metrics: metrics)
                    }
                    .frame(height: metrics.inset(74))
                    .clipped()

                    VStack(spacing: metrics.inset(6)) {
                        HStack(spacing: 0) {
                            columnHeader(language.text(.day), width: proxy.size.width * 0.22, metrics: metrics)
                            columnHeader(Prayer.fajr.title(for: language), width: proxy.size.width * 0.156, metrics: metrics)
                            columnHeader(Prayer.dhuhr.title(for: language), width: proxy.size.width * 0.156, metrics: metrics)
                            columnHeader(Prayer.asr.title(for: language), width: proxy.size.width * 0.156, metrics: metrics)
                            columnHeader(Prayer.maghrib.title(for: language), width: proxy.size.width * 0.156, metrics: metrics)
                            columnHeader(Prayer.isha.title(for: language), width: proxy.size.width * 0.156, metrics: metrics)
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(upcomingSchedules.enumerated()), id: \.element.id) { index, item in
                                calendarRow(item: item, index: index, metrics: metrics)
                            }
                        }
                    }

                    Text(dailyWisdom)
                        .font(WidgetFontStyle.cairo.font(size: metrics.font(10.8), weight: .bold))
                        .foregroundStyle(foreground)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .padding(.top, metrics.inset(2))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(4)
            }
        }
        .environment(\.layoutDirection, entry.settings.language.layoutDirection)
        .containerBackground(for: .widget) { background }
    }

    private func calendarHeadBlock(day: String, top: String, middle: String, bottom: String, metrics: WidgetMetrics) -> some View {
        VStack(spacing: 0) {
            Text(day)
                .font(WidgetFontStyle.cairo.font(size: metrics.font(15), weight: .bold))
                .frame(maxWidth: .infinity, minHeight: metrics.inset(16), alignment: .top)
                .padding(.top, metrics.inset(2))

            Spacer(minLength: metrics.inset(1))

            VStack(spacing: metrics.inset(0.5)) {
                Text(top)
                    .font(WidgetFontStyle.cairo.font(size: metrics.font(12.3), weight: .bold))
                Text(middle)
                    .font(WidgetFontStyle.cairo.font(size: metrics.font(10.5), weight: .bold))
                Text(bottom)
                    .font(WidgetFontStyle.cairo.font(size: metrics.font(9.4), weight: .bold))
            }
            .padding(.bottom, metrics.inset(4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(foreground)
    }

    private func centerSeal(metrics: WidgetMetrics) -> some View {
        WeekdaySealImageView(date: entry.date, side: metrics.inset(62))
            .frame(width: metrics.inset(76), height: metrics.inset(76))
            .frame(maxHeight: .infinity, alignment: .center)
    }

    private func columnHeader(_ title: String, width: CGFloat, metrics: WidgetMetrics) -> some View {
        Text(title)
            .font(WidgetFontStyle.cairo.font(size: metrics.font(11.4), weight: .bold))
            .frame(width: width, height: metrics.inset(28))
            .foregroundStyle(foreground)
    }

    private func calendarRow(item: CalendarDaySchedule, index: Int, metrics: WidgetMetrics) -> some View {
        let rowColor = index.isMultiple(of: 2) ? rowFillA : rowFillB
        let formatter = DateFormatter()
        formatter.locale = entry.settings.language.locale
        formatter.dateFormat = "h:mm"
        let totalWidth = metrics.size.width

        return HStack(spacing: 0) {
            tableCell(item.dayLabel, width: totalWidth * 0.22, metrics: metrics, fill: rowColor, bold: true)
            tableCell(timeString(for: item.schedule, prayer: .fajr, formatter: formatter), width: totalWidth * 0.156, metrics: metrics, fill: rowColor)
            tableCell(timeString(for: item.schedule, prayer: .dhuhr, formatter: formatter), width: totalWidth * 0.156, metrics: metrics, fill: rowColor)
            tableCell(timeString(for: item.schedule, prayer: .asr, formatter: formatter), width: totalWidth * 0.156, metrics: metrics, fill: rowColor)
            tableCell(timeString(for: item.schedule, prayer: .maghrib, formatter: formatter), width: totalWidth * 0.156, metrics: metrics, fill: rowColor)
            tableCell(timeString(for: item.schedule, prayer: .isha, formatter: formatter), width: totalWidth * 0.156, metrics: metrics, fill: rowColor)
        }
        .frame(maxWidth: .infinity)
    }

    private func tableCell(_ text: String, width: CGFloat, metrics: WidgetMetrics, fill: Color, bold: Bool = false) -> some View {
        Text(text)
            .font(WidgetFontStyle.cairo.font(size: metrics.font(10.5), weight: .bold))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: width, height: metrics.inset(28))
            .background(fill)
    }

    private var upcomingSchedules: [CalendarDaySchedule] {
        let calendar = Calendar(identifier: .gregorian)
        return (0..<5).compactMap { offset in
            guard let targetDate = calendar.date(byAdding: .day, value: offset, to: entry.date) else {
                return nil
            }

            return CalendarDaySchedule(
                date: targetDate,
                dayLabel: dayLabel(for: targetDate, isToday: offset == 0),
                schedule: PrayerCalculator.schedule(
                    for: targetDate,
                    latitude: entry.settings.latitude,
                    longitude: entry.settings.longitude
                )
            )
        }
    }

    private var dailyWisdom: String {
        let wisdoms = [
            "من أصلح سريرته أصلح الله علانيته.",
            "خير الأعمال ما دام وإن قل.",
            "الصبر مفتاح الفرج.",
            "من سار على الدرب وصل.",
            "أقرب القلوب إلى الله أنفعها للناس.",
            "استعن بالله ولا تعجز.",
            "الكلمة الطيبة صدقة."
        ]
        let dayIndex = Calendar(identifier: .gregorian).ordinality(of: .day, in: .year, for: entry.date) ?? 0
        return wisdoms[dayIndex % wisdoms.count]
    }

    private func dayLabel(for date: Date, isToday: Bool) -> String {
        if isToday {
            return entry.settings.language.text(.today)
        }

        let formatter = DateFormatter()
        formatter.locale = entry.settings.language.locale
        formatter.setLocalizedDateFormatFromTemplate("EEE d")
        return formatter.string(from: date)
    }

    private func timeString(for schedule: PrayerDaySchedule, prayer: Prayer, formatter: DateFormatter) -> String {
        guard let moment = schedule.moments.first(where: { $0.prayer == prayer }) else {
            return "--:--"
        }
        return formatter.string(from: moment.date)
    }

    private var gregorianDay: String {
        String(Calendar(identifier: .gregorian).component(.day, from: entry.date))
    }

    private var gregorianYear: String {
        String(Calendar(identifier: .gregorian).component(.year, from: entry.date))
    }

    private var hijriDay: String {
        String(Calendar(identifier: .islamicUmmAlQura).component(.day, from: entry.date))
    }

    private var hijriYear: String {
        String(Calendar(identifier: .islamicUmmAlQura).component(.year, from: entry.date))
    }

    private func gregorianMonth(locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: entry.date)
    }

    private func hijriMonth(locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: entry.date)
    }

}

private struct CalendarDaySchedule: Identifiable {
    let date: Date
    let dayLabel: String
    let schedule: PrayerDaySchedule

    var id: TimeInterval { date.timeIntervalSince1970 }
}

struct PrayWindowWidget: Widget {
    let kind = "PrayWindowWidget"

    init() {
        FontRegistrar.registerEmbeddedFonts()
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayWindowTimelineProvider()) { entry in
            PrayWindowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("مواقيت الصلاة")
        .description("يعرض الصلاة القادمة مع التاريخ الهجري والميلادي لليوم.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct PrayWindowCalendarWidget: Widget {
    let kind = "PrayWindowCalendarWidget"

    init() {
        FontRegistrar.registerEmbeddedFonts()
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayWindowTimelineProvider()) { entry in
            PrayerCalendarLargeView(entry: entry)
        }
        .configurationDisplayName("تقويم الصلاة")
        .description("جدول مواقيت الصلاة لخمسة أيام بالتقويم الهجري والميلادي والشمسي.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}

struct PrayWindowCountdownWidget: Widget {
    let kind = "PrayWindowCountdownWidget"

    init() {
        FontRegistrar.registerEmbeddedFonts()
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayWindowTimelineProvider()) { entry in
            PrayWindowCountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("العدّ التنازلي للصلاة")
        .description("يعرض الوقت المتبقي للصلاة القادمة في ودجت صغير.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct PrayWindowImagePrayerWidget: Widget {
    let kind = "PrayWindowImagePrayerWidget"

    init() {
        FontRegistrar.registerEmbeddedFonts()
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayWindowTimelineProvider()) { entry in
            PrayWindowImagePrayerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("مواقيت الصلاة مع صورة الخلفية")
        .description("يعرض صورة لمكة المكرمة فوق مواقيت الصلاة اليومية في ودجت متوسط.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct PrayWindowDateWisdomWidget: Widget {
    let kind = "PrayWindowDateWisdomWidget"

    init() {
        FontRegistrar.registerEmbeddedFonts()
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayWindowTimelineProvider()) { entry in
            PrayWindowDateWisdomWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("التاريخ وحكمة اليوم")
        .description("يعرض صورة على اليمين مع التاريخ الميلادي والهجري وحكمة اليوم على اليسار.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct PrayWindowLockScreenCountdownWidget: Widget {
    let kind = "PrayWindowLockScreenCountdownWidget"

    init() {
        FontRegistrar.registerEmbeddedFonts()
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayWindowTimelineProvider()) { entry in
            PrayWindowLockScreenCountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("عدّاد الصلاة لقفل الشاشة")
        .description("يعرض الوقت المتبقي للصلاة القادمة على شاشة القفل.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct PrayWindowLockScreenPrayerWidget: Widget {
    let kind = "PrayWindowLockScreenPrayerWidget"

    init() {
        FontRegistrar.registerEmbeddedFonts()
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayWindowTimelineProvider()) { entry in
            PrayWindowLockScreenPrayerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("الصلاة القادمة لقفل الشاشة")
        .description("يعرض اسم ووقت الصلاة القادمة على شاشة القفل.")
        .supportedFamilies([.accessoryRectangular])
    }
}

private extension View {
    func widgetTextFit(lines: Int = 1, minScale: CGFloat = 0.74) -> some View {
        self
            .lineLimit(lines)
            .minimumScaleFactor(minScale)
            .allowsTightening(true)
    }
}

@main
struct PrayWindowWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayWindowWidget()
        PrayWindowCalendarWidget()
        PrayWindowCountdownWidget()
        PrayWindowImagePrayerWidget()
        PrayWindowDateWisdomWidget()
        PrayWindowLockScreenCountdownWidget()
        PrayWindowLockScreenPrayerWidget()
    }
}
