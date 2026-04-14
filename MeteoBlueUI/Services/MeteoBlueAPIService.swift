//
//  MeteoBlueAPIService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import Foundation
import MapKit
import OSLog

private let apiLogger = Logger(subsystem: "com.raphaelgc.MeteoBlueUI", category: "MeteoBlueAPIService")

actor MeteoBlueAPIService {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    private var forecastTask: Task<MeteoBlueAPIForecast, Error>?
    private var forecast1HTask: Task<MeteoBlueAPI1HForecast, Error>?
    private var nextHourTask: Task<MeteoBlueAPI15Min, Error>?

    func getCityFromCompletion(title: String, subtitle: String) async throws -> WeatherLocation? {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "\(title), \(subtitle)"
        let search = MKLocalSearch(request: searchRequest)
        let response = try? await search.start()
        guard let mapItem = response?.mapItems.first else {
            print("No results found")
            return nil
        }
        return WeatherLocation(from: mapItem)
    }

    func fetchForecast(location: WeatherLocation) async throws -> MeteoBlueAPIForecast {
        forecastTask?.cancel()

        let task = Task<MeteoBlueAPIForecast, Error> {
            let (lat, lon) = (location.latitude, location.longitude)
            apiLogger.info("🌐 fetchForecast: \(location.city) lat=\(lat) lon=\(lon)")

            guard let token = KeychainService().getMetoBlueAPIToken() else {
                apiLogger.error("❌ fetchForecast: no API token in keychain — widget cannot fetch")
                throw AppError.noAPIToken
            }
            apiLogger.info("🔑 fetchForecast: API token found (\(token.prefix(4))…)")

            var components = URLComponents()
            components.scheme = "https"
            components.host = "my.meteoblue.com"
            components.path = "/packages/basic-1h_basic-day"
            components.queryItems = [
                URLQueryItem(name: "lat", value: String(lat)),
                URLQueryItem(name: "lon", value: String(lon)),
                URLQueryItem(name: "apikey", value: token),
            ]
            guard let url = components.url else { throw URLError(.badURL) }

            let (data, response) = try await session.data(from: url)

            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200 ... 299: break
                case 401: throw AppError.invalidAPIToken
                case 429: throw AppError.rateLimitExceeded
                default: throw AppError.httpError(http.statusCode)
                }
            }

            return try JSONDecoder().decode(MeteoBlueAPIForecast.self, from: data)
        }

        forecastTask = task
        return try await task.value
    }

    func fetch1HForecast(location: WeatherLocation) async throws -> MeteoBlueAPI1HForecast {
        forecast1HTask?.cancel()

        let task = Task<MeteoBlueAPI1HForecast, Error> {
            let (lat, lon) = (location.latitude, location.longitude)
            apiLogger.info("🌐 fetch1HForecast: \(location.city) lat=\(lat) lon=\(lon)")

            guard let token = KeychainService().getMetoBlueAPIToken() else {
                apiLogger.error("❌ fetch1HForecast: no API token in keychain — widget cannot fetch")
                throw AppError.noAPIToken
            }
            apiLogger.info("🔑 fetch1HForecast: API token found (\(token.prefix(4))…)")

            var components = URLComponents()
            components.scheme = "https"
            components.host = "my.meteoblue.com"
            components.path = "/packages/basic-1h"
            components.queryItems = [
                URLQueryItem(name: "lat", value: String(lat)),
                URLQueryItem(name: "lon", value: String(lon)),
                URLQueryItem(name: "apikey", value: token),
            ]
            guard let url = components.url else { throw URLError(.badURL) }

            let (data, response) = try await session.data(from: url)

            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200 ... 299: break
                case 401: throw AppError.invalidAPIToken
                case 429: throw AppError.rateLimitExceeded
                default: throw AppError.httpError(http.statusCode)
                }
            }

            return try JSONDecoder().decode(MeteoBlueAPI1HForecast.self, from: data)
        }

        forecast1HTask = task
        return try await task.value
    }

    func fetch15Min(location: WeatherLocation) async throws -> MeteoBlueAPI15Min {
        nextHourTask?.cancel()

        let task = Task<MeteoBlueAPI15Min, Error> {
            let (lat, lon) = (location.latitude, location.longitude)
            print(
                "Fetching MeteoBlue API 15-min for \(location.city) — lat: \(lat), lon: \(lon)"
            )

            guard let token = KeychainService().getMetoBlueAPIToken() else {
                throw AppError.noAPIToken
            }

            var components = URLComponents()
            components.scheme = "https"
            components.host = "my.meteoblue.com"
            components.path = "/packages/basic-15min"
            components.queryItems = [
                URLQueryItem(name: "lat", value: String(lat)),
                URLQueryItem(name: "lon", value: String(lon)),
                URLQueryItem(name: "apikey", value: token),
            ]
            guard let url = components.url else { throw URLError(.badURL) }

            let (data, response) = try await session.data(from: url)

            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200 ... 299: break
                case 401: throw AppError.invalidAPIToken
                case 429: throw AppError.rateLimitExceeded
                default: throw AppError.httpError(http.statusCode)
                }
            }

            return try JSONDecoder().decode(MeteoBlueAPI15Min.self, from: data)
        }

        nextHourTask = task
        return try await task.value
    }
}
