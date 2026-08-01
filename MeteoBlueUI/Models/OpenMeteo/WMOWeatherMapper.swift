//
//  WMOWeatherMapper.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 31/07/2026.
//

/// Maps Open-Meteo's WMO weather codes to
/// a description and SF Symbol, mirroring PictoMapper's role for MeteoBlue.
struct WMOWeatherMapper {
    static func description(code: Int) -> String {
        return switch code {
        case 0: "Ciel clair"
        case 1: "Principalement clair"
        case 2: "Partiellement nuageux"
        case 3: "Couvert"
        case 45, 48: "Brouillard"
        case 51, 53, 55: "Bruine"
        case 56, 57: "Bruine verglaçante"
        case 61, 63, 65: "Pluie"
        case 66, 67: "Pluie verglaçante"
        case 71, 73, 75: "Neige"
        case 77: "Grains de neige"
        case 80, 81, 82: "Averses de pluie"
        case 85, 86: "Averses de neige"
        case 95: "Orage"
        case 96, 99: "Orage avec grêle"
        default: "Inconnu"
        }
    }

    static func sfSymbol(code: Int, isDaylight: Bool) -> String {
        let symbol: (day: String, night: String) = switch code {
        case 0: ("sun.max.fill", "moon.fill")
        case 1: ("sun.max.fill", "moon.fill")
        case 2: ("cloud.sun.fill", "cloud.moon.fill")
        case 3: ("cloud.fill", "cloud.fill")
        case 45, 48: ("cloud.fog.fill", "cloud.fog.fill")
        case 51, 53, 55: ("cloud.drizzle.fill", "cloud.drizzle.fill")
        case 56, 57: ("cloud.sleet.fill", "cloud.sleet.fill")
        case 61, 63, 65: ("cloud.rain.fill", "cloud.rain.fill")
        case 66, 67: ("cloud.sleet.fill", "cloud.sleet.fill")
        case 71, 73, 75: ("cloud.snow.fill", "cloud.snow.fill")
        case 77: ("cloud.snow.fill", "cloud.snow.fill")
        case 80, 81, 82: ("cloud.sun.rain.fill", "cloud.moon.rain.fill")
        case 85, 86: ("cloud.snow.fill", "cloud.snow.fill")
        case 95: ("cloud.bolt.rain.fill", "cloud.bolt.rain.fill")
        case 96, 99: ("cloud.bolt.rain.fill", "cloud.bolt.rain.fill")
        default: ("questionmark", "questionmark")
        }
        return isDaylight ? symbol.day : symbol.night
    }
}
