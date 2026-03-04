//
//  WeatherSummaryService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 05/03/2026.
//

import Foundation
import FoundationModels

// MARK: - WeatherSummaryService

/// Generates an AI-powered weather summary using Apple Intelligence (on-device LLM).
@MainActor
class WeatherSummaryService {
    private var session: LanguageModelSession?

    /// Generates a natural-language weather summary for the upcoming hours.
    /// - Parameters:
    ///   - upcomingHours: The next few hours of weather data (up to 12).
    ///   - cityName: The name of the city to personalise the summary.
    /// - Returns: A generated description string, or `nil` if unavailable.
    func generateSummary(for hoursToDescribe: [MeteoData1H]) async -> String? {
        guard SystemLanguageModel.default.availability == .available else {
            print("WeatherSummaryService: Language model not available on this device.")
            return nil
        }

        guard !hoursToDescribe.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH'h'"

        let hoursDescription = hoursToDescribe.map { hour in
            let time = formatter.string(from: hour.time)
            let felt = abs(hour.feltTemperature - hour.temperature) >= 3 ? "ressenti \(hour.feltTemperature)°C" : ""
            let precip = hour.precipitation > 0.1 && hour.precipitationProbability > 40 ? ", \(hour.precipitationProbability)% de \(hour.precipitation)mm de pluie" : ""
            return "\(time): \(hour.description), \(Int(round(hour.temperature)))°C\(felt)\(precip)"
        }.joined(separator: "\n")

        let prompt = """
        Tu es un assistant météorologique intégré dans une application mobile. À partir des données brutes suivantes sur les 24 prochaines heures, génère un résumé météo fluide et naturel.

        CONTRAINTES STRICTES :
        - Utilise un vocabulaire clair, précis et des phrases simples.
        - Ne mentionne EN AUCUN CAS le nom de la ville ou du lieu.
        - Ne mentionne la pluie ou la neige QUE SI le pourcentage de probabilité est vraiment pertinent. Ignore les faibles risques. S'il n'y a pas de risque significatif de précipitations, ne mentionne pas la pluie ou la neige du tout.
        - Le texte doit être très court et très concis (2 ou 3 phrases maximum).
        - Fournis uniquement le résumé. N'inclus aucune formule de politesse, d'introduction ou de conclusion.

        DONNÉES MÉTÉO DES PROCHAINES 24 HEURES :
        \(hoursDescription)
        """

        print("WeatherSummaryService prompt:\n\(prompt)")

        do {
            let session = LanguageModelSession()
            self.session = session
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch let error as LanguageModelSession.GenerationError {
            print("WeatherSummaryService generation error: \(error)")
            return nil
        } catch {
            // Covers ModelManagerError (model not downloaded, simulator, etc.)
            print("WeatherSummaryService unavailable: \(error.localizedDescription)")
            return nil
        }
    }
}
