//
//  DateTimeConverter.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 19/05/2026.
//
import Foundation

enum DateTimeConverter {
    static func convertStringDayHourToTime(input: String) -> Date {
        return convertStringToDate(input: input, format: "yyyy-MM-dd HH:mm")
    }
    
    static func convertStringDayToDate(input: String) -> Date {
        return convertStringToDate(input: input, format: "yyyy-MM-dd")
    }
    
    static func convertStringHourToTime(input: String) -> Date {
        return convertStringToDate(input: input, format: "HH:mm")
    }
    
    static func convertStringToDate(input: String, format: String) -> Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = format
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        return inputFormatter.date(from: input) ?? Date()
    }
    
    static func combineDayAndTime(day: Date, time: String) -> Date {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1])
        else {
            return day
        }
        return Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: day
        ) ?? day
    }
}
