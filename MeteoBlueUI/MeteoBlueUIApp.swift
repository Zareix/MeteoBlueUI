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
    @StateObject private var locationManager = LocationManager()
    @StateObject private var meteoData: MeteoData
    @State private var showSheet =
    KeychainService().getMetoBlueAPIToken() == nil
    @State private var apiToken: String = ""
    
    init() {
        let service = MeteoBlueAPIService()
        _meteoData = StateObject(wrappedValue: MeteoData(service: service))
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                if !showSheet {
                    if locationManager.city != nil {
                        ContentView()
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
}
