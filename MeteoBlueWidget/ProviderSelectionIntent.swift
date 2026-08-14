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

enum WidgetLocationChoice: String, AppEnum {
    case currentLocation
    case favorite

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Location"
    static var caseDisplayRepresentations: [WidgetLocationChoice: DisplayRepresentation] = [
        .currentLocation: "Current Location",
        .favorite: "Favorite",
    ]
}

struct FavoriteLocationEntity: AppEntity {
    let id: String
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Favorite City"
    static var defaultQuery = FavoriteLocationQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(city)", subtitle: "\(country)")
    }

    var weatherLocation: WeatherLocation {
        WeatherLocation(city: city, country: country, latitude: latitude, longitude: longitude)
    }

    init(location: WeatherLocation) {
        id = location.id
        city = location.city
        country = location.country
        latitude = location.latitude
        longitude = location.longitude
    }
}

struct FavoriteLocationQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FavoriteLocationEntity] {
        FavoriteCities().items
            .filter { identifiers.contains($0.id) }
            .map(FavoriteLocationEntity.init(location:))
    }

    func suggestedEntities() async throws -> [FavoriteLocationEntity] {
        FavoriteCities().items.map(FavoriteLocationEntity.init(location:))
    }
}

struct SelectProviderIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Settings"
    static var description = IntentDescription("Choose which weather source and location power this widget.")

    @Parameter(title: "Provider", default: .openmeteo)
    var provider: WidgetProviderChoice

    @Parameter(title: "Location", default: .currentLocation)
    var locationSource: WidgetLocationChoice

    @Parameter(title: "Favorite City")
    var favorite: FavoriteLocationEntity?

    static var parameterSummary: some ParameterSummary {
        When(\.$locationSource, .equalTo, WidgetLocationChoice.favorite) {
            Summary("Show \(\.$provider) for \(\.$locationSource): \(\.$favorite)")
        } otherwise: {
            Summary("Show \(\.$provider) for \(\.$locationSource)")
        }
    }
}
