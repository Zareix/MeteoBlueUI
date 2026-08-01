//
//  ProviderSelectionIntent.swift
//  MeteoBlueWidget
//
//  Created by Raphaël Catarino on 01/08/2026.
//

import AppIntents
import WidgetKit

enum WidgetProviderChoice: String, AppEnum {
    case sameAsApp
    case meteoblue
    case weatherkit
    case openmeteo

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Weather Provider"
    static var caseDisplayRepresentations: [WidgetProviderChoice: DisplayRepresentation] = [
        .sameAsApp: "Same as App",
        .meteoblue: "MeteoBlue",
        .weatherkit: "Apple Weather",
        .openmeteo: "Open-Meteo",
    ]

    var resolvedType: WeatherProviderType {
        switch self {
        case .sameAsApp: WeatherProviderType.current
        case .meteoblue: .meteoblue
        case .weatherkit: .weatherkit
        case .openmeteo: .openmeteo
        }
    }
}

struct SelectProviderIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Weather Provider"
    static var description = IntentDescription("Choose which weather source powers this widget.")

    @Parameter(title: "Provider", default: .openmeteo)
    var provider: WidgetProviderChoice
}
