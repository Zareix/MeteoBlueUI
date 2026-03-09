//
//  WidgetDataService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 04/03/2026.
//

import CoreLocation
import Foundation
import MapKit
import OSLog
import WidgetKit

private let wdLogger = Logger(subsystem: "com.zareix.MeteoBlueUI", category: "WidgetDataService")

// MARK: - Shared models

struct WidgetHourEntry: Codable {
    let time: Date
    let symbol: String
    let description: String
    let temperature: Double
    let precipitationProbability: Int
}

struct WidgetData: Codable {
    let location: WeatherLocation
    let hours: [WidgetHourEntry]
    let savedAt: Date
}

// MARK: - Service

enum WidgetDataService {
    static let appGroupID = "group.com.zareix.MeteoBlueUI"
    static let userDefaultsKey = "widget_forecast_data"
    static let staleThreshold: TimeInterval = 60 * 60 // 1 hour

    static func isStale() -> Bool {
        guard let data = loadFromCache() else { return true }
        return Date().timeIntervalSince(data.savedAt) >= staleThreshold
    }

    static func loadFromCache() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            wdLogger.error("❌ loadFromCache: UserDefaults(suiteName:) returned nil — App Group '\(appGroupID)' not configured")
            return nil
        }
        guard let data = defaults.data(forKey: userDefaultsKey) else {
            wdLogger.warning("⚠️ loadFromCache: no data for key '\(userDefaultsKey)' — cache is empty")
            return nil
        }
        guard let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            wdLogger.error("❌ loadFromCache: JSON decode failed")
            return nil
        }
        wdLogger.info("✅ loadFromCache: hit — city=\(widgetData.location.city), savedAt=\(widgetData.savedAt), hours=\(widgetData.hours.count)")
        return widgetData
    }

    static func fetchWidgetData(for location: WeatherLocation) async throws -> WidgetData {
        wdLogger.info("🌐 fetchWidgetData: fetching for \(location.city) (\(location.latitude), \(location.longitude))")
        let forecast = try await MeteoBlueAPIService().fetchForecast(location: location)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let now = Date()
        let hours: [WidgetHourEntry] = forecast.data1H.time.enumerated().compactMap { index, timeStr in
            let date = formatter.date(from: timeStr) ?? Date()
            guard date >= now else { return nil }
            return WidgetHourEntry(
                time: date,
                symbol: PictoMapper.pictoToSFSymbol(
                    picto: forecast.data1H.pictocode[index],
                    isDaylight: forecast.data1H.isdaylight[index] != 0
                ),
                description: PictoMapper.pictoToDescription(picto: forecast.data1H.pictocode[index]),
                temperature: forecast.data1H.temperature[index],
                precipitationProbability: forecast.data1H.precipitationProbability[index]
            )
        }

        let widgetData = WidgetData(location: location, hours: hours, savedAt: now)
        wdLogger.info("✅ fetchWidgetData: got \(hours.count) future hours for \(location.city)")

        if let encoded = try? JSONEncoder().encode(widgetData),
           let defaults = UserDefaults(suiteName: appGroupID)
        {
            defaults.set(encoded, forKey: userDefaultsKey)
            wdLogger.info("💾 fetchWidgetData: saved to App Group cache")
        } else {
            wdLogger.error("❌ fetchWidgetData: failed to save to App Group cache")
        }

        return widgetData
    }

    static func fetchCurrentLocation() async -> WeatherLocation {
        if let location = await _WidgetLocationResolver.resolve() {
            return location
        }
        return loadFromCache()?.location ?? _WidgetLocationResolver.defaultLocation()
    }

    static func loadOrFetch() async -> WidgetData? {
        // 1. If we have a fresh cache, use it immediately — no GPS needed
        if !isStale(), let cached = loadFromCache() {
            wdLogger.info("♻️ loadOrFetch: using fresh cache for \(cached.location.city)")
            return cached
        }

        // 2. Determine location: prefer cached location, only fall back to GPS if nothing cached
        let location: WeatherLocation
        if let cachedLocation = loadFromCache()?.location {
            wdLogger.info("📍 loadOrFetch: using cached location = \(cachedLocation.city)")
            location = cachedLocation
        } else {
            wdLogger.info("📍 loadOrFetch: no cache, resolving location via GPS…")
            location = await fetchCurrentLocation()
            wdLogger.info("📍 loadOrFetch: resolved location = \(location.city)")
        }

        // 3. Fetch fresh data for that location
        wdLogger.info("🔄 loadOrFetch: cache stale or missing, fetching…")
        do {
            return try await fetchWidgetData(for: location)
        } catch {
            wdLogger.error("❌ loadOrFetch: fetch failed — \(error, privacy: .public). Falling back to stale cache.")
            return loadFromCache()
        }
    }
}

// MARK: - _WidgetLocationResolver

/// Minimal one-shot CLLocationManager using async/await. No Combine dependency.
private final class _WidgetLocationResolver: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<WeatherLocation?, Never>?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    static func defaultLocation() -> WeatherLocation {
        return WeatherLocation(
            city: "Cupertino",
            country: "United States",
            latitude: 37.323,
            longitude: -122.032
        )
    }

    // Retained for the lifetime of the async location request
    private static var _active: _WidgetLocationResolver?

    static func resolve() async -> WeatherLocation? {
        await withCheckedContinuation { continuation in
            let resolver = _WidgetLocationResolver()
            _active = resolver          // keep alive until resume()
            resolver.continuation = continuation
            resolver.start()
        }
    }

    private func start() {
        wdLogger.info("📡 _WidgetLocationResolver: authStatus=\(self.manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            wdLogger.warning("⚠️ _WidgetLocationResolver: location not authorized, skipping GPS")
            resume(with: nil)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        wdLogger.info("📡 _WidgetLocationResolver: authChanged=\(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            resume(with: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { resume(with: nil); return }
        wdLogger.info("📍 _WidgetLocationResolver: got GPS fix, reverse geocoding…")
        let request = MKReverseGeocodingRequest(location: location)
        request?.getMapItems { [weak self] mapItems, error in
            if let error {
                wdLogger.error("❌ _WidgetLocationResolver: reverse geocode failed — \(error, privacy: .public)")
                self?.resume(with: nil)
                return
            }
            guard let mapItem = mapItems?.first else {
                wdLogger.warning("⚠️ _WidgetLocationResolver: no map items returned")
                self?.resume(with: nil)
                return
            }
            let loc = WeatherLocation(from: mapItem)
            wdLogger.info("✅ _WidgetLocationResolver: resolved to \(loc.city)")
            self?.resume(with: loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        wdLogger.error("❌ _WidgetLocationResolver: CLLocationManager failed — \(error, privacy: .public)")
        resume(with: nil)
    }

    private func resume(with location: WeatherLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
        Self._active = nil   // release the retained reference
    }
}
