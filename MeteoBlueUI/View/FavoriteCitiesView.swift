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

    func handleClick(location: WeatherLocation) {
        isSheetOpen = false
        Task {
            await meteoData.loadMeteoData(location: location)
        }
    }

    func addCurrent() {
        guard let location = meteoData.location else { return }
        favorites.add(location)
    }

    func deleteFromFavorite(at offsets: IndexSet) {
        favorites.remove(at: offsets)
    }

    func moveFavorite(from: IndexSet, to: Int) {
        favorites.move(from: from, to: to)
    }

    func isCurrentCityFavorite() -> Bool {
        guard let location = meteoData.location else { return false }
        return favorites.items.contains(location)
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
                                ForEach(favorites.items) { location in
                                    Button {
                                        handleClick(location: location)
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
    @Previewable @State var mock = MockMeteoData()
    NavigationStack {
        VStack {}
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    FavoriteCitiesView()
                        .environmentObject(mock as MeteoData)
                        .task {
                            await mock.loadMeteoData()
                        }
                }
            }
    }
}
