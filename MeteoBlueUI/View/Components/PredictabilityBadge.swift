//
//  PredictabilityBadge.swift
//  MeteoBlueUI
//
//  Created by Assistant on 17/05/2026.
//

import SwiftUI

struct PredictabilityBadge: View {
    let predictabilityClass: Int
    var size: CGFloat = 12

    @State private var showPopover = false

    var body: some View {
        Button {
            showPopover = true
        } label: {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: size))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover) {
            VStack(alignment: .leading, spacing: 8) {
                if predictabilityClass == 1 {
                    Text("predictability.very-low.title")
                        .font(.headline)
                    Text("predictability.very-low.description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("predictability.low.title")
                        .font(.headline)
                    Text("predictability.low.description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }
}
