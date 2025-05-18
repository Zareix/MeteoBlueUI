//
//  MeteoBlueUIApp.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import SwiftUI

@main
struct MeteoBlueUIApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var meteoData = MeteoData()
    @State private var showSheet =
        KeychainService().getMetoBlueAPIToken() == nil
    @State private var apiToken: String = ""

    var body: some Scene {
        WindowGroup {
            if !showSheet {
                if locationManager.city != nil {
                    ContentView()
                        .background(
                            .thinMaterial
                        )
                        .environmentObject(meteoData)
                        .environmentObject(locationManager)
                } else {
                    ProgressView()
                }
            } else {
                VStack {
                    ProgressView()
                }.sheet(isPresented: $showSheet) {
                    VStack(spacing: 8) {
                        Text("Enter your MeteoBlue API token")
                            .font(.headline)
                            .padding()
                        TextField("API Token", text: $apiToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        Button("Save") {
                            KeychainService().setMetoBlueAPIToken(
                                token: apiToken
                            )
                            showSheet = false
                        }
                        .padding()
                    }
                }
            }
        }
    }
}
