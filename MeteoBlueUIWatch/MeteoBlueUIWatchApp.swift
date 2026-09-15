//
//  MeteoBlueUIWatchApp.swift
//  MeteoBlueUIWatch
//
//  Created by Raphaël Catarino on 15/09/2026.
//

import SwiftUI

@main
struct MeteoBlueUIWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Add the weather widget on your watch face. The app on your iPhone configures it.")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
