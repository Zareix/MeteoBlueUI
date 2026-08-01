//
//  KeychainService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 12/05/2025.
//

import Foundation
import KeychainAccess

struct KeychainService {
    static let didChangeNotification = Notification.Name("KeychainAPITokenDidChange")

    let keychain = Keychain(service: "com.raphaelgc.MeteoBlueUI")
        .accessibility(.afterFirstUnlock)

    func getMetoBlueAPIToken() -> String? {
        return keychain["api-token"]
    }

    func setMetoBlueAPIToken(token: String) {
        keychain[string: "api-token"] = token
        NotificationCenter.default.post(name: KeychainService.didChangeNotification, object: nil)
    }

    func clearMetoBlueAPIToken() {
        try? keychain.remove("api-token")
    }
}
