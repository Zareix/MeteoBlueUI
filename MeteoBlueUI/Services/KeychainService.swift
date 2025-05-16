//
//  KeychainService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 12/05/2025.
//

import KeychainAccess

struct KeychainService {
    let keychain = Keychain(service: "com.zareix.MeteoBlueUI")

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
