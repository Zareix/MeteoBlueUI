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
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: userDefaultsKey),
            let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data)
        else { return nil }
        return widgetData
    }

    static func fetchWidgetData(for location: WeatherLocation) async throws -> WidgetData {
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

        if let encoded = try? JSONEncoder().encode(widgetData),
           let defaults = UserDefaults(suiteName: appGroupID)
        {
            defaults.set(encoded, forKey: userDefaultsKey)
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
        let location = await fetchCurrentLocation()
        if !isStale(), let cached = loadFromCache(), cached.location == location {
            return cached
        }
        do {
            return try await fetchWidgetData(for: location)
        } catch {
            print("WidgetDataService: fetch failed — \(error). Using stale cache if available.")
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

    static func resolve() async -> WeatherLocation? {
        await withCheckedContinuation { continuation in
            let resolver = _WidgetLocationResolver()
            resolver.continuation = continuation
            resolver.start()
            _ = resolver
        }
    }

    private func start() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            resume(with: nil)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            resume(with: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { resume(with: nil); return }
        let request = MKReverseGeocodingRequest(location: location)
        request?.getMapItems { [weak self] mapItems, error in
            guard let mapItem = mapItems?.first, error == nil else {
                self?.resume(with: nil)
                return
            }
            self?.resume(with: WeatherLocation(from: mapItem))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("_WidgetLocationResolver: \(error)")
        resume(with: nil)
    }

    private func resume(with location: WeatherLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
    }
}
