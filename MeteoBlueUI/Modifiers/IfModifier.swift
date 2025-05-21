//
//  IfModifier.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 21/05/2025.
//
import SwiftUI

extension View {
    /// - Parameters:
    ///   - value: An optional value that determines whether the transformation should be applied.
    ///   - transform: A closure taking the original view and the unwrapped value, returning a modified content.
    /// - Returns: If the optional value is non-nil, returns the transformed content; otherwise, returns the original view.
    @ViewBuilder
    func `ifLet`<T, Content: View>(_ value: T?, transform: (Self, T) -> Content)
        -> some View
    {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}
