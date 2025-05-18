import Charts
//
//  PrecipitationChartView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 18/05/2025.
//
import SwiftUI

struct PrecipitationChartView: View {
    var day: MeteoDataDay

    private var now: Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents(
            [.year, .month, .day, .hour],
            from: Date()
        )
        return calendar.date(from: comps) ?? Date()
    }

    private var pastHours: [MeteoData1H] {
        day.hourByHour.filter { $0.time <= now }
    }

    private var futureHours: [MeteoData1H] {
        day.hourByHour.filter { $0.time >= now }
    }

    private var axisHours: [Date] {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: day.time)
        return [0, 6, 12, 18].compactMap { hour in
            calendar.date(
                bySettingHour: hour,
                minute: 0,
                second: 0,
                of: baseDate
            )
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("day-details.precipitation")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            HStack {
                Text(
                    "day-details.precipitation-risk-today-\(day.time.formatted(.dateTime.weekday(.wide)))-\(day.precipitationProbability)"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                Spacer()
            }

            Chart {
                if !pastHours.isEmpty {
                    ForEach(pastHours, id: \.time) { hourData in
                        LineMark(
                            x: .value("hour", hourData.time, unit: .hour),
                            y: .value(
                                "day-details.precipitation-percent",
                                hourData.precipitationProbability
                            ),
                            series: .value("Series", "Previous")
                        )
                        .foregroundStyle(.gray.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 3, dash: [8, 4]))
                        .interpolationMethod(.catmullRom)
                    }
                }

                if !futureHours.isEmpty {
                    ForEach(futureHours, id: \.time) { hourData in
                        LineMark(
                            x: .value("hour", hourData.time, unit: .hour),
                            y: .value(
                                "day-details.precipitation-percent",
                                hourData.precipitationProbability,
                            ),
                            series: .value("Series", "Future")
                        )
                        .foregroundStyle(
                            .cyan
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: axisHours) { value in
                    AxisGridLine()
                    AxisValueLabel(
                        format: .dateTime.hour(
                            .defaultDigits(amPM: .abbreviated)
                        )
                    )
                }
            }
            .chartYAxis {
                AxisMarks(
                    values: stride(from: 0, to: 110, by: 20).map { $0 }
                ) { value in
                    AxisGridLine()
                    AxisTick()
                    if let y = value.as(Double.self) {
                        AxisValueLabel("\(Int(y))%")
                    }
                }
            }
            .chartYScale(domain: 0...110)
            .frame(height: 200)
            .clipped()
            .padding()
        }

    }
}

// MARK: - Preview
#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()
    @Previewable @StateObject var locationManager = LocationManager()

    @Previewable @State var open: Bool = true

    if let city = locationManager.city {
        ZStack {
            if let firstDay = mockData.dayByDay.first {
                VStack {
                    PrecipitationChartView(
                        day: firstDay
                    )
                }
                .padding(.horizontal, 16)
            }
        }.task {
            await mockData.loadMeteoData(city: city)
        }
    } else {
        ProgressView()
    }
}
