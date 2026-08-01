//
//  ProviderIcon.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 31/07/2026.
//

import SwiftUI

struct ProviderIcon: View {
    let provider: WeatherProviderType
    var size: CGFloat = 20

    var body: some View {
        switch provider {
        case .meteoblue:
            Image("MeteoBlueIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        case .weatherkit:
            Image(systemName: "applelogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 1.1, height: size * 1.1)
                .foregroundColor(.primary)
        case .openmeteo:
            Image("OpenMeteoICon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        }
    }
}
