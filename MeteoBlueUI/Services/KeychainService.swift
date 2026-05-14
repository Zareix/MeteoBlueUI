//
//  KeychainService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 12/05/2025.
//

import KeychainAccess

struct KeychainService {
    // Utiliser un access group pour partager le token entre l'app et le widget
    // IMPORTANT: Remplacez "YOUR_TEAM_ID" par votre Team ID (trouve dans Signing & Capabilities)
    let keychain = Keychain(service: "com.raphaelgc.MeteoBlueUI")
        .accessibility(.afterFirstUnlock) // Pour que le widget puisse y accéder

    func getMetoBlueAPIToken() -> String? {
        return keychain["api-token"]
    }

    func setMetoBlueAPIToken(token: String) {
        keychain[string: "api-token"] = token
    }

    func clearMetoBlueAPIToken() {
        try? keychain.remove("api-token")
    }
}
