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
        Button {
            let all = WeatherProviderType.allCases
            let index = all.firstIndex(of: current) ?? 0
            let next = all[(index + 1) % all.count]
            current = next
            WeatherProviderType.current = next
        } label: {
            switch current {
            case .meteoblue:
                Image("MeteoBlueIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            case .weatherkit:
                Image(systemName: "applelogo")
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    ProviderSwitchButton()
}
