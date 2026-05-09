//
//  ContentView.swift
//  PrayWindow
//
//  Created by Codex on 23/04/2026.
//

import CoreLocation
import PhotosUI
import SwiftUI
import UIKit
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var locationManager = LocationManager()
    @State private var settings = WidgetSettingsStore.shared.load()
    @State private var selectedTab = 0
    @State private var cityInput = WidgetSettingsStore.shared.load().city
    @State private var backgroundColor = Color(hex: WidgetTheme.default.backgroundHex)
    @State private var textColor = Color(hex: WidgetTheme.default.textHex)
    @State private var alertBarColor = Color(hex: PrayerSettings.default.prePrayerAlertBarColorHex)
    @State private var savedMessage = ""
    @State private var isSavingCity = false
    @State private var cityLookupError: String?
    @State private var citySaveTask: Task<Void, Never>?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var customPhotoPreviewImage = WidgetSettingsStore.shared.customPhotoImage(revision: WidgetSettingsStore.shared.load().customPhotoRevision)

    private let suggestedCities: [(name: String, latitude: Double, longitude: Double)] = [
        ("Makkah", 21.3891, 39.8579),
        ("Madinah", 24.5247, 39.5692),
        ("Riyadh", 24.7136, 46.6753),
        ("Jeddah", 21.5433, 39.1728),
        ("Dammam", 26.4207, 50.0888),
        ("Dubai", 25.2048, 55.2708),
        ("Cairo", 30.0444, 31.2357),
    ]

    private var language: AppLanguage {
        settings.language
    }

    private var appPrimaryText: Color {
        Color(hex: "#183A2A")
    }

    private var appSecondaryText: Color {
        Color(hex: "#42554B")
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    settingsTab
                        .padding(20)
                }
                .scrollIndicators(.hidden)
                .contentMargins(.bottom, 28, for: .scrollContent)
                .background(appBackground.ignoresSafeArea())
                .navigationTitle(language.isArabic ? "الإعدادات" : "Settings")
                .toolbarTitleDisplayMode(.inline)
                .toolbarBackground(Color(hex: "#F8F4EA"), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
            }
            .tabItem {
                Label(language.isArabic ? "الإعدادات" : "Settings", systemImage: "slider.horizontal.3")
            }
            .tag(0)

            NavigationStack {
                ScrollView {
                    aboutTab
                        .padding(20)
                }
                .scrollIndicators(.hidden)
                .contentMargins(.bottom, 28, for: .scrollContent)
                .background(appBackground.ignoresSafeArea())
                .navigationTitle(language.isArabic ? "عن التطبيق" : "About")
                .toolbarTitleDisplayMode(.inline)
                .toolbarBackground(Color(hex: "#F8F4EA"), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
            }
            .tabItem {
                Label(language.isArabic ? "عن التطبيق" : "About", systemImage: "info.circle.fill")
            }
            .tag(1)
        }
        .tint(Color(hex: "#183A2A"))
        .toolbarBackground(Color(hex: "#F8F4EA"), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
        .environment(\.layoutDirection, language.layoutDirection)
        .onAppear {
            syncSelectionsFromSettings()
            refreshLocationOnLaunchIfNeeded()
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            refreshLocationOnLaunchIfNeeded()
        }
        .onDisappear {
            citySaveTask?.cancel()
        }
    }

    private var appBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#F5EFE4"), Color(hex: "#E6EFE8"), Color(hex: "#DEE7F7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 280, height: 280)
                .blur(radius: 12)
                .offset(x: -120, y: -220)

            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(Color(hex: "#E2D4B7").opacity(0.2))
                .frame(width: 320, height: 220)
                .rotationEffect(.degrees(20))
                .offset(x: 120, y: 280)
        }
    }

    private var settingsTab: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !savedMessage.isEmpty {
                statusBanner(savedMessage)
            }
            settingsHero
            appearanceSection
            locationSection
            languageIconSection
            previewGallerySection
        }
    }

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text(language.text(.appTitle))
                    .font(settings.theme.fontStyle.font(size: 30, weight: .bold))
                    .foregroundStyle(Color(hex: "#183A2A"))

                Text(language.isArabic ? "تطبيق مخصص لمعاينة وضبط ودجت الصلاة والتقويم بشكل عربي واضح وسهل." : "An app for previewing and customizing the prayer and calendar widget with a clear Arabic-first experience.")
                    .font(settings.theme.fontStyle.font(size: 16, weight: .regular))
                    .foregroundStyle(Color(hex: "#42554B"))

                Text(language.isArabic ? "الإصدار 1.0" : "Version 1.0")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(hex: "#42554B"))
                    .padding(.top, 4)
            }
            .padding(22)
            .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 30, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                Label(language.isArabic ? "للمراسلة" : "Contact", systemImage: "envelope.fill")
                    .font(settings.theme.fontStyle.font(size: 19, weight: .bold))
                    .foregroundStyle(Color(hex: "#183A2A"))

                Link("praywidget@nahedh.com", destination: URL(string: "mailto:praywidget@nahedh.com")!)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1E6F5C"))

                Text(language.isArabic ? "راسلنا لأي اقتراحات أو ملاحظات تخص الودجت والتطبيق." : "Reach out for feedback, ideas, or support related to the widget and app.")
                    .font(settings.theme.fontStyle.font(size: 15, weight: .regular))
                    .foregroundStyle(Color(hex: "#42554B"))
            }
            .padding(22)
            .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 30, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                Label(language.isArabic ? "روابط مهمة" : "Useful Links", systemImage: "link")
                    .font(settings.theme.fontStyle.font(size: 19, weight: .bold))
                    .foregroundStyle(Color(hex: "#183A2A"))

                aboutLinkRow(
                    icon: "lock.shield.fill",
                    title: language.isArabic ? "سياسة الخصوصية" : "Privacy Policy",
                    url: "https://almatrafi-ali.github.io/PrayWidget/privacy.html"
                )

                aboutLinkRow(
                    icon: "questionmark.circle.fill",
                    title: language.isArabic ? "صفحة الدعم" : "Support",
                    url: "https://almatrafi-ali.github.io/PrayWidget/support.html"
                )
            }
            .padding(22)
            .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
    }

    private func aboutLinkRow(icon: String, title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "#1E6F5C"))
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#183A2A"))
                Spacer()
                Image(systemName: language.isArabic ? "chevron.left" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#42554B").opacity(0.6))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.7))
            )
        }
    }

    private var settingsHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.isArabic ? "لوحة إعدادات الودجت" : "Widget Control Center")
                .font(settings.theme.fontStyle.font(size: 32, weight: .bold))
                .foregroundStyle(appPrimaryText)

            Text(language.isArabic ? "رتّب المظهر، حدّد الموقع، واختر الصورة المناسبة من أقسام واضحة ومتوازنة قبل نشر الودجت للواجهة الرئيسية." : "Tune the look, location, and imagery through clearer sections before publishing the widget to the Home Screen.")
                .font(settings.theme.fontStyle.font(size: 15, weight: .regular))
                .foregroundStyle(appSecondaryText)

            HStack(spacing: 10) {
                heroPill(icon: "paintpalette.fill", title: language.text(.appearance))
                heroPill(icon: "location.fill", title: language.text(.location))
                heroPill(icon: "sparkles.rectangle.stack.fill", title: language.isArabic ? "المعاينة" : "Preview")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.65), lineWidth: 1)
                )
        )
    }

    private var languageIconSection: some View {
        settingsSectionCard(
            title: language.text(.chooseLanguage),
            subtitle: language.isArabic ? "اختر لغة التطبيق والودجت من أزرار موحّدة وواضحة." : "Choose the app and widget language using balanced, clear controls."
        ) {
            HStack(spacing: 12) {
                languageIconButton(for: .arabic, icon: "character.book.closed.fill", title: "ع")
                languageIconButton(for: .english, icon: "textformat.abc", title: "EN")
            }
        }
    }

    private func languageIconButton(for appLanguage: AppLanguage, icon: String, title: String) -> some View {
        let selected = settings.language == appLanguage

        return Button {
            settings.language = appLanguage
            saveSettings(message: language.text(.styleSaved))
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(selected ? Color.white : Color(hex: "#183A2A"))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? Color(hex: "#183A2A") : Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "#183A2A").opacity(selected ? 0 : 0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var locationSection: some View {
        settingsSectionCard(
            title: language.text(.location),
            subtitle: language.isArabic ? "حدّد المدينة يدويًا أو استخدم موقعك الحالي، مع وصول أسرع للمدن الشائعة." : "Set the city manually or use your current location, with quicker access to common cities."
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text(language.isArabic ? "المدينة الحالية" : "Current City")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(appSecondaryText)

                Label(settings.city.isEmpty ? (language.isArabic ? "غير محددة" : "Not set") : settings.city, systemImage: "mappin.and.ellipse")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(appPrimaryText)
            }
            .padding(14)
            .background(inputBackground)

            TextField(language.text(.cityName), text: $cityInput)
                .foregroundStyle(appPrimaryText)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit {
                    Task {
                        await saveManualCity()
                    }
                }
                .onChange(of: cityInput) {
                    scheduleCityAutoSave()
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(inputBackground)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestedCities, id: \.name) { city in
                        Button(city.name) {
                            citySaveTask?.cancel()
                            settings.city = city.name
                            settings.latitude = city.latitude
                            settings.longitude = city.longitude
                            settings.usesCurrentLocation = false
                            cityInput = city.name
                            cityLookupError = nil
                            saveSettings(message: String(format: language.text(.savedForWidget), city.name))
                        }
                        .buttonStyle(CapsuleTagButtonStyle())
                    }
                }
            }

            Button {
                citySaveTask?.cancel()
                locationManager.requestCurrentLocation { coordinate, city in
                    settings.city = city
                    settings.latitude = coordinate.latitude
                    settings.longitude = coordinate.longitude
                    settings.usesCurrentLocation = true
                    cityInput = city
                    cityLookupError = nil
                    saveSettings(message: language.text(.currentLocationSaved))
                }
            } label: {
                HStack {
                    if locationManager.isResolvingLocation {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "location.circle.fill")
                    }
                    Text(locationManager.isResolvingLocation ? language.text(.detectingLocation) : language.text(.useCurrentLocation))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(FilledActionButtonStyle())
            .disabled(locationManager.isResolvingLocation)

            if let errorMessage = locationManager.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if let cityLookupError {
                Text(cityLookupError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(language.text(.calculationMethod))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(settings.calculationMethod.title(for: language))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(appSecondaryText)
                }

                Picker(language.text(.prayerMethod), selection: $settings.calculationMethod) {
                    ForEach(PrayerCalculationMethod.allCases) { method in
                        Text(method.title(for: language))
                            .tag(method)
                    }
                }
                .pickerStyle(.menu)
                .tint(appPrimaryText)
                .padding(14)
                .background(inputBackground)
                .onChange(of: settings.calculationMethod) {
                    saveSettings(message: language.text(.styleSaved))
                }
            }
        }
    }

    private var appearanceSection: some View {
        settingsSectionCard(
            title: language.text(.appearance),
            subtitle: language.isArabic ? "اضبط ألوان الخلفية والنص وحجم الخط والخط المستخدم بصياغة متناسقة." : "Adjust background, text color, font size, and typeface through a more consistent visual setup."
        ) {
            colorPickerRow(
                title: language.text(.background),
                color: $backgroundColor
            )

            colorPickerRow(
                title: language.text(.text),
                color: $textColor
            )

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $settings.showsPrePrayerAlertBar) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text(.prePrayerAlertBar))
                            .font(.subheadline.weight(.semibold))
                        Text(language.text(.prePrayerAlertBarHint))
                            .font(.footnote)
                            .foregroundStyle(appSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(Color(hex: "#183A2A"))
                .onChange(of: settings.showsPrePrayerAlertBar) {
                    saveSettings(message: language.text(.styleSaved))
                }

                if settings.showsPrePrayerAlertBar {
                    colorPickerRow(
                        title: language.text(.prePrayerBarColor),
                        color: $alertBarColor
                    )
                }
            }
            .padding(14)
            .background(inputBackground)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(language.text(.fontSize))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(String(format: "%.1f", settings.theme.fontSizeMultiplier))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(appSecondaryText)
                }

                Slider(value: $settings.theme.fontSizeMultiplier, in: 0.7...1.6, step: 0.05)
                    .tint(Color(hex: "#183A2A"))
                    .onChange(of: settings.theme.fontSizeMultiplier) {
                        saveThemeSettings()
                    }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(language.text(.font))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(settings.theme.fontStyle.title)
                        .font(settings.theme.fontStyle.font(size: 14, weight: .semibold))
                        .foregroundStyle(appSecondaryText)
                }

                Picker(language.text(.font), selection: $settings.theme.fontStyle) {
                    ForEach(WidgetFontStyle.allCases) { style in
                        Text(style.title)
                            .font(style.font(size: 15, weight: .semibold))
                            .tag(style)
                    }
                }
                .pickerStyle(.menu)
                .tint(appPrimaryText)
                .onChange(of: settings.theme.fontStyle) {
                    saveThemeSettings()
                }
            }

            widgetImageSection
        }
        .onChange(of: backgroundColor) {
            saveThemeSettings()
        }
        .onChange(of: textColor) {
            saveThemeSettings()
        }
        .onChange(of: alertBarColor) {
            settings.prePrayerAlertBarColorHex = alertBarColor.hexString
            saveSettings(message: language.text(.styleSaved))
        }
        .onChange(of: selectedPhotoItem) {
            Task {
                await saveSelectedPhoto()
            }
        }
    }

    private var widgetImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(language.text(.widgetImage))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(settings.photoChoice.title(for: language))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(appSecondaryText)
            }

            Text(language.text(.bundledImages))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(appSecondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(imageChoicesForDisplay) { choice in
                        photoChoiceCard(for: choice)
                    }
                }
                .padding(.vertical, 2)
            }

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                preferredItemEncoding: .compatible,
                photoLibrary: .shared()
            ) {
                Text(language.text(.uploadImage))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(FilledActionButtonStyle())

            if let activeWidgetPhotoImage {
                Text(language.text(.imageFocusPoint))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(appSecondaryText)

                WidgetPhotoFocusEditor(
                    image: activeWidgetPhotoImage,
                    focusPoint: settings.customPhotoFocusPoint,
                    tintColor: Color(hex: settings.theme.backgroundHex),
                    onPointChanged: { point in
                        settings.customPhotoFocusX = point.x
                        settings.customPhotoFocusY = point.y
                    },
                    onPointCommitted: { point in
                        settings.customPhotoFocusX = point.x
                        settings.customPhotoFocusY = point.y
                        saveSettings(message: language.text(.styleSaved))
                    }
                )
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Text(language.text(.imageFocusHint))
                    .font(.footnote)
                    .foregroundStyle(appSecondaryText)
            }

            Button(language.text(.removeImage)) {
                removeSelectedPhoto()
            }
            .buttonStyle(OutlineActionButtonStyle())
            .disabled(settings.photoChoice == .none)
        }
    }

    private var imageChoicesForDisplay: [WidgetPhotoChoice] {
        var choices: [WidgetPhotoChoice] = [.none, .makkah, .madinah, .alquds]
        if customPhotoPreviewImage != nil || !settings.customPhotoRevision.isEmpty {
            choices.append(.custom)
        }
        return choices
    }

    private func photoChoiceCard(for choice: WidgetPhotoChoice) -> some View {
        let isSelected = settings.photoChoice == choice

        return Button {
            selectPhotoChoice(choice)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.92))

                    if let image = previewImage(for: choice) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "rectangle.fill")
                                .font(.system(size: 28, weight: .semibold))
                            Text(language.text(.noImage))
                                .font(WidgetFontStyle.rubik.font(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color(hex: "#42554B"))
                    }
                }
                .frame(width: 132, height: 94)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? Color(hex: "#183A2A") : Color.black.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                )

                Text(choice.title(for: language))
                    .font(WidgetFontStyle.rubik.font(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "#183A2A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 132)
        }
        .buttonStyle(.plain)
    }

    private var previewGallerySection: some View {
        settingsSectionCard(
            title: language.isArabic ? "معاينة جميع المقاسات" : "All Widget Sizes",
            subtitle: language.isArabic ? "راجع شكل كل ويدجت قبل النشر، مع فصل بصري واضح لكل مقاس." : "Review each widget before release with a cleaner visual separation for every size."
        ) {
            widgetPreviewStack
        }
    }

    private var widgetPreviewStack: some View {
        VStack(alignment: .leading, spacing: 18) {
            previewGroup(title: language.isArabic ? "التقويم الكبير" : "Calendar Large") {
                CalendarWidgetPreviewCard(settings: previewSettings)
                    .frame(height: 390)
            }

            previewGroup(title: language.isArabic ? "الكبير" : "Large") {
                WidgetPreviewCard(
                    settings: previewSettings,
                    nextPrayer: previewNextPrayer,
                    family: .systemLarge
                )
                .frame(height: 340)
            }

            previewGroup(title: language.isArabic ? "المتوسط" : "Medium") {
                WidgetPreviewCard(
                    settings: previewSettings,
                    nextPrayer: previewNextPrayer,
                    family: .systemMedium
                )
                .frame(height: 170)
            }

            previewGroup(title: language.isArabic ? "المتوسط - الصورة" : "Medium - Image") {
                ImagePrayerWidgetPreviewCard(
                    settings: previewSettings,
                    nextPrayer: previewNextPrayer
                )
                .frame(height: 170)
            }

            previewGroup(title: language.isArabic ? "المتوسط - التاريخ والحكمة" : "Medium - Date & Wisdom") {
                DateWisdomWidgetPreviewCard(settings: previewSettings)
                    .frame(height: 170)
            }

            HStack(alignment: .top, spacing: 14) {
                previewGroup(title: language.isArabic ? "الصغير" : "Small") {
                    WidgetPreviewCard(
                        settings: previewSettings,
                        nextPrayer: previewNextPrayer,
                        family: .systemSmall
                    )
                    .aspectRatio(1, contentMode: .fit)
                }
                .frame(maxWidth: .infinity)

                previewGroup(title: language.isArabic ? "الصغير - الوقت المتبقي" : "Small - Time Remaining") {
                    CountdownWidgetPreviewCard(
                        settings: previewSettings,
                        nextPrayer: previewNextPrayer
                    )
                    .aspectRatio(1, contentMode: .fit)
                }
                .frame(maxWidth: .infinity)
            }

            previewGroup(title: language.isArabic ? "قفل الشاشة" : "Lock Screen") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(language.isArabic ? "معاينة تقريبية لويدجت قفل الشاشة" : "Approximate Lock Screen widget preview")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(appSecondaryText)

                    HStack(alignment: .center, spacing: 14) {
                        LockScreenCountdownPreviewCard(
                            settings: previewSettings,
                            nextPrayer: previewNextPrayer
                        )

                        LockScreenPrayerPreviewCard(
                            settings: previewSettings,
                            nextPrayer: previewNextPrayer
                        )
                    }
                }
            }
        }
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }

    private func statusBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "#1E6F5C"))
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(appPrimaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.84))
        )
    }

    private func heroPill(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(appPrimaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.88), in: Capsule())
    }

    private func settingsSectionCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(settings.theme.fontStyle.font(size: 20, weight: .bold))
                    .foregroundStyle(appPrimaryText)

                Text(subtitle)
                    .font(settings.theme.fontStyle.font(size: 13.5, weight: .regular))
                    .foregroundStyle(appSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
        .foregroundStyle(appPrimaryText)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )
        )
    }

    private func previewGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(appPrimaryText)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
        )
    }

    private func colorPickerRow(title: String, color: Binding<Color>) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.wrappedValue)
                .frame(width: 50, height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(color.wrappedValue.hexString)
                    .font(.footnote.monospaced())
                    .foregroundStyle(appSecondaryText)
            }

            Spacer()

            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 44, height: 44)
        }
        .foregroundStyle(appPrimaryText)
        .padding(14)
        .background(inputBackground)
    }

    private var previewSettings: PrayerSettings {
        var preview = settings
        preview.city = cityInput.isEmpty ? settings.city : cityInput
        preview.theme.backgroundHex = backgroundColor.hexString
        preview.theme.textHex = textColor.hexString
        preview.prePrayerAlertBarColorHex = alertBarColor.hexString
        return preview
    }

    private var activeWidgetPhotoImage: UIImage? {
        previewImage(for: settings.photoChoice)
    }

    private func previewImage(for choice: WidgetPhotoChoice) -> UIImage? {
        switch choice {
        case .none:
            return nil
        case .custom:
            return customPhotoPreviewImage ?? WidgetSettingsStore.shared.customPhotoImage(revision: settings.customPhotoRevision)
        case .makkah, .madinah, .alquds:
            guard let assetName = choice.assetName else { return nil }
            return UIImage(named: assetName)
        }
    }

    private var previewNextPrayer: PrayerMoment {
        PrayerCalculator.nextPrayer(
            from: Date(),
            latitude: previewSettings.latitude,
            longitude: previewSettings.longitude,
            method: previewSettings.calculationMethod
        )
    }

    private func syncSelectionsFromSettings() {
        backgroundColor = Color(hex: settings.theme.backgroundHex)
        textColor = Color(hex: settings.theme.textHex)
        alertBarColor = Color(hex: settings.prePrayerAlertBarColorHex)
        customPhotoPreviewImage = WidgetSettingsStore.shared.customPhotoImage(revision: settings.customPhotoRevision)
    }

    private func saveSettings(message: String) {
        WidgetSettingsStore.shared.save(settings)
        savedMessage = message
        syncSelectionsFromSettings()
    }

    private func refreshLocationOnLaunchIfNeeded() {
        guard !locationManager.isResolvingLocation else { return }

        citySaveTask?.cancel()
        locationManager.requestCurrentLocation { coordinate, city in
            settings.city = city
            settings.latitude = coordinate.latitude
            settings.longitude = coordinate.longitude
            settings.usesCurrentLocation = true
            cityInput = city
            cityLookupError = nil
            saveSettings(message: language.text(.currentLocationSaved))
        }
    }

    private func saveThemeSettings() {
        settings.theme.backgroundHex = backgroundColor.hexString
        settings.theme.textHex = textColor.hexString
        settings.prePrayerAlertBarColorHex = alertBarColor.hexString
        saveSettings(message: language.text(.styleSaved))
    }

    @MainActor
    private func saveSelectedPhoto() async {
        guard let selectedPhotoItem else { return }
        defer { self.selectedPhotoItem = nil }

        guard
            let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
            let revision = WidgetSettingsStore.shared.saveCustomPhotoData(data, replacing: settings.customPhotoRevision)
        else {
            return
        }

        settings.customPhotoRevision = revision
        customPhotoPreviewImage = WidgetSettingsStore.shared.customPhotoImage(revision: revision)
        settings.photoChoice = .custom
        settings.customPhotoFocusX = 0.5
        settings.customPhotoFocusY = 0.5
        saveSettings(message: language.text(.customImageSaved))
    }

    private func selectPhotoChoice(_ choice: WidgetPhotoChoice) {
        settings.photoChoice = choice
        saveSettings(message: language.text(.styleSaved))
    }

    private func removeSelectedPhoto() {
        if settings.photoChoice == .custom {
            WidgetSettingsStore.shared.removeCustomPhoto(revision: settings.customPhotoRevision)
            customPhotoPreviewImage = nil
            settings.customPhotoRevision = ""
        }

        settings.photoChoice = .none
        settings.customPhotoFocusX = 0.5
        settings.customPhotoFocusY = 0.5
        saveSettings(message: language.text(.customImageRemoved))
    }

    private func scheduleCityAutoSave() {
        citySaveTask?.cancel()

        let trimmedCity = cityInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCity.isEmpty, trimmedCity.caseInsensitiveCompare(settings.city) != .orderedSame else {
            return
        }

        citySaveTask = Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            await saveManualCity()
        }
    }

    @MainActor
    private func saveManualCity() async {
        let trimmedCity = cityInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCity.isEmpty else {
            cityLookupError = language.text(.enterCityFirst)
            return
        }

        guard trimmedCity.caseInsensitiveCompare(settings.city) != .orderedSame else {
            cityLookupError = nil
            settings.city = trimmedCity
            return
        }

        cityLookupError = nil
        isSavingCity = true

        defer {
            isSavingCity = false
        }

        if let city = suggestedCities.first(where: { $0.name.caseInsensitiveCompare(trimmedCity) == .orderedSame }) {
            settings.city = city.name
            settings.latitude = city.latitude
            settings.longitude = city.longitude
            settings.usesCurrentLocation = false
            cityInput = city.name
            saveSettings(message: String(format: language.text(.savedForWidget), city.name))
            return
        }

        do {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.geocodeAddressString(trimmedCity)

            guard let location = placemarks.first?.location else {
                cityLookupError = language.text(.cityLookupFailed)
                return
            }

            settings.city = trimmedCity
            settings.latitude = location.coordinate.latitude
            settings.longitude = location.coordinate.longitude
            settings.usesCurrentLocation = false
            cityInput = trimmedCity
            saveSettings(message: String(format: language.text(.savedForWidget), trimmedCity))
        } catch {
            cityLookupError = error.localizedDescription
        }
    }
}

