//
//  NextHour.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 06/03/2026.
//

import Charts
import SwiftUI

struct NextHourView: View {
    let nextHour: [MeteoData15Min]

    private var maxPrecipitation: Double {
        nextHour.map(\.precipitation).max() ?? 1
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func shouldDisplay() -> Bool {
        return nextHour.contains { $0.precipitation > 0 }
    }

    var body: some View {
        if shouldDisplay() {
            VStack(alignment: .leading, spacing: 12) {
                Text("nexthour.title")
                    .font(.title.bold())
                    .fontDesign(.serif)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Chart {
                    ForEach(nextHour, id: \.time) { hourData in
                        BarMark(
                            x: .value("hour", hourData.time, unit: .minute),
                            y: .value(
                                "day-details.precipitation-mm",
                                hourData.precipitation
                            )
                        )
                        .foregroundStyle(
                            .cyan
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(
                        values: .stride(by: .minute, count: 15)
                    ) { _ in
                        AxisGridLine()
                        AxisValueLabel(
                            format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute()
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(
                        values: stride(
                            from: 0,
                            to: 22,
                            by: 5
                        ).map { $0 }
                    ) { value in
                        AxisGridLine()
                        AxisTick()
                        if let y = value.as(Double.self) {
                            AxisValueLabel("\(Int(y)) mm")
                        }
                    }
                }
                .chartYScale(
                    domain: 0 ... 22,
                    type: .linear
                )
                .frame(height: 180)
                .clipped()
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()
    let defaultLocation = LocationManager.defaultLocation()

    VStack {
        NextHourView(
            nextHour: mockData.nextHour.prefix(8).map { $0 }
        )
        .padding(16)
        .appBackground()
    }.task {
        await mockData.loadMeteoData(location: defaultLocation, isCurrentLocation: true)
    }
}
