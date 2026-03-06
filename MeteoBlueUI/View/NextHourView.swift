//
//  NextHour.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 06/03/2026.
//

import SwiftUI

struct NextHourView: View {
    let nextHour: [MeteoData15Min]

    var body: some View {
        VStack {
            Text("nexthour.title")
                .font(.title.bold())
                .fontDesign(.serif)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
        }
    }
}

#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()
    let defaultLocation = LocationManager.defaultLocation()

    VStack {
        if !mockData.nextHour.isEmpty {
            NextHourView(
                nextHour: mockData.nextHour
            )
            .appBackground()
        } else {
            ProgressView()
        }
    }.task {
        await mockData.loadMeteoData(location: defaultLocation, isCurrentLocation: true)
    }
}