private struct WidgetPreviewCard: View {
    let settings: PrayerSettings
    let nextPrayer: PrayerMoment
    let family: WidgetFamily

    var body: some View {
        let schedule = PrayerCalculator.schedule(
            for: Date(),
            latitude: settings.latitude,
            longitude: settings.longitude,
            method: settings.calculationMethod
        )
        PreviewPrayerWidgetChrome(entry: .init(date: Date(), settings: settings, nextPrayer: nextPrayer), family: family, moments: schedule.moments)
            .environment(\.layoutDirection, settings.language.layoutDirection)
    }
}

private struct CalendarWidgetPreviewCard: View {
    let settings: PrayerSettings

    var body: some View {
        PreviewCalendarWidgetChrome(entry: .init(
            date: Date(),
            settings: settings,
            nextPrayer: PrayerCalculator.nextPrayer(
                from: Date(),
                latitude: settings.latitude,
                longitude: settings.longitude,
                method: settings.calculationMethod
            )
        ))
    }
}

private struct CountdownWidgetPreviewCard: View {
    let settings: PrayerSettings
    let nextPrayer: PrayerMoment

    var body: some View {
        PreviewCountdownWidgetChrome(entry: .init(date: Date(), settings: settings, nextPrayer: nextPrayer))
            .environment(\.layoutDirection, settings.language.layoutDirection)
    }
}

