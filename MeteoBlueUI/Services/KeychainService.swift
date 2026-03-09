//
//  KeychainService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 12/05/2025.
//

import KeychainAccess

struct KeychainService {
    let keychain = Keychain(service: "com.zareix.MeteoBlueUI") // Doesn't work when sideloading : accessGroup: "KC74NH6SS8.com.zareix.MeteoBlueUI.keychain-access-group")

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
