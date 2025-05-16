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

    func handleSave(title: String, subtitle: String) {
        isSearchActive = false
        Task {
            let foundCity = try await MeteoBlueAPIService()
                .getCityFromCompletion(title: title, subtitle: subtitle)
            if foundCity == nil {
                return
            }
            await meteoData.loadMeteoData(city: foundCity!)

            searchHistory.add(
                SearchHistoryItem(title: title, subtitle: subtitle)
            )

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
                    if !searchHistory.items.isEmpty {
                        Section("search.history") {
                            List(searchHistory.items) { city in
                                Button {
                                    handleSave(
                                        title: city.title,
                                        subtitle: city.subtitle
                                    )
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(city.title)
                                            .foregroundColor(.primary)
                                        Text(city.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
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
                    ForEach($locationSearchService.completions, id: \.title) {
                        $completion in
                        Button {
                            handleSave(
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
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    NavigationStack {
        VStack {

        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SearchCityView()
                    .environmentObject(MockMeteoData() as MeteoData)
            }
        }
    }
}
