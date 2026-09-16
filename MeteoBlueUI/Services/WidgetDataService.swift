//
//  WidgetDataService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 04/03/2026.
//

import CoreLocation
import Foundation
import MapKit
import WidgetKit

// MARK: - Service

enum WidgetDataService {
    static let appGroupID = "group.com.raphaelgc.MeteoBlueUI"
    static let staleThreshold: TimeInterval = 60 * 60 // 1 hour

    // Cache is keyed per provider AND location so widgets configured with different providers
    // or different cities (Edit Widget > Location) don't overwrite each other's data — and so
    // switching a widget's favorite city can't keep serving another city's fresh-looking cache.
    private static func userDefaultsKey(for providerType: WeatherProviderType, locationID: String) -> String {
        "widget_forecast_data_\(providerType.rawValue)_\(locationID)"
    }

    static func isStale(providerType: WeatherProviderType, locationID: String) -> Bool {
        guard let data = loadFromCache(providerType: providerType, locationID: locationID) else { return true }
        return Date().timeIntervalSince(data.savedAt) >= staleThreshold
    }

    static func loadFromCache(providerType: WeatherProviderType, locationID: String) -> WidgetData? {
        let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
        guard let data = userDefaults.data(forKey: userDefaultsKey(for: providerType, locationID: locationID)),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data)
        else {
            return nil
        }
        return widgetData
    }

    /// Best-effort cache lookup for when the exact location isn't known yet without an async
    /// resolution (e.g. a widget-gallery preview in "Current Location" mode). Returns whichever
    /// location was most recently fetched for this provider.
    static func mostRecentCache(providerType: WeatherProviderType) -> WidgetData? {
        let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
        let prefix = "widget_forecast_data_\(providerType.rawValue)_"
        return userDefaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
            .compactMap { userDefaults.data(forKey: $0) }
            .compactMap { try? JSONDecoder().decode(WidgetData.self, from: $0) }
            .max { $0.savedAt < $1.savedAt }
    }

    static func fetchWidgetData(for location: WeatherLocation, providerType: WeatherProviderType) async throws -> WidgetData {
        let widgetData = try await providerType.makeService().fetchWidgetData(location: location)

        if let encoded = try? JSONEncoder().encode(widgetData) {
            let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
            userDefaults.set(encoded, forKey: userDefaultsKey(for: providerType, locationID: location.id))
            WidgetCenter.shared.reloadAllTimelines()
        }

        return widgetData
    }

    /// Resolves the location to show in the widget, per its own configuration (Edit Widget):
    /// a specific favorite the user picked, or the device's current position.
    static func resolveLocation(preferredFavorite: WeatherLocation?) async -> WeatherLocation {
        if let preferredFavorite {
            return preferredFavorite
        }

        if let location = await WidgetLocationFetcher.fetchCurrentLocation() {
            saveLastKnownLocation(location)
            return location
        }

        // Le GPS n'a rien donné : on réutilise la dernière position résolue
        // (mieux vaut des données d'un endroit légèrement daté que le fallback).
        if let last = loadLastKnownLocation() {
            return last
        }

        return fallbackLocation()
    }

    // MARK: Last resolved location cache

    /// La dernière position résolue, pour éviter d'afficher un fallback quand
    /// le GPS n'a pas le temps de répondre pendant le court cycle de vie du widget.
    private static let lastLocationKey = "widget_last_resolved_location"

    private static func saveLastKnownLocation(_ location: WeatherLocation) {
        guard let encoded = try? JSONEncoder().encode(location) else { return }
        let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
        userDefaults.set(encoded, forKey: lastLocationKey)
    }

    private static func loadLastKnownLocation() -> WeatherLocation? {
        let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
        guard let data = userDefaults.data(forKey: lastLocationKey),
              let location = try? JSONDecoder().decode(WeatherLocation.self, from: data)
        else {
            return nil
        }
        return location
    }

    private static func fallbackLocation() -> WeatherLocation {
        if let location = FavoriteCities().items.first {
            return location
        }

        if let location = SearchHistory().items.first {
            return location
        }

        return WeatherLocation(
            city: "Cupertino",
            country: "United States",
            latitude: 37.323,
            longitude: -122.032
        )
    }
}

// MARK: - Live location fetch

/// Fetches a one-shot device location and reverse-geocodes it, for use from the widget
/// extension. Relies on `NSWidgetWantsLocation` + the containing app's "When In Use"
/// authorization — the extension never prompts for permission itself.
/// `@unchecked Sendable`: mutable state is only ever touched serially on the main queue
/// (the CLLocationManager delegate callbacks and the timeout closure below).
private final class WidgetLocationFetcher: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    static func fetchCurrentLocation() async -> WeatherLocation? {
        guard let clLocation = await WidgetLocationFetcher().requestLocation() else { return nil }
        return await Self.reverseGeocode(clLocation)
    }

    /// Au-delà de cet âge, la dernière position connue est considérée trop vieille
    /// et on demande une nouvelle correction GPS.
    private static let cachedLocationMaxAge: TimeInterval = 15 * 60

    private func requestLocation() async -> CLLocation? {
        // Chemin rapide : la dernière position connue du système (fix de l'app
        // principale ou d'un reload précédent) est quasi instantanée à lire,
        // alors qu'un `requestLocation()` dans un processus widget froid peut
        // mettre plusieurs secondes — ou tomber dans le timeout.
        if let last = manager.location,
           Date().timeIntervalSince(last.timestamp) < Self.cachedLocationMaxAge {
            return last
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.delegate = self

            guard manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways
            else {
                finish(with: nil)
                return
            }

            manager.requestLocation()

            // Widget refreshes are budgeted; don't let a stuck fix block the timeline forever.
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
                self?.finish(with: nil)
            }
        }
    }

    private func finish(with location: CLLocation?) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: location)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finish(with: locations.first)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: nil)
    }

    private static func reverseGeocode(_ location: CLLocation) async -> WeatherLocation? {
        await withCheckedContinuation { continuation in
            guard let request = MKReverseGeocodingRequest(location: location) else {
                continuation.resume(returning: nil)
                return
            }
            request.getMapItems { mapItems, error in
                guard let mapItem = mapItems?.first, error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: WeatherLocation(from: mapItem))
            }
        }
    }
}
