import MapKit

//
//  SearchCityView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import SwiftUI

struct SearchCityView: View {
    @EnvironmentObject private var meteoData: MeteoData
    @ObservedObject var locationSearchService = LocationSearchService()

    @StateObject private var searchHistory = SearchHistory()
    @State private var isSearchActive = false

    func handleSearch(title: String, subtitle: String) {
        isSearchActive = false
        Task {
            let foundLocation = try await MeteoBlueAPIService()
                .getCityFromCompletion(title: title, subtitle: subtitle)
            guard let foundLocation else { return }
            await meteoData.loadMeteoData(location: foundLocation)

            searchHistory.add(foundLocation)
            locationSearchService.searchQuery = ""
        }
    }

    func handleSearch(location: WeatherLocation) {
        isSearchActive = false
        Task {
            await meteoData.loadMeteoData(location: location)

            searchHistory.add(location)
            locationSearchService.searchQuery = ""
        }
    }

    func deleteFromHistory(at offsets: IndexSet) {
        searchHistory.remove(at: offsets)
    }

    var body: some View {
        Button {
            isSearchActive.toggle()
        } label: {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.blue)
        }
        .sheet(
            isPresented: $isSearchActive,
            onDismiss: {
                isSearchActive = false
                locationSearchService.searchQuery = ""
            }
        ) {
            NavigationStack {
                Form {
                    if !searchHistory.items.isEmpty && locationSearchService.searchQuery.isEmpty {
                        Section("search.history") {
                            List {
                                ForEach(searchHistory.items) { location in
                                    Button {
                                        handleSearch(
                                            location: location
                                        )
                                    } label: {
                                        VStack(alignment: .leading) {
                                            Text(location.city)
                                                .foregroundColor(.primary)
                                            Text(location.country)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .onDelete(perform: deleteFromHistory)
                            }
                        }
                    }
                }
                .navigationTitle("search.title")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $locationSearchService.searchQuery,
                    prompt: String(localized: "search.prompt")
                ) {
                    if !locationSearchService.searchQuery.isEmpty {
                        ForEach(locationSearchService.completions, id: \.self) { completion in
                            Button {
                                handleSearch(
                                    title: completion.title,
                                    subtitle: completion.subtitle
                                )
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(completion.title)
                                        .foregroundColor(.primary)
                                    Text(completion.subtitle)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    NavigationStack {
        VStack {}
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SearchCityView()
                        .environmentObject(MockMeteoData() as MeteoData)
                }
            }
    }
}
