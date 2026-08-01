//
//  ProviderSwitchButton.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 31/07/2026.
//

import SwiftUI

struct ProviderSwitchButton: View {
    @State private var current: WeatherProviderType = .current

    var body: some View {
        Menu {
            ForEach(WeatherProviderType.allCases) { provider in
                Button {
                    current = provider
                    WeatherProviderType.current = provider
                } label: {
                    Label {
                        Text(provider.titleKey)
                    } icon: {
                        ProviderIcon(provider: provider)
                    }
                }
            }
        } label: {
            ProviderIcon(provider: current)
        }
        .onReceive(NotificationCenter.default.publisher(for: WeatherProviderType.didChangeNotification)) { _ in
            current = .current
        }
    }
}

private extension WeatherProviderType {
    var titleKey: LocalizedStringKey {
        switch self {
        case .meteoblue: "settings.provider.meteoblue"
        case .weatherkit: "settings.provider.weatherkit"
        case .openmeteo: "settings.provider.openmeteo"
        }
    }
}

#Preview {
    ProviderSwitchButton()
}
