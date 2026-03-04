//
//  AppError.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import Foundation

enum AppError: Error, LocalizedError {
    case runtimeError(String)
    case noAPIToken
    case invalidAPIToken
    case rateLimitExceeded
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .runtimeError(let msg): return msg
        case .noAPIToken: return "No API token found. Please add your MeteoBlue API key in Settings."
        case .invalidAPIToken: return "Invalid API token. Please check your MeteoBlue API key in Settings."
        case .rateLimitExceeded: return "API rate limit exceeded. Please try again later."
        case .httpError(let code): return "Server error (HTTP \(code)). Please try again later."
        }
    }
}