private struct ImagePrayerWidgetPreviewCard: View {
    let settings: PrayerSettings
    let nextPrayer: PrayerMoment

    var body: some View {
        let schedule = PrayerCalculator.schedule(
            for: Date(),
            latitude: settings.latitude,
            longitude: settings.longitude,
            method: settings.calculationMethod
        )
        PreviewImagePrayerMediumWidgetChrome(
            entry: .init(date: Date(), settings: settings, nextPrayer: nextPrayer),
            moments: schedule.moments
        )
        .environment(\.layoutDirection, settings.language.layoutDirection)
    }
}

private struct DateWisdomWidgetPreviewCard: View {
    let settings: PrayerSettings

    var body: some View {
        PreviewDateWisdomMediumWidgetChrome(
            entry: .init(
                date: Date(),
                settings: settings,
                nextPrayer: PrayerCalculator.nextPrayer(
                    from: Date(),
                    latitude: settings.latitude,
                    longitude: settings.longitude,
                    method: settings.calculationMethod
                )
            )
        )
        .environment(\.layoutDirection, settings.language.layoutDirection)
    }
}

private struct LockScreenCountdownPreviewCard: View {
    let settings: PrayerSettings
    let nextPrayer: PrayerMoment

    var body: some View {
        VStack(spacing: 10) {
            Text(settings.language.isArabic ? "الدائرية" : "Circular")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))

