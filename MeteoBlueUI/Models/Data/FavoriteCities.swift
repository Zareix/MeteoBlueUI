//
//  FavoriteCities.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 15/05/2025.
//

import Combine
import Foundation

class FavoriteCities: ObservableObject {
    private let storageKey = "favoriteCities"
    @Published var items: [WeatherLocation] = []

    init() {
        load()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([WeatherLocation].self, from: data)
        {
            items = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
            items = items
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func add(_ item: WeatherLocation) {
        if items.contains(item) {
            return
        }
        items.insert(item, at: 0)
        save()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }
}
