//
//  WeatherProviderType.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 19/05/2026.
//

import Foundation

enum WeatherProviderType: String, CaseIterable, Identifiable {
    case meteoblue
    case weatherkit
    case openmeteo

    var id: String {
        rawValue
    }

    static let storageKey = "weather.provider"
    private static let userDefaults = UserDefaults(suiteName: "group.com.raphaelgc.MeteoBlueUI") ?? .standard
    static let didChangeNotification = Notification.Name("WeatherProviderTypeDidChange")

    static var current: WeatherProviderType {
        get {
            if let raw = userDefaults.string(forKey: storageKey),
               let value = WeatherProviderType(rawValue: raw)
            {
                return value
            }
            return .weatherkit
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: storageKey)
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }
}
