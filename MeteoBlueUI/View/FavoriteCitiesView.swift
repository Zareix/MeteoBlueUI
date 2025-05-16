import MapKit
//
//  FavoriteCitiesView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import SwiftUI

struct FavoriteCitiesView: View {
    @EnvironmentObject private var meteoData: MeteoData

    @StateObject private var favorites = FavoriteCities()
    @State private var isSearchActive = false

    func handleClick(title: String, subtitle: String) {
        isSearchActive = false
        Task {
            let foundCity = try await MeteoBlueAPIService()
                .getCityFromCompletion(title: title, subtitle: subtitle)
            if foundCity == nil {
                return
            }
            await meteoData.loadMeteoData(city: foundCity!)

            favorites.add(
                FavoriteCitiesItem(title: title, subtitle: subtitle)
            )
        }
    }

    func addCurrent() {
        guard let city = meteoData.city
        else {
            return
        }
        favorites.add(
            FavoriteCitiesItem(
                title: city.placemark.locality ?? "",
                subtitle: city.placemark.country ?? ""
            )
        )
    }

    func deleteFromFavorite(at offsets: IndexSet) {
        favorites.remove(at: offsets)
    }

    func moveFavorite(from: IndexSet, to: Int) {
        favorites.move(from: from, to: to)
    }

    func isCurrentCityFavorite() -> Bool {
        guard let city = meteoData.city else {
            return false
        }
        return favorites.items.contains(
            FavoriteCitiesItem(
                title: city.placemark.locality ?? "",
                subtitle: city.placemark.country ?? ""
            )
        )
    }

    var body: some View {
        Button {
            isSearchActive.toggle()
        } label: {
            Image(
                systemName:
                    isCurrentCityFavorite() ? "star.fill" : "star"
            )
            .foregroundColor(.blue)
        }
        .sheet(
            isPresented: $isSearchActive,
            onDismiss: {
                isSearchActive = false
            }
        ) {
            NavigationStack {
                VStack {
                    if !favorites.items.isEmpty {
                        Section {
                            List {
                                ForEach(favorites.items) { city in
                                    Button {
                                        handleClick(
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
                                .onDelete(perform: deleteFromFavorite)
                                .onMove(perform: moveFavorite)
                            }
                        }
                    }
                }
                .padding(.top, -16)
                .navigationTitle("favorites.title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if !isCurrentCityFavorite() {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("favorites.add-current") {
                                addCurrent()
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
            ToolbarItem(placement: .topBarLeading) {
                FavoriteCitiesView()
                    .environmentObject(MockMeteoData() as MeteoData)
            }
        }
    }
}
