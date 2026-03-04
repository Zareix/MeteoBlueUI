//
//  WeatherAISummaryView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 05/03/2026.
//

import SwiftUI

struct WeatherAISummaryView: View {
    let days: [MeteoDataDay]
    let location: WeatherLocation

    @State private var aiSummary: String? = nil
    @State private var isLoadingAI: Bool = true

    private let summaryService = WeatherSummaryService()

    /// Filters the next 24 hours across the first 2 days starting from the current hour.
    private var upcomingHours: [MeteoData1H] {
        guard days.count >= 2 else { return days.first?.hourByHour ?? [] }
        let now = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month, .day, .hour], from: Date())
        ) ?? Date()
        let fromToday = days[0].hourByHour.filter { $0.time >= now }
        let needed = max(0, 24 - fromToday.count)
        return Array((fromToday + days[1].hourByHour.prefix(needed)).prefix(24))
    }

    private func generate() async {
        let hours = upcomingHours
        guard !hours.isEmpty else {
            isLoadingAI = false
            return
        }
        isLoadingAI = true
        aiSummary = nil
        aiSummary = await summaryService.generateSummary(for: hours)
        isLoadingAI = false
    }

    var body: some View {
        Group {
            if let summary = aiSummary {
                Text(summary)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
                    .animation(.easeOut, value: summary)
            } else if isLoadingAI {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Génération du résumé…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
        .task {
            await generate()
        }
        .onChange(of: location) {
            Task { await generate() }
        }
    }
}
