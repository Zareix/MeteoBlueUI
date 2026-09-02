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

    /// Timestep between entries, inferred from the data: 5 min (MeteoBlue, WeatherKit)
    /// or 15 min (Open-Meteo's nowcast).
    private var stepSeconds: TimeInterval {
        guard nextHour.count > 1 else { return 5 * 60 }
        let diff = nextHour[1].time.timeIntervalSince(nextHour[0].time)
        return diff > 0 ? diff : 5 * 60
    }

    /// 15-minute buckets (radar nowcast) cover two hours; 5-minute data covers one.
    private var windowSeconds: TimeInterval {
        stepSeconds > 5 * 60 ? 2 * 60 * 60 : 60 * 60
    }

    private var thisNextHour: [MeteoData5Min] {
        Array(nextHour.prefix(Int(windowSeconds / stepSeconds)))
    }

    private var maxPrecipitation: Double {
        thisNextHour.map(\.precipitation).max() ?? 1
    }

    private var yMax: Double {
        max(maxPrecipitation * 1.2, 0.5)
    }

    private var yStride: Double {
        switch yMax {
        case ..<1: 0.25
        case ..<2.5: 0.5
        case ..<6: 1
        default: 2
        }
    }

    private var hasPrecipitation: Bool {
        thisNextHour.contains { $0.precipitation > 0 }
    }

    private var startTime: Date {
        thisNextHour.first?.time ?? Date()
    }

    private var axisStrideMinutes: Int {
        windowSeconds > 60 * 60 ? 30 : 10
    }

    private var axisDates: [Date] {
        stride(
            from: 0,
            through: Int(windowSeconds / 60) - axisStrideMinutes,
            by: axisStrideMinutes
        )
        .map { startTime.addingTimeInterval(TimeInterval($0 * 60)) }
    }

    private func axisLabel(for date: Date) -> String {
        let minutes = Int(date.timeIntervalSince(startTime).rounded() / 60)
        switch minutes {
        case ...0: return ""
        case ..<60: return "\(minutes)min"
        default:
            let hours = minutes / 60
            let remainder = minutes % 60
            return remainder == 0 ? "\(hours)h" : "\(hours)h\(remainder)"
        }
    }

    var body: some View {
        if hasPrecipitation {
            let titleKey: LocalizedStringKey = stepSeconds > 5 * 60 ? "nexthour.title2h" : "nexthour.title"
            VStack(alignment: .leading, spacing: 12) {
                Text(titleKey)
                    .font(.title.bold())
                    .fontDesign(.serif)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Chart {
                    ForEach(thisNextHour, id: \.time) { hourData in
                        RectangleMark(
                            xStart: .value("hour", hourData.time, unit: .minute),
                            xEnd: .value(
                                "hour-end",
                                hourData.time.addingTimeInterval(stepSeconds - 61),
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
                            AxisValueLabel(axisLabel(for: date), anchor: .top)
                        }
                    }
                }
                .chartXScale(
                    domain: startTime ... startTime.addingTimeInterval(windowSeconds)
                )
                .chartYAxis {
                    AxisMarks(values: Array(stride(from: 0, through: yMax, by: yStride))) { value in
                        AxisGridLine()
                        AxisTick()
                        if let y = value.as(Double.self) {
                            AxisValueLabel("\(y, specifier: "%.2g") mm")
                        }
                    }
                }
                .chartYScale(domain: 0 ... yMax, type: .linear)
                .frame(height: 150)
            }
        }
    }
}

// MARK: - Preview

private func previewNextHour(stepMinutes: Int, amounts: [Double]) -> [MeteoData5Min] {
    let now = Date()
    let calendar = Calendar.current
    let currentMinute = calendar.component(.minute, from: now)
    let alignedMinute = currentMinute - (currentMinute % stepMinutes)
    let start = calendar.date(
        bySettingHour: calendar.component(.hour, from: now),
        minute: alignedMinute,
        second: 0,
        of: now
    ) ?? now

    return amounts.enumerated().map { index, amount in
        MeteoData5Min(
            time: start.addingTimeInterval(TimeInterval(index * stepMinutes * 60)),
            precipitation: amount
        )
    }
}

#Preview("15 min · 2 h (OpenMeteo)") {
    VStack {
        NextHourView(
            nextHour: previewNextHour(
                stepMinutes: 15,
                amounts: [0, 0.1, 0.4, 0.9, 0.7, 0.2, 0, 0]
            )
        )
        .padding(16)
        .appBackground()
    }
}

#Preview("5 min · 1 h (MeteoBlue / WeatherKit)") {
    VStack {
        NextHourView(
            nextHour: previewNextHour(
                stepMinutes: 5,
                amounts: [0.1, 0.15, 0.25, 0.4, 0.3, 0.1, 0, 0.05, 0.2, 0.3, 0.15, 0.05]
            )
        )
        .padding(16)
        .appBackground()
    }
}
