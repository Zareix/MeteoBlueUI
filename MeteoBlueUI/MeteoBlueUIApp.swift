//
//  MeteoBlueUIApp.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import SwiftUI
import UIKit

@main
struct MeteoBlueUIApp: App {
    @State private var locationManager = LocationManager()
    @State private var meteoData = MeteoData()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(meteoData)
                    .environmentObject(locationManager)
            }
            .appBackground()
            .onReceive(
                NotificationCenter.default.publisher(for: WeatherProviderType.didChangeNotification)
                    .merge(with: NotificationCenter.default.publisher(for: KeychainService.didChangeNotification))
            ) { _ in
                meteoData.setProvider(MeteoData.makeDefaultProvider())
                Task {
                    if let location = meteoData.location {
                        await meteoData.loadMeteoData(force: true, location: location)
                    }
                }
            }
        }
    }
}
