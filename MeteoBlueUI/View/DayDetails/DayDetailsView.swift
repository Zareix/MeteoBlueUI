//
//  DayDetailsView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 18/05/2025.
//

import Charts
import SwiftUI

struct DayDetailsView: View {
    let dayByDay: [MeteoDataDay]
    let selectedItem: MeteoDataDay

    @State var activeItem: MeteoDataDay?

    var body: some View {
        NavigationStack {
            VStack {
                if let activeDay = activeItem {
                    VStack(spacing: 8) {
                        HStack {
                            ForEach(dayByDay) { day in
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
                                        )
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .foregroundColor(
                                        dayByDay.first == day ? .cyan : .primary
                                    )
                                    .font(.body)
                                    .background(
                                        activeDay == day
                                            ? Circle()
                                                .fill(.white)
                                            : Circle().fill(.clear)
                                    )
                                    .shadow(
                                        color: .secondary.opacity(0.4),
                                        radius:  activeDay == day
                                        ? 2 : 0
                                    )
                                    .transition(.opacity)
                                    .animation(.easeInOut, value: activeDay)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)

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
                        .frame(maxWidth: .infinity)

                        Divider()
                    }
                }

                ScrollView(.horizontal) {
                    HStack {
                        ForEach(dayByDay, id: \.self) { day in
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
        }
        .onAppear {
            activeItem = selectedItem
        }
    }
}

//// MARK: - Preview
//#Preview {
//    @Previewable @StateObject var mockData = MockMeteoData()
//    @Previewable @StateObject var locationManager = LocationManager()
//
//    @Previewable @State var open: Bool = true
//
//    if let city = locationManager.city {
//        ZStack {
//            if let firstDay = mockData.dayByDay.first {
//                VStack {
//                    Button("Preview") {
//                        open.toggle()
//                    }
//                }.sheet(isPresented: $open) {
//                    DayDetailsView(
//                        day: firstDay
//                    )
//                    .environmentObject(mockData as MeteoData)
//                }
//            }
//        }.task {
//            await mockData.loadMeteoData(city: city)
//        }
//    } else {
//        ProgressView()
//    }
//}
