//
//  SearchHistory.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 15/05/2025.
//

import Foundation
import Combine

struct SearchHistoryItem: Codable, Identifiable, Equatable {
    let title: String
    let subtitle: String
    var id: String { title }
    
    static func == (lhs: SearchHistoryItem, rhs: SearchHistoryItem) -> Bool {
        return lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
    }
}

class SearchHistory: ObservableObject {
    private static let maxHistoryCount = 5
    private let storageKey = "searchHistory"
    @Published var items: [SearchHistoryItem] = []

    init() {
        load()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) {
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

    func add(_ item: SearchHistoryItem) {
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
