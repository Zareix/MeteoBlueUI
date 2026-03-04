//
//  AppBackground.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import SwiftUI

extension View {
    func appBackground() -> some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            self
        }
    }
}
