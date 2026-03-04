//
//  ContentView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import MapKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject private var meteoData: MeteoData

    @State private var displayedTemperature: Int = 0

    init() {
        let appearance = UINavigationBarAppearance()
        let largeTitleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.serif)!
            .withSymbolicTraits(.traitBold)!
        let titleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
            .withDesign(.serif)!
        appearance.largeTitleTextAttributes = [
            .font: UIFont(descriptor: largeTitleDescriptor, size: 0)
        ]
        appearance.titleTextAttributes = [
            .font: UIFont(descriptor: titleDescriptor, size: 0)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().layoutMargins.left = 20
        UINavigationBar.appearance().layoutMargins.right = 20
    }

    func areMapItemsEqual(_ item1: MKMapItem?, _ item2: MKMapItem?) -> Bool {
        guard let item1 = item1, let item2 = item2 else {
            return false
        }
        return item1.name == item2.name
            && item1.addressRepresentations?.regionName == item2.addressRepresentations?.regionName
    }

    var body: some View {
        VStack {
            if let city = meteoData.city,
               let firstDay = meteoData.dayByDay.first,
               let currentHour = firstDay.hourByHour.first(where: {
                   $0.time
                       == Calendar.current.date(
                           from: Calendar.current.dateComponents(
                               [.year, .month, .day, .hour],
                               from: Date()
                           )
                       ) ?? Date()
               })
            {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 32) {
                            CurrentWeatherView(
                                currentHour: currentHour
                            )

                            HourByHourView(days: meteoData.dayByDay)
                                .scrollEdgeEffectStyle(.hard, for: .horizontal)

                            DayByDayView(days: meteoData.dayByDay)
                        }
                        .padding(.horizontal, 20)
                    }
                    .navigationTitle(city.name ?? "Unknown Location")
                    .navigationSubtitle(city.addressRepresentations?.regionName ?? "Unknown")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            FavoriteCitiesView()
                        }
                        if let currentCity = locationManager.city {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    Task {
                                        await meteoData.loadMeteoData(
                                            city: currentCity
                                        )
                                    }
                                } label: {
                                    Image(
                                        systemName: areMapItemsEqual(
                                            locationManager.city,
                                            city
                                        ) ? "location.fill" : "location"
                                    )
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            SearchCityView()
                        }
                    }
                    .refreshable {
                        await meteoData.loadMeteoData(
                            force: true,
                            city: city
                        )
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color("BackgroundColor"))
                }

            } else if let errorMessage = meteoData.error {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                ProgressView()
                    .padding()
            }
        }
        .task {
            let city = locationManager.city ?? LocationManager.defaultMapItem()
            await meteoData.loadMeteoData(city: city)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()
    @Previewable @StateObject var locationManager = LocationManager()

    let defaultCity = LocationManager.defaultMapItem()

    ContentView()
        .environmentObject(mockData as MeteoData)
        .environmentObject(locationManager)
        .appBackground()
        .task {
            await mockData.loadMeteoData(city: defaultCity)
        }
}
