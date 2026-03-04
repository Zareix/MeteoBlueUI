//
//  DayByDayView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import SwiftUI

struct DayByDayView: View {
    let days: [MeteoDataDay]

    @State private var selectedDescription = ""
    @State private var selectedItem: MeteoDataDay?

    private func roundToNearest5(_ value: Int) -> Int {
        return 5 * Int(round(Double(value) / 5.0))
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("day-by-day.title")
                .font(.title.bold())
                .fontDesign(.serif)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

            ForEach(
                Array(days.enumerated()),
                id: \.element.time
            ) {
                index,
                item in
                HStack(spacing: 16) {
                    Text(
                        index == 0
                            ? String(localized: "day-by-day.today")
                            : item.time.formatted(
                                .dateTime.weekday(.abbreviated)
                            ).capitalized
                    )
                    .font(.body.bold())
                    .frame(width: 42, alignment: .leading)

                    HStack(spacing: 8) {
                        SymbolView(symbol: item.symbol)
                            .font(.system(size: 20))
                            .frame(width: 20, height: 20)
                        if item.precipitationProbability > 30 {
                            Text(
                                "\(roundToNearest5(item.precipitationProbability)) %"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        HStack(spacing: 0) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            TemperatureView(temperature: item.temperatureMin)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 30)
                        }

                        HStack(spacing: 0) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                            TemperatureView(temperature: item.temperatureMax)
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(minWidth: 30)
                        }
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedItem = item
                }
            }
            .padding(.horizontal, 16)
            .sheet(
                item: $selectedItem,
                onDismiss: {
                    selectedItem = nil
                }
            ) { selectedItem in
                DayDetailsView(
                    selectedItem: selectedItem
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()

    if !mockData.dayByDay.isEmpty {
        DayByDayView(days: mockData.dayByDay)
            .appBackground()
    } else {
        ProgressView()
    }
}
