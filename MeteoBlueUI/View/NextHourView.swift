//
//  NextHour.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 06/03/2026.
//

import Charts
import SwiftUI

struct NextHourView: View {
    let nextHour: [MeteoData5Min]

    private var thisNextHour: [MeteoData5Min] {
        Array(nextHour.prefix(12))
    }

    private var maxPrecipitation: Double {
        thisNextHour.map(\.precipitation).max() ?? 1
    }

    private var yMax: Double {
        max(maxPrecipitation * 1.2, 2)
    }

    private var hasPrecipitation: Bool {
        thisNextHour.contains { $0.precipitation > 0 }
    }

    private var startTime: Date {
        thisNextHour.first?.time ?? Date()
    }

    private var axisDates: [Date] {
        stride(from: 0, through: 50, by: 10).map {
            startTime.addingTimeInterval(TimeInterval($0 * 60))
        }
    }

    private func axisLabel(for date: Date) -> String {
        let minutes = Int(date.timeIntervalSince(startTime).rounded() / 60)
        return minutes == 0 ? "" : "\(minutes)min"
    }

    var body: some View {
        if hasPrecipitation {
            VStack(alignment: .leading, spacing: 12) {
                Text("nexthour.title")
                    .font(.title.bold())
                    .fontDesign(.serif)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Chart {
                    ForEach(thisNextHour, id: \.time) { hourData in
                        RectangleMark(
                            xStart: .value("hour", hourData.time, unit: .minute),
                            xEnd: .value(
                                "hour-end",
                                hourData.time.addingTimeInterval(5 * 60 - 61),
                                unit: .minute
                            ),
                            yStart: .value("precipitation", 0),
                            yEnd: .value("precipitation", hourData.precipitation)
                        )
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 5))
                        .offset(x: 2)
                        .foregroundStyle(.cyan)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: axisDates) { value in
                        AxisGridLine()
                        if let date = value.as(Date.self) {
                            AxisValueLabel(axisLabel(for: date))
                        }
                    }
                }
                .chartXScale(
                    domain: startTime ... startTime.addingTimeInterval(60 * 60)
                )
                .chartYAxis {
                    AxisMarks(values: Array(stride(from: 0, to: yMax, by: 0.5))) { value in
                        AxisGridLine()
                        AxisTick()
                        if let y = value.as(Double.self) {
                            AxisValueLabel("\(y, specifier: "%.1f") mm")
                        }
                    }
                }
                .chartYScale(domain: 0 ... yMax, type: .linear)
                .frame(height: 150)
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()
    let defaultLocation = LocationManager.defaultLocation()

    VStack {
        NextHourView(
            nextHour: mockData.nextHour
        )
        .padding(16)
        .appBackground()
    }.task {
        await mockData.loadMeteoData(location: defaultLocation, isCurrentLocation: true)
    }
}
