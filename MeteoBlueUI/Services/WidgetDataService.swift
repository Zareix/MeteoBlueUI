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

private let wdLogger = Logger(subsystem: "com.raphaelgc.MeteoBlueUI", category: "WidgetDataService")

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
    static let userDefaultsKey = "widget_forecast_data"
    static let staleThreshold: TimeInterval = 60 * 60 // 1 hour

    static func isStale() -> Bool {
        guard let data = loadFromCache() else { return true }
        return Date().timeIntervalSince(data.savedAt) >= staleThreshold
    }

    static func loadFromCache() -> WidgetData? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data)
        else {
            return nil
        }
        return widgetData
    }

    static func fetchWidgetData(for location: WeatherLocation) async throws -> WidgetData {
        // Pour les widgets, utiliser directement URLSession.shared
        guard let token = KeychainService().getMetoBlueAPIToken() else {
            throw AppError.noAPIToken
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "my.meteoblue.com"
        components.path = "/packages/basic-1h_basic-day"
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.latitude)),
            URLQueryItem(name: "lon", value: String(location.longitude)),
            URLQueryItem(name: "apikey", value: token),
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200 ... 299: break
            case 401: throw AppError.invalidAPIToken
            case 429: throw AppError.rateLimitExceeded
            default: throw AppError.httpError(http.statusCode)
            }
        }

        let forecast = try JSONDecoder().decode(MeteoBlueAPIForecast.self, from: data)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let now = Date().addingTimeInterval(-3600)

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

        let widgetData = WidgetData(location: location, hours: hours, savedAt: Date())

        if let encoded = try? JSONEncoder().encode(widgetData) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }

        return widgetData
    }

    static func fetchCurrentLocation() async -> WeatherLocation {
        // Timeout de 5 secondes pour la localisation
        let location = await withTaskGroup(of: WeatherLocation?.self) { group in
            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 secondes
                wdLogger.warning("⏱️ Location resolution timeout")
                return nil
            }
            group.addTask {
                await _WidgetLocationResolver.resolve()
            }

            let first = await group.next()
            group.cancelAll()
            return first ?? nil
        }

        if let location = location {
            return location
        }
        return loadFromCache()?.location ?? _WidgetLocationResolver.defaultLocation()
    }

    static func loadOrFetch() async -> WidgetData? {
        if !isStale(), let cached = loadFromCache() {
            return cached
        }

        let location: WeatherLocation
        if let cachedLocation = loadFromCache()?.location {
            location = cachedLocation
        } else {
            location = await fetchCurrentLocation()
        }

        do {
            return try await fetchWidgetData(for: location)
        } catch {
            wdLogger.error("Failed to fetch widget data: \(error.localizedDescription)")
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

    private static var _active: _WidgetLocationResolver?

    static func resolve() async -> WeatherLocation? {
        await withCheckedContinuation { continuation in
            let resolver = _WidgetLocationResolver()
            _active = resolver
            resolver.continuation = continuation
            resolver.start()
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
            if error != nil || mapItems?.first == nil {
                self?.resume(with: nil)
                return
            }
            let loc = WeatherLocation(from: mapItems!.first!)
            self?.resume(with: loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(with: nil)
    }

    private func resume(with location: WeatherLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
        Self._active = nil
    }
}
