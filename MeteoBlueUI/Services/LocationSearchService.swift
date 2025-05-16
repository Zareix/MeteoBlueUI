//
//  LocationSearchService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 14/05/2025.
//

import SwiftUI
import MapKit
import Combine

class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions: [MKLocalSearchCompletion] = []

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
        self.completions = completer.results
    }
}
