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
    @State private var isSheetOpen = false

    func handleClick(title: String, subtitle: String) {
        isSheetOpen = false
        Task {
            let foundLocation = try await MeteoBlueAPIService()
                .getCityFromCompletion(title: title, subtitle: subtitle)
            guard let foundLocation else { return }
            await meteoData.loadMeteoData(location: foundLocation)
        }
    }

    func addCurrent() {
        guard let location = meteoData.location else { return }
        favorites.add(
            FavoriteCitiesItem(
                title: location.city,
                subtitle: location.country
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
        guard let location = meteoData.location else { return false }
        return favorites.items.contains(
            FavoriteCitiesItem(
                title: location.city,
                subtitle: location.country
            )
        )
    }

    var body: some View {
        Button {
            isSheetOpen.toggle()
        } label: {
            Image(
                systemName:
                    isCurrentCityFavorite() ? "star.fill" : "star"
            )
            .foregroundColor(.blue)
        }
        .sheet(
            isPresented: $isSheetOpen,
            onDismiss: {
                isSheetOpen = false
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
