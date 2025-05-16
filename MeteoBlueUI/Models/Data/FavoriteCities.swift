//
//  FavoriteCities.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 15/05/2025.
//

import Foundation
import Combine

struct FavoriteCitiesItem: Codable, Identifiable, Equatable {
    let title: String
    let subtitle: String
    var id: String { title }
    
    static func == (lhs: FavoriteCitiesItem, rhs: FavoriteCitiesItem) -> Bool {
        return lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
    }
}

class FavoriteCities: ObservableObject {
    private let storageKey = "favoriteCities"
    @Published var items: [FavoriteCitiesItem] = []

    init() {
        load()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([FavoriteCitiesItem].self, from: data) {
            items = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
            items = items
        }
    }

    func add(_ item: FavoriteCitiesItem) {
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
