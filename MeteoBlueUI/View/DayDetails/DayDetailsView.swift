//
//  DayDetailsView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 18/05/2025.
//

import Charts
import SwiftUI

struct DayDetailsView: View {
    @EnvironmentObject var meteoData: MeteoData

    let selectedItem: MeteoDataDay

    @State var activeItem: MeteoDataDay?
    @State private var daySelectorWidth: CGFloat = 0

    private var activeDay: MeteoDataDay {
        activeItem ?? selectedItem
    }

    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 8) {
                    ScrollViewReader { scrollProxy in
                        ScrollView(.horizontal) {
                            HStack(alignment: .center) {
                                ForEach(meteoData.dayByDay) { day in
                                    VStack {
                                        Text(
                                            day.time.formatted(
                                                .dateTime.weekday(.abbreviated)
                                            )
                                            .capitalized
                                            .prefix(1)
                                        )
                                        .font(.system(size: 14))
                                        .onTapGesture {
                                            withAnimation {
                                                activeItem = day
                                            }
                                        }
                                        Button {
                                            withAnimation {
                                                activeItem = day
                                            }
                                        } label: {
                                            Text(
                                                day.time.formatted(
                                                    .dateTime.day(.twoDigits)
                                                )
                                            ).lineLimit(1)
                                        }
                                        .padding(8)
                                        .foregroundColor(
                                            meteoData.dayByDay.first == day
                                                ? .accentColor : .primary
                                        )
                                        .font(.body)
                                        .background(
                                            activeDay == day
                                                ? Circle()
                                                .fill(Color.accentColor.opacity(0.2))
                                                : Circle().fill(.clear)
                                        )
                                        .shadow(
                                            color: .secondary.opacity(0.4),
                                            radius: activeDay == day
                                                ? 2 : 0
                                        )
                                        .transition(.opacity)
                                        .animation(.easeInOut, value: activeDay)
                                    }
                                    .id(day.id)
                                }
                            }
                            .padding(.horizontal)
                            .frame(minWidth: daySelectorWidth)
                        }
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.width
                        } action: { newWidth in
                            daySelectorWidth = newWidth
                        }
                        .onChange(of: activeDay) { _, newValue in
                            withAnimation {
                                scrollProxy.scrollTo(newValue.id, anchor: .center)
                            }
                        }
                    }

                    HStack {
                        Text(
                            activeDay.time.formatted(
                                .dateTime
                                    .weekday(.wide)
                                    .day(.twoDigits)
                                    .month(.wide)
                            )
                            .capitalized
                        )
                        .transition(.opacity)
                        .animation(.easeInOut, value: activeDay.time)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                }

                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(meteoData.dayByDay, id: \.self) { day in
                            ScrollView {
                                TemperatureChartView(day: day)

                                Divider()

                                PrecipitationChartView(day: day)
                                    .padding(.top, 8)
                            }
                            .padding(.horizontal, 16)
                        }
                        .containerRelativeFrame(
                            .horizontal,
                            count: 1,
                            spacing: 0
                        )
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $activeItem)
                .scrollIndicators(.never)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 18))
                            .frame(height: 18)
                        Text("day-details.title")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .appBackground()
        }
        .onAppear {
            activeItem = selectedItem
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()
    @Previewable @StateObject var locationManager = LocationManager()

    @Previewable @State var open = true

    if let location = locationManager.currentLocation {
        ZStack {
            if let firstDay = mockData.dayByDay.first {
                VStack {
                    Button("Preview") {
                        open.toggle()
                    }
                }.sheet(isPresented: $open) {
                    DayDetailsView(
                        selectedItem: firstDay
                    )
                    .environmentObject(mockData as MeteoData)
                }
            }
        }
        .appBackground()
        .task {
            await mockData.loadMeteoData(location: location)
        }
    } else {
        ProgressView()
    }
}
