//
//  LocationManager.swift
//  PrayWindow
//
//  Created by Codex on 23/04/2026.
//

import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isResolvingLocation = false
    @Published var errorMessage: String?

    private let manager = CLLocationManager()
    private var onLocationResolved: ((CLLocationCoordinate2D, String) -> Void)?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentLocation(onResolved: @escaping (CLLocationCoordinate2D, String) -> Void) {
        onLocationResolved = onResolved
        errorMessage = nil

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            errorMessage = "Location permission is disabled. Please allow location access in Settings."
        default:
            isResolvingLocation = true
            manager.requestLocation()
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
                isResolvingLocation = true
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isResolvingLocation = false
            errorMessage = error.localizedDescription
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        Task { @MainActor in
            defer { onLocationResolved = nil }
            do {
                let city = try await reverseGeocodeCity(for: location)
                    ?? "Current Location"

                isResolvingLocation = false
                errorMessage = nil
                onLocationResolved?(location.coordinate, city)
            } catch {
                isResolvingLocation = false
                errorMessage = error.localizedDescription
                onLocationResolved?(location.coordinate, "Current Location")
            }
        }
    }

    private func reverseGeocodeCity(for location: CLLocation) async throws -> String? {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        let placemark = placemarks.first
        return placemark?.locality
            ?? placemark?.subAdministrativeArea
            ?? placemark?.administrativeArea
            ?? placemark?.name
    }
}
