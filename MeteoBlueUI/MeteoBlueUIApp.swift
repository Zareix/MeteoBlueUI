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

    @State private var showSheet =
        KeychainService().getMetoBlueAPIToken() == nil
    @State private var apiToken: String = ""

    func saveToKeychain() {
        KeychainService().setMetoBlueAPIToken(token: apiToken)
        showSheet = false
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !showSheet {
                    ContentView()
                        .environmentObject(meteoData)
                        .environmentObject(locationManager)
                } else {
                    VStack {
                        ProgressView()
                    }.sheet(isPresented: $showSheet) {
                        VStack(spacing: 8) {
                            Text("Enter your MeteoBlue API token")
                                .font(.headline)
                                .padding()
                            SecureField("API Token", text: $apiToken)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            Button("Save") {
                                saveToKeychain()
                            }
                            .padding()
                        }
                    }
                }
            }
            .appBackground()
        }
    }
}
