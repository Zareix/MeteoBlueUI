//
//  PictoMapper.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 16/05/2025.
//

struct PictoMapper {
    static func pictoToDescription(picto: Int) -> String {
        return switch picto {
        case 1: "Clair, ciel sans nuage"
        case 2: "Clair, quelques cirrus"
        case 3: "Clair avec cirrus"
        case 4: "Clair avec quelques nuages bas"
        case 5: "Clair avec quelques nuages bas et quelques cirrus"
        case 6: "Clair avec quelques nuages bas et cirrus"
        case 7: "Partiellement nuageux"
        case 8: "Partiellement nuageux et quelques cirrus"
        case 9: "Partiellement nuageux et cirrus"
        case 10: "Variable avec quelques nuages d'orage possibles"
        case 11:
            "Variable avec quelques cirrus et quelques nuages d'orage possibles"
        case 12: "Variable avec cirrus et quelques nuages d'orage possibles"
        case 13: "Ciel clair mais brumeux"
        case 14: "Ciel clair mais brumeux avec quelques cirrus"
        case 15: "Ciel clair mais brumeux avec cirrus"
        case 16: "Brouillard/Stratus bas"
        case 17: "Brouillard/Stratus bas avec quelques cirrus"
        case 18: "Brouillard/Stratus bas avec cirrus"
        case 19: "Partiellement nuageux"
        case 20: "Partiellement nuageux avec quelques cirrus"
        case 21: "Partiellement nuageux avec quelques cirrus"
        case 22: "Ciel couvert"
        case 23: "Couvert avec pluie"
        case 24: "Couvert avec chutes de neige"
        case 25: "Couvert avec fortes pluies"
        case 26: "Couvert avec fortes chutes de neige"
        case 27: "Pluie, orages probables"
        case 28: "Pluies éparses, orages probables"
        case 29: "Tempête avec fortes chutes de neige"
        case 30: "Fortes pluies, orages probables"
        case 31: "Variable avec risques d'averses"
        case 32: "Ciel variable avec des averses de neige"
        case 33: "Couvert avec pluie légère"
        case 34: "Couvert avec neige légère"
        case 35: "Couvert avec un mélange de pluie et neige"
        default: "Inconnu"
        }
    }

    static func pictoToSFSymbol(picto: Int, isDaylight: Bool) -> String {
        let symbol =
            switch picto {
            case 1: ("sun.max.fill", "moon.fill")
            case 2: ("sun.max.fill", "moon.fill")
            case 3: ("sun.max.fill", "moon.fill")
            case 4: ("cloud.sun.fill", "cloud.moon.fill")
            case 5: ("cloud.sun.fill", "cloud.moon.fill")
            case 6: ("cloud.sun.fill", "cloud.moon.fill")
            case 7: ("cloud.sun.fill", "cloud.moon.fill")
            case 8: ("cloud.sun.fill", "cloud.moon.fill")
            case 9: ("cloud.sun.fill", "cloud.moon.fill")
            case 10: ("cloud.sun.fill", "cloud.moon.fill")
            case 11: ("cloud.sun.fill", "cloud.moon.fill")
            case 12: ("cloud.sun.fill", "cloud.moon.fill")
            case 13: ("sun.max.fill", "moon.fill")
            case 14: ("sun.max.fill", "moon.fill")
            case 15: ("sun.max.fill", "moon.fill")
            case 16: ("cloud.fog.fill", "cloud.fog.fill")
            case 17: ("cloud.fog.fill", "cloud.fog.fill")
            case 18: ("cloud.fog.fill", "cloud.fog.fill")
            case 19: ("cloud.sun.fill", "cloud.moon.fill")
            case 20: ("cloud.sun.fill", "cloud.moon.fill")
            case 21: ("cloud.sun.fill", "cloud.moon.fill")
            case 22: ("cloud.fill", "cloud.fill")
            case 23: ("cloud.rain.fill", "cloud.rain.fill")
            case 24: ("cloud.snow.fill", "cloud.snow.fill")
            case 25: ("cloud.heavyrain.fill", "cloud.heavyrain.fill")
            case 26: ("cloud.snow.fill", "cloud.snow.fill")
            case 27: ("cloud.sun.bolt.fill", "cloud.moon.bolt.fill")
            case 28: ("cloud.sun.bolt.fill", "cloud.moon.bolt.fill")
            case 29: ("cloud.snow.fill", "cloud.snow.fill")
            case 30: ("cloud.sun.bolt.fill", "cloud.moon.bolt.fill")
            case 31: ("cloud.sun.rain.fill", "cloud.moon.rain.fill")
            case 32: ("sun.snow.fill", "snow.fill")
            case 33: ("cloud.rain.fill", "cloud.rain.fill")
            case 34: ("cloud.snow.fill", "cloud.snow.fill")
            case 35: ("cloud.rain.fill", "cloud.rain.fill")
            default: ("questionmark", "questionmark")
            }

        return isDaylight ? symbol.0 : symbol.1
    }

    static func pictoIdayToDescription(picto: Int) -> String {
        return switch picto {
        case 1: "Ensoleillé sans nuage"
        case 2: "Ensoleillé avec quelques nuages"
        case 3: "Partiellement nuageux"
        case 4: "Ciel couvert"
        case 5: "Brouillard"
        case 6: "Couvert avec pluie"
        case 7: "Variable avec risques d'averses"
        case 8: "Averses avec orages probables"
        case 9: "Couvert avec chutes de neige"
        case 10: "Ciel variable avec des averses de neige"
        case 11: "Partiellement nuageux avec mélange de neige et de pluie"
        case 12: "Couvert avec pluie légère"
        case 13: "Couvert avec neige légère"
        case 14: "Partiellement nuageux avec pluie"
        case 15: "Partiellement nuageux avec neige"
        case 16: "Partiellement nuageux avec pluies éparses"
        case 17: "Partiellement nuageux avec chutes de neiges éparses"
        default: "Inconnu"
        }
    }

    static func pictoIdayToSFSymbol(picto: Int) -> String {
        return switch picto {
        case 1: "sun.max.fill"
        case 2: "cloud.sun.fill"
        case 3: "cloud.sun.fill"
        case 4: "cloud.fill"
        case 5: "cloud.fog.fill"
        case 6: "cloud.rain.fill"
        case 7: "cloud.sun.rain.fill"
        case 8: "cloud.sun.bolt.fill"
        case 9: "cloud.snow.fill"
        case 10: "cloud.snow.fill"
        case 11: "cloud.sun.rain.fill"
        case 12: "cloud.rain.fill"
        case 13: "cloud.snow.fill"
        case 14: "cloud.sun.rain.fill"
        case 15: "cloud.snow.fill"
        case 16: "cloud.sun.rain.fill"
        case 17: "cloud.snow.fill"
        default: "questionmark"
        }
    }
}