            PreviewLockScreenCountdownCircularView(
                entry: .init(date: Date(), settings: settings, nextPrayer: nextPrayer)
            )
            .frame(width: 88, height: 88)
        }
        .frame(maxWidth: .infinity, minHeight: 156)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#2D3E63"), Color(hex: "#243552")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

private struct LockScreenPrayerPreviewCard: View {
    let settings: PrayerSettings
    let nextPrayer: PrayerMoment

    var body: some View {
        VStack(spacing: 10) {
            Text(settings.language.isArabic ? "المستطيلة" : "Rectangular")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))

            PreviewLockScreenPrayerRectangularView(
                entry: .init(date: Date(), settings: settings, nextPrayer: nextPrayer)
            )
            .frame(maxWidth: 230, minHeight: 88, maxHeight: 88)
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 156)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#2D3E63"), Color(hex: "#243552")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

private struct PrayWindowPreviewEntry {
    let date: Date
    let settings: PrayerSettings
    let nextPrayer: PrayerMoment
}

private struct PreviewMetrics {
    let size: CGSize
    let multiplier: CGFloat

    private var scaleBase: CGFloat {
        max(0.76, min(1.28, min(size.width / 329, size.height / 345)))
    }

    func font(_ base: CGFloat) -> CGFloat { base * scaleBase * multiplier }
    func inset(_ base: CGFloat) -> CGFloat { base * scaleBase }
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

private struct StarSectionItem: Identifiable {
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

private struct StarSectionRowView: View {
    let items: [StarSectionItem]
    let metrics: PreviewMetrics
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

private enum PreviewWidgetPhotoSource {
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

private struct WidgetPhotoFocusEditor: View {
    let image: UIImage
    let focusPoint: CGPoint
    let tintColor: Color
    let onPointChanged: (CGPoint) -> Void
    let onPointCommitted: (CGPoint) -> Void

