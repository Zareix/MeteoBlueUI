//
//  SearchHistory.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 15/05/2025.
//

import Combine
import Foundation

class SearchHistory: ObservableObject {
    private static let maxHistoryCount = 5
    private let storageKey = "searchHistory"
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
        let limited = Array(items.prefix(Self.maxHistoryCount))
        if let data = try? JSONEncoder().encode(limited) {
            UserDefaults.standard.set(data, forKey: storageKey)
            items = limited
        }
    }

    func add(_ item: WeatherLocation) {
        if items.contains(item) {
            items.removeAll(where: { $0 == item })
        }
        items.insert(item, at: 0)
        save()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }
}
