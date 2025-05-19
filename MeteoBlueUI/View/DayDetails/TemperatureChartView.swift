import Charts
//
//  TemperatureChartView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 18/05/2025.
//
import SwiftUI

struct TemperatureChartView: View {
    let day: MeteoDataDay

    @EnvironmentObject private var meteoData: MeteoData

    @State private var selectedHour: MeteoData1H?
    @State private var selectedX: CGFloat?

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

    private var yMin: Double {
        round((day.hourByHour.map { $0.temperature }.min() ?? 0)) - 2
    }

    private var yMax: Double {
        floor((day.hourByHour.map { $0.temperature }.max() ?? 0)) + 2.5
    }

    var body: some View {
        VStack {

            if let selected = selectedHour, let x = selectedX {
                HStack {
                    Spacer().frame(
                        width:
                            x < 14
                            ? 14
                            : x - 14
                    )
                    VStack(
                        alignment:
                            x < 14
                            ? .leading
                            : .center,
                        spacing: 0
                    ) {
                        HStack {
                            Image(systemName: selected.symbol)
                                .symbolRenderingMode(.multicolor)
                                .shadow(
                                    color: .secondary.opacity(0.3),
                                    radius: 8
                                )
                                .font(.system(size: 24))
                                .frame(width: 24)
                            Text("\(Int(round(selected.temperature)))°")
                                .font(.body)
                                .fontWeight(.bold)
                                .padding(6)
                                .cornerRadius(8)
                        }
                        Text(
                            selected.time.formatted(
                                .dateTime
                                    .hour(
                                        .defaultDigits(amPM: .abbreviated)
                                    )
                            )
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 24)
                    Spacer()
                }
                .frame(height: 52)
            } else {
                VStack {
                    if day == meteoData.dayByDay.first {
                        HStack {
                            Text(
                                "\(Int(round(day.temperatureMean)))°"
                            )
                            .font(.title)
                            Image(systemName: day.symbol)
                                .symbolRenderingMode(.multicolor)
                                .shadow(
                                    color: .secondary.opacity(0.3),
                                    radius: 8
                                )
                                .font(.system(size: 24))
                                .frame(width: 24)
                            Spacer()
                        }
                        HStack {
                            HStack(spacing: 0) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                Text(
                                    "\(Int(round(day.temperatureMax)))°"
                                )
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            }
                            HStack(spacing: 0) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text(
                                    "\(Int(round(day.temperatureMin)))°"
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    } else {
                        HStack {
                            HStack(spacing: 4) {
                                Text(
                                    "\(Int(round(day.temperatureMax)))°"
                                )
                                .font(.system(size: 24))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                Text(
                                    "\(Int(round(day.temperatureMin)))°"
                                )
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                                Image(systemName: day.symbol)
                                    .symbolRenderingMode(.multicolor)
                                    .shadow(
                                        color: .secondary.opacity(0.3),
                                        radius: 8
                                    )
                                    .font(.system(size: 24))
                                    .frame(width: 24)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .frame(height: 52)
            }

            Chart {
                if yMin < 0 && yMax > 0 {
                    RuleMark(y: .value("day-details.temperature", 0))
                        .foregroundStyle(.blue.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }

                if selectedHour == nil {
                    ForEach(
                        day.hourByHour.enumerated().filter { $0.offset % 2 == 0 }
                            .map { $0.element },
                        id: \.self
                    ) {
                        hour in
                        RuleMark(
                            x: .value("hour", hour.time, unit: .hour)
                        )
                        .foregroundStyle(.clear)
                        .annotation(position: .top) {
                            Image(systemName: hour.symbol)
                                .symbolRenderingMode(.multicolor)
                                .shadow(
                                    color: .secondary.opacity(0.6),
                                    radius: 8
                                )
                                .font(.system(size: 12))
                        }
                    }
                }

                if !pastHours.isEmpty {
                    ForEach(pastHours, id: \.time) { hourData in
                        LineMark(
                            x: .value("hour", hourData.time, unit: .hour),
                            y: .value(
                                "day-details.temperature",
                                hourData.temperature
                            ),
                            series: .value("Series", "Previous")
                        )
                        .foregroundStyle(.gray.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 3, dash: [8, 4]))
                        .interpolationMethod(.catmullRom)
                        if hourData.temperature == day.temperatureMax {
                            PointMark(
                                x: .value("hour", hourData.time, unit: .hour),
                                y: .value(
                                    "day-details.temperature",
                                    hourData.temperature
                                )
                            )
                            .foregroundStyle(.orange.opacity(0.3))
                            .annotation(position: .top) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 12))
                                    .fontWeight(.bold)
                                    .foregroundColor(.red.opacity(0.3))
                            }
                        } else if hourData.temperature == day.temperatureMin {
                            PointMark(
                                x: .value("hour", hourData.time, unit: .hour),
                                y: .value(
                                    "day-details.temperature",
                                    hourData.temperature
                                )
                            )
                            .foregroundStyle(.blue.opacity(0.3))
                            .annotation(position: .bottom) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 12))
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue.opacity(0.3))
                            }
                        }
                    }
                }

                if !futureHours.isEmpty {
                    ForEach(futureHours, id: \.time) { hourData in
                        LineMark(
                            x: .value("hour", hourData.time, unit: .hour),
                            y: .value(
                                "day-details.temperature",
                                hourData.temperature,
                            ),
                            series: .value("Series", "Future")
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .cyan, location: 0),
                                    .init(color: .yellow, location: 1),
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.catmullRom)
                        if hourData.temperature == day.temperatureMax {
                            PointMark(
                                x: .value("hour", hourData.time, unit: .hour),
                                y: .value(
                                    "day-details.temperature",
                                    hourData.temperature
                                )
                            )
                            .foregroundStyle(.orange)
                            .annotation(position: .top) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 12))
                                    .fontWeight(.bold)
                                    .foregroundColor(.red.opacity(0.7))
                            }
                        } else if hourData.temperature == day.temperatureMin {
                            PointMark(
                                x: .value("hour", hourData.time, unit: .hour),
                                y: .value(
                                    "day-details.temperature",
                                    hourData.temperature
                                )
                            )
                            .foregroundStyle(.blue)
                            .annotation(position: .bottom) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 12))
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue.opacity(0.7))
                            }
                        }
                    }
                }
                if let selected = selectedHour {
                    RuleMark(x: .value("hour", selected.time))
                        .foregroundStyle(.gray.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 2))
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
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    if let y = value.as(Double.self) {
                        AxisValueLabel("\(Int(y))°")
                    }
                }
            }
            .chartYScale(domain: yMin...yMax)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let xPos =
                                        value.location.x
                                        - geo[proxy.plotFrame!].origin.x
                                    if let date: Date = proxy.value(
                                        atX: xPos
                                    ) {
                                        if let nearest = day.hourByHour.min(
                                            by: {
                                                abs(
                                                    $0.time
                                                        .timeIntervalSince(
                                                            date
                                                        )
                                                )
                                                    < abs(
                                                        $1.time
                                                            .timeIntervalSince(
                                                                date
                                                            )
                                                    )
                                            }
                                        ) {
                                            selectedHour = nearest
                                            if let x = proxy.position(
                                                forX: nearest.time
                                            ) {
                                                selectedX =
                                                    x
                                                    + geo[proxy.plotFrame!]
                                                    .origin.x
                                            } else {
                                                selectedX = nil
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    selectedHour = nil
                                }
                        )
                }
            }
            .frame(height: 200)
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
            if mockData.dayByDay.count > 1 {
                VStack {
                    TemperatureChartView(
                        day: mockData.dayByDay[1]
                    )
                    .environmentObject(mockData as MeteoData)
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