    var body: some View {
        GeometryReader { proxy in
            let markerSize = min(proxy.size.width, proxy.size.height) * 0.12
            let clampedPoint = CGPoint(
                x: min(max(focusPoint.x, 0), 1),
                y: min(max(focusPoint.y, 0), 1)
            )

            ZStack {
                WidgetPhotoFillView(image: image, focalPoint: focusPoint)

                tintColor.opacity(0.24)

                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .background(Circle().fill(Color.white.opacity(0.18)))
                    .frame(width: markerSize, height: markerSize)
                    .position(
                        x: clampedPoint.x * proxy.size.width,
                        y: clampedPoint.y * proxy.size.height
                    )

                Image(systemName: "viewfinder")
                    .font(.system(size: markerSize * 0.42, weight: .bold))
                    .foregroundStyle(.white)
                    .position(
                        x: clampedPoint.x * proxy.size.width,
                        y: clampedPoint.y * proxy.size.height
                    )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onPointChanged(normalizedPoint(for: value.location, in: proxy.size))
                    }
                    .onEnded { value in
                        onPointCommitted(normalizedPoint(for: value.location, in: proxy.size))
                    }
            )
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func normalizedPoint(for location: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(location.x / max(size.width, 1), 0), 1),
            y: min(max(location.y / max(size.height, 1), 0), 1)
        )
    }
}

private struct PreviewWidgetPhotoBackground: View {
    let settings: PrayerSettings
    let tint: Color
    let tintOpacity: Double

    var body: some View {
        if let image = PreviewWidgetPhotoSource.uiImage(for: settings) {
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

private struct PreviewPrayerAlertBarState {
    let progress: Double
    let color: Color
    let fillAlignment: Alignment
}

private struct PreviewPrayerAlertBarOverlay: View {
    let state: PreviewPrayerAlertBarState

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width * state.progress, 0)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .overlay(alignment: state.fillAlignment) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [state.color.opacity(0.95), state.color.opacity(0.55)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width)
                }
        }
        .frame(height: 6)
    }
}

private extension View {
    func withPreviewPrayerAlertBar(for entry: PrayWindowPreviewEntry) -> some View {
        let progress = PrayerCalculator.alertProgress(
            at: entry.date,
            for: entry.nextPrayer,
            isEnabled: entry.settings.showsPrePrayerAlertBar
        )

        let state = progress.map {
            PreviewPrayerAlertBarState(
                progress: $0,
                color: Color(hex: entry.settings.prePrayerAlertBarColorHex),
                fillAlignment: entry.settings.language.isArabic ? .trailing : .leading
            )
        }

        return overlay(alignment: .top) {
            if let state {
                PreviewPrayerAlertBarOverlay(state: state)
            }
        }
    }
}

private struct PreviewPrayerWidgetChrome: View {
    let entry: PrayWindowPreviewEntry
    let family: WidgetFamily
    let moments: [PrayerMoment]

    private var language: AppLanguage { entry.settings.language }
    private var locale: Locale { language.locale }
    private var background: Color { Color(hex: entry.settings.theme.backgroundHex) }
    private var foreground: Color { Color(hex: entry.settings.theme.textHex) }
    private var panelBackground: Color { background.opacity(0.42) }
    private var panelBorder: Color { foreground.opacity(0.16) }
    private var cityName: String {
        let trimmed = entry.settings.city.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Current Location" : trimmed
    }
    private var prayerMoments: [PrayerMoment] {
        moments.filter { $0.prayer != .sunrise }
    }
    var body: some View {
        GeometryReader { proxy in
            let metrics = PreviewMetrics(
                size: proxy.size,
                multiplier: entry.settings.theme.textScale.multiplier * CGFloat(entry.settings.theme.fontSizeMultiplier)
            )

            ZStack {
                PreviewWidgetPhotoBackground(
                    settings: entry.settings,
                    tint: background,
                    tintOpacity: 0.78
                )

                previewContent(metrics: metrics)
                    .padding(widgetContentPadding(metrics: metrics))
            }
        }
        .foregroundStyle(foreground)
        .withPreviewPrayerAlertBar(for: entry)
    }

