//
//  LocationSearchService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 14/05/2025.
//

import Combine
import MapKit
import SwiftUI

struct SearchResult: Hashable {
    let title: String
    let subtitle: String
}

class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions: [SearchResult] = []

    private var completer: MKLocalSearchCompleter
    private var cancellable: AnyCancellable?

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        cancellable = $searchQuery.assign(to: \.queryFragment, on: completer)
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results.map { SearchResult(title: $0.title, subtitle: $0.subtitle) }
    }
}