    @ViewBuilder
    private func previewContent(metrics: PreviewMetrics) -> some View {
        switch family {
        case .systemSmall:
            previewSmallLayout(metrics: metrics)
        case .systemMedium:
            previewMediumLayout(metrics: metrics)
        case .systemLarge:
            previewLargeLayout(metrics: metrics)
        default:
            previewMediumLayout(metrics: metrics)
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

    private func headerStrip(metrics: PreviewMetrics) -> some View {
        HStack(alignment: .top, spacing: metrics.inset(8)) {
            VStack(alignment: .leading, spacing: 3) {
                Text(weekdayTitle)
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .opacity(0.88)
                    .widgetTextFit(minScale: 0.82)
                Text(PrayerDateFormatter.gregorianDayMonth(for: entry.date, locale: locale))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .medium))
                    .opacity(0.72)
                    .widgetTextFit(minScale: 0.82)
            }
            Spacer()
            Text(PrayerDateFormatter.hijriDayMonth(for: entry.date, locale: locale))
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .medium))
                .multilineTextAlignment(.trailing)
                .widgetTextFit(lines: 2, minScale: 0.78)
        }
    }

    private func previewSmallLayout(metrics: PreviewMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.inset(4)) {
            headerStrip(metrics: metrics)
            cityLine(metrics: metrics)
            VStack(alignment: .leading, spacing: metrics.inset(2)) {
                Text(language.text(.nextPrayer))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .opacity(0.74)
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
        .padding(metrics.inset(8))
        .background(panelBackground)
        .overlay(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous).stroke(panelBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func previewMediumLayout(metrics: PreviewMetrics) -> some View {
        HStack(spacing: metrics.inset(10)) {
            VStack(alignment: .leading, spacing: metrics.inset(5)) {
                headerStrip(metrics: metrics)
                cityLine(metrics: metrics)
                Spacer(minLength: 0)
                Text(language.text(.nextPrayer))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .opacity(0.74)
                Text(entry.nextPrayer.prayer.title(for: language))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                    .widgetTextFit(lines: 1, minScale: 0.72)
                Text(PrayerDateFormatter.timeString(for: entry.nextPrayer.date, locale: locale))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(19), weight: .bold))
                    .monospacedDigit()
                    .widgetTextFit(lines: 1, minScale: 0.62)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(metrics.inset(12))
            .background(panelBackground)
            .overlay(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous).stroke(panelBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous))

            VStack(alignment: .leading, spacing: metrics.inset(5)) {
                Text(language.text(.prayerTimes))
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(10), weight: .semibold))
                    .opacity(0.74)
                ForEach(Array(prayerMoments.prefix(5)), id: \.id) { moment in
                    previewPrayerLine(moment: moment, metrics: metrics, compact: true)
                }
            }
            .frame(width: metrics.inset(124), alignment: .leading)
            .padding(metrics.inset(8))
            .background(panelBackground)
            .overlay(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous).stroke(panelBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: metrics.inset(18), style: .continuous))
        }
    }

    private func previewLargeLayout(metrics: PreviewMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.inset(8)) {
            HStack(spacing: metrics.inset(8)) {
                previewInfoPanel(day: gregorianDay, title: gregorianMonth, subtitle: language.text(.gregorian), metrics: metrics)
                previewInfoPanel(day: weekdayTitle, title: PrayerDateFormatter.gregorianDayMonth(for: entry.date, locale: locale), subtitle: language.text(.today), metrics: metrics, centered: true)
                previewInfoPanel(day: hijriDay, title: hijriMonth, subtitle: language.text(.hijri), metrics: metrics)
            }

            HStack(alignment: .top, spacing: metrics.inset(8)) {
                VStack(alignment: .leading, spacing: metrics.inset(5)) {
                    cityLine(metrics: metrics)
                    Text(language.text(.nextPrayer))
                        .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                        .opacity(0.74)
                    Text(entry.nextPrayer.prayer.title(for: language))
                        .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                        .widgetTextFit(lines: 1, minScale: 0.74)
                    Text(PrayerDateFormatter.timeString(for: entry.nextPrayer.date, locale: locale))
                        .font(entry.settings.theme.fontStyle.font(size: metrics.font(20), weight: .bold))
                        .monospacedDigit()
                        .widgetTextFit(lines: 1, minScale: 0.6)
                    Spacer(minLength: 0)
                    HStack(spacing: metrics.inset(8)) {
                        Image(systemName: "clock.fill")
                            .font(.caption.weight(.bold))
                        Text(language.text(.prayerTimes))
                            .font(entry.settings.theme.fontStyle.font(size: metrics.font(13), weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 176, alignment: .leading)
                .padding(metrics.inset(14))
                .background(panelBackground)
                .overlay(RoundedRectangle(cornerRadius: metrics.inset(20), style: .continuous).stroke(panelBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: metrics.inset(20), style: .continuous))

                VStack(alignment: .leading, spacing: metrics.inset(5)) {
                    HStack {
                        Text(language.text(.prayerTimes))
                            .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                        Spacer()
                        Text(language.text(.today))
                            .font(entry.settings.theme.fontStyle.font(size: metrics.font(10), weight: .medium))
                            .opacity(0.7)
                    }
                    ForEach(Array(prayerMoments), id: \.id) { moment in
                        previewPrayerLine(moment: moment, metrics: metrics, compact: false)
                    }
                }
                .frame(width: metrics.inset(150), alignment: .leading)
                .padding(metrics.inset(10))
                .background(panelBackground)
                .overlay(RoundedRectangle(cornerRadius: metrics.inset(20), style: .continuous).stroke(panelBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: metrics.inset(20), style: .continuous))
            }
        }
    }

    private func previewInfoPanel(day: String, title: String, subtitle: String, metrics: PreviewMetrics, centered: Bool = false) -> some View {
        VStack(alignment: centered ? .center : .leading, spacing: metrics.inset(2.5)) {
            Text(day)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                .widgetTextFit(lines: 1, minScale: 0.62)
            Text(title)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .semibold))
                .widgetTextFit(minScale: 0.78)
            Text(subtitle)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(11), weight: .medium))
                .opacity(0.68)
                .widgetTextFit(minScale: 0.82)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .padding(.horizontal, metrics.inset(11))
        .padding(.vertical, metrics.inset(10))
    }

    private func cityLine(metrics: PreviewMetrics) -> some View {
        Label(cityName, systemImage: "location.fill")
            .font(entry.settings.theme.fontStyle.font(size: metrics.font(9.6), weight: .semibold))
            .widgetTextFit(lines: 1, minScale: 0.72)
            .opacity(0.84)
    }

    private func previewPrayerLine(moment: PrayerMoment, metrics: PreviewMetrics, compact: Bool) -> some View {
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
        .padding(.vertical, metrics.inset(compact ? 1 : 2))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(foreground.opacity(0.18))
                .frame(height: 1)
                .offset(y: metrics.inset(4))
        }
    }

    private func widgetContentPadding(metrics: PreviewMetrics) -> CGFloat {
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

private struct PreviewCalendarWidgetChrome: View {
    let entry: PrayWindowPreviewEntry

    private var background: Color { Color(hex: entry.settings.theme.backgroundHex) }
    private var foreground: Color { Color(hex: entry.settings.theme.textHex) }
    private var rowFillA: Color { .clear }
    private var rowFillB: Color { .clear }
    private var cityName: String {
        let trimmed = entry.settings.city.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Current Location" : trimmed
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = PreviewMetrics(
                size: proxy.size,
                multiplier: 0.94 * CGFloat(entry.settings.theme.fontSizeMultiplier)
            )
            let language = entry.settings.language
            let locale = language.locale
            let headerFont = metrics.font(11.4)

            ZStack {
                PreviewWidgetPhotoBackground(
                    settings: entry.settings,
                    tint: background,
                    tintOpacity: 0.78
                )

                VStack(spacing: metrics.inset(7)) {
                    Label(cityName, systemImage: "location.fill")
                        .font(WidgetFontStyle.cairo.font(size: metrics.font(10.8), weight: .bold))
                        .foregroundStyle(foreground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    HStack(spacing: 0) {
                        previewHead(day: gregorianDay, top: gregorianMonth(locale: locale), middle: gregorianYear, bottom: language.text(.gregorian), metrics: metrics)
                        previewCenter(metrics: metrics)
                        previewHead(day: hijriDay, top: hijriMonth(locale: locale), middle: hijriYear, bottom: language.text(.hijri), metrics: metrics)
                    }
                    .frame(height: metrics.inset(74))
                    .clipped()

                    VStack(spacing: metrics.inset(4)) {
                        HStack(spacing: 0) {
                            previewColumn(language.text(.day), width: proxy.size.width * 0.22, size: headerFont)
                            previewColumn(Prayer.fajr.title(for: language), width: proxy.size.width * 0.156, size: headerFont)
                            previewColumn(Prayer.dhuhr.title(for: language), width: proxy.size.width * 0.156, size: headerFont)
                            previewColumn(Prayer.asr.title(for: language), width: proxy.size.width * 0.156, size: headerFont)
                            previewColumn(Prayer.maghrib.title(for: language), width: proxy.size.width * 0.156, size: headerFont)
                            previewColumn(Prayer.isha.title(for: language), width: proxy.size.width * 0.156, size: headerFont)
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(upcomingSchedules.enumerated()), id: \.element.id) { index, item in
                                previewRow(item: item, index: index, width: proxy.size.width, metrics: metrics)
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
                .padding(3)
            }
        }
        .environment(\.layoutDirection, entry.settings.language.layoutDirection)
        .withPreviewPrayerAlertBar(for: entry)
    }

    private func previewHead(day: String, top: String, middle: String, bottom: String, metrics: PreviewMetrics) -> some View {
        VStack(spacing: 0) {
            Text(day)
                .font(WidgetFontStyle.cairo.font(size: metrics.font(15), weight: .bold))
                .frame(maxWidth: .infinity, minHeight: metrics.inset(16), alignment: .top)
                .padding(.top, metrics.inset(2))

            Spacer(minLength: metrics.inset(1))

            VStack(spacing: metrics.inset(0.5)) {
                Text(top).font(WidgetFontStyle.cairo.font(size: metrics.font(12.3), weight: .bold))
                Text(middle).font(WidgetFontStyle.cairo.font(size: metrics.font(10.5), weight: .bold))
                Text(bottom).font(WidgetFontStyle.cairo.font(size: metrics.font(9.4), weight: .bold))
            }
            .padding(.bottom, metrics.inset(4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(foreground)
    }

    private func previewCenter(metrics: PreviewMetrics) -> some View {
        WeekdaySealImageView(date: entry.date, side: metrics.inset(62))
            .frame(width: metrics.inset(76), height: metrics.inset(76))
            .frame(maxHeight: .infinity, alignment: .center)
    }

    private func previewColumn(_ title: String, width: CGFloat, size: CGFloat) -> some View {
        Text(title)
            .font(WidgetFontStyle.cairo.font(size: size, weight: .bold))
            .frame(width: width, height: 28)
            .foregroundStyle(foreground)
    }

    private func previewRow(item: PreviewCalendarDaySchedule, index: Int, width: CGFloat, metrics: PreviewMetrics) -> some View {
        let rowColor = index.isMultiple(of: 2) ? rowFillA : rowFillB
        let formatter = DateFormatter()
        formatter.locale = entry.settings.language.locale
        formatter.dateFormat = "h:mm"

        return HStack(spacing: 0) {
            previewCell(item.dayLabel, width: width * 0.22, metrics: metrics, fill: rowColor, bold: true)
            previewCell(timeString(for: item.schedule, prayer: .fajr, formatter: formatter), width: width * 0.156, metrics: metrics, fill: rowColor)
            previewCell(timeString(for: item.schedule, prayer: .dhuhr, formatter: formatter), width: width * 0.156, metrics: metrics, fill: rowColor)
            previewCell(timeString(for: item.schedule, prayer: .asr, formatter: formatter), width: width * 0.156, metrics: metrics, fill: rowColor)
            previewCell(timeString(for: item.schedule, prayer: .maghrib, formatter: formatter), width: width * 0.156, metrics: metrics, fill: rowColor)
            previewCell(timeString(for: item.schedule, prayer: .isha, formatter: formatter), width: width * 0.156, metrics: metrics, fill: rowColor)
        }
    }

    private func previewCell(_ text: String, width: CGFloat, metrics: PreviewMetrics, fill: Color, bold: Bool = false) -> some View {
        Text(text)
            .font(WidgetFontStyle.cairo.font(size: metrics.font(10.5), weight: .bold))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: width, height: metrics.inset(28))
            .background(fill)
    }

    private var upcomingSchedules: [PreviewCalendarDaySchedule] {
        let calendar = Calendar(identifier: .gregorian)
        return (0..<5).compactMap { offset in
            guard let targetDate = calendar.date(byAdding: .day, value: offset, to: entry.date) else {
                return nil
            }

            return PreviewCalendarDaySchedule(
                date: targetDate,
                dayLabel: dayLabel(for: targetDate, isToday: offset == 0),
                schedule: PrayerCalculator.schedule(
                    for: targetDate,
                    latitude: entry.settings.latitude,
                    longitude: entry.settings.longitude,
                    method: entry.settings.calculationMethod
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

    private var gregorianDay: String { String(Calendar(identifier: .gregorian).component(.day, from: entry.date)) }
    private var gregorianYear: String { String(Calendar(identifier: .gregorian).component(.year, from: entry.date)) }
    private var hijriDay: String { String(Calendar(identifier: .islamicUmmAlQura).component(.day, from: entry.date)) }
    private var hijriYear: String { String(Calendar(identifier: .islamicUmmAlQura).component(.year, from: entry.date)) }

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

private struct PreviewCountdownWidgetChrome: View {
    let entry: PrayWindowPreviewEntry

    private var language: AppLanguage { entry.settings.language }
    private var locale: Locale { language.locale }
    private var background: Color { Color(hex: entry.settings.theme.backgroundHex) }
    private var foreground: Color { Color(hex: entry.settings.theme.textHex) }
    private var cityName: String {
        let trimmed = entry.settings.city.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Current Location" : trimmed
    }
    var body: some View {
        GeometryReader { proxy in
            let metrics = PreviewMetrics(
                size: proxy.size,
                multiplier: entry.settings.theme.textScale.multiplier * CGFloat(entry.settings.theme.fontSizeMultiplier)
            )

            VStack(alignment: .leading, spacing: metrics.inset(5)) {
                Label(cityName, systemImage: "location.fill")
                    .font(entry.settings.theme.fontStyle.font(size: metrics.font(10.5), weight: .semibold))
                    .widgetTextFit(minScale: 0.72)
                    .opacity(0.84)

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
            .padding(metrics.inset(12))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                PreviewWidgetPhotoBackground(
                    settings: entry.settings,
                    tint: background,
                    tintOpacity: 0.8
                )
            )
        }
        .withPreviewPrayerAlertBar(for: entry)
    }
}

private struct PreviewImagePrayerMediumWidgetChrome: View {
    let entry: PrayWindowPreviewEntry
    let moments: [PrayerMoment]

    private var language: AppLanguage { entry.settings.language }
    private var locale: Locale { language.locale }
    private var background: Color { Color(hex: entry.settings.theme.backgroundHex) }
    private var foreground: Color { Color(hex: entry.settings.theme.textHex) }
    private var lowerSectionBackground: Color { background.opacity(0.78) }
    private var cityName: String {
        let trimmed = entry.settings.city.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Current Location" : trimmed
    }
    private var prayerMoments: [PrayerMoment] {
        moments.filter { $0.prayer != .sunrise }
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = PreviewMetrics(
                size: proxy.size,
                multiplier: entry.settings.theme.textScale.multiplier * CGFloat(entry.settings.theme.fontSizeMultiplier)
            )

            VStack(spacing: 0) {
                if let image = PreviewWidgetPhotoSource.uiImage(for: entry.settings) {
                    WidgetPhotoFillView(image: image, focalPoint: entry.settings.customPhotoFocusPoint)
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.5)
                } else {
                    Color.clear
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.5)
                }

                VStack(alignment: .leading, spacing: metrics.inset(4)) {
                    Label(cityName, systemImage: "location.fill")
                        .font(entry.settings.theme.fontStyle.font(size: metrics.font(10.4), weight: .semibold))
                        .widgetTextFit(minScale: 0.72)
                        .opacity(0.84)

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
        .withPreviewPrayerAlertBar(for: entry)
    }

    private func prayerMomentCell(moment: PrayerMoment, metrics: PreviewMetrics) -> some View {
        VStack(spacing: metrics.inset(2.5)) {
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

private struct PreviewDateWisdomMediumWidgetChrome: View {
    let entry: PrayWindowPreviewEntry

    private var language: AppLanguage { entry.settings.language }
    private var locale: Locale { language.locale }
    private var background: Color { Color(hex: entry.settings.theme.backgroundHex) }
    private var foreground: Color { Color(hex: entry.settings.theme.textHex) }
    private var panelBackground: Color { background.opacity(0.76) }
    private var panelBorder: Color { foreground.opacity(0.14) }
    private var cityName: String {
        let trimmed = entry.settings.city.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Current Location" : trimmed
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = PreviewMetrics(
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
        .withPreviewPrayerAlertBar(for: entry)
    }

    private func infoPanel(metrics: PreviewMetrics) -> some View {
        VStack(alignment: .center, spacing: metrics.inset(12)) {
            Text(weekdayTitle)
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(24), weight: .bold))
                .widgetTextFit(lines: 1, minScale: 0.6)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Label(cityName, systemImage: "location.fill")
                .font(entry.settings.theme.fontStyle.font(size: metrics.font(10.8), weight: .semibold))
                .widgetTextFit(lines: 1, minScale: 0.72)
                .opacity(0.84)

            HStack(alignment: .top, spacing: metrics.inset(8)) {
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

    private func dateColumn(day: String, month: String, year: String, metrics: PreviewMetrics, emphasized: Bool) -> some View {
        VStack(spacing: metrics.inset(2)) {
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

    private func imagePanel(metrics: PreviewMetrics) -> some View {
        ZStack {
            if let image = PreviewWidgetPhotoSource.uiImage(for: entry.settings) {
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

private struct PreviewLockScreenCountdownCircularView: View {
    let entry: PrayWindowPreviewEntry

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
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
        .background {
            Circle()
                .fill(Color.white.opacity(0.14))

            Circle()
                .stroke(Color.white.opacity(0.26), lineWidth: 2)
        }
    }

    private var shortPrayerName: String {
        let title = entry.nextPrayer.prayer.title(for: language)
        return title.count > 10 ? String(title.prefix(10)) : title
    }
}

private struct PreviewLockScreenPrayerRectangularView: View {
    let entry: PrayWindowPreviewEntry

    private var language: AppLanguage { entry.settings.language }
    private var cityName: String {
        let trimmed = entry.settings.city.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Current Location" : trimmed
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.14))

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.nextPrayer.prayer.title(for: language))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .widgetTextFit(lines: 1, minScale: 0.65)

                    Text(cityName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .widgetTextFit(lines: 1, minScale: 0.62)
                }

                Text(entry.nextPrayer.date, style: .timer)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .widgetTextFit(lines: 1, minScale: 0.68)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

private struct PreviewCalendarDaySchedule: Identifiable {
    let date: Date
    let dayLabel: String
    let schedule: PrayerDaySchedule

    var id: TimeInterval { date.timeIntervalSince1970 }
}

private struct CapsuleTagButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WidgetFontStyle.rubik.font(size: 14, weight: .semibold))
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background(Color(hex: "#EEF2EC"), in: Capsule())
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private struct FilledActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WidgetFontStyle.rubik.font(size: 17, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(.white)
            .background(Color(hex: "#183A2A"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private struct OutlineActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WidgetFontStyle.rubik.font(size: 17, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(Color(hex: "#183A2A"))
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "#183A2A").opacity(0.2), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
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

#Preview {
    ContentView()
}
