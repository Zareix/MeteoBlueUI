//
//  SymbolView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 21/05/2025.
//
import SwiftUI

struct SymbolView: View {
    let symbol: String
    var description: String?
    var transition: ContentTransition = .opacity
    var animationEnabled: Bool = true

    @State var selected: Bool = false

    var body: some View {
        Image(systemName: symbol)
            .symbolRenderingMode(.multicolor)
            .shadow(color: .secondary.opacity(0.3), radius: 8)
            .contentTransition(transition)
            .animation(
                animationEnabled ? .easeInOut : nil,
                value: symbol
            )
            .ifLet(description) { view, description in
                view
                    .onTapGesture {
                        selected.toggle()
                    }
                    .popover(isPresented: $selected) {
                        Text(description)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .frame(maxWidth: 250)
                            .multilineTextAlignment(.center)
                            .presentationCompactAdaptation((.popover))
                    }
            }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var symbol = "cloud.sun.fill"
    @Previewable @State var description =
        "Variable avec cirrus et quelques nuages d'orage possibles"

    VStack {
        HStack(spacing: 32) {
            SymbolView(symbol: symbol)

            SymbolView(symbol: symbol)
                .font(.system(size: 28))
                .frame(width: 28, height: 28)

            SymbolView(symbol: symbol, description: description)
                .font(.system(size: 38))
                .frame(width: 38, height: 38)
        }
        HStack(spacing: 32) {
            SymbolView(
                symbol: symbol,
                description: description,
                animationEnabled: false
            )
            .font(.system(size: 38))
            .frame(width: 38, height: 38)

            SymbolView(
                symbol: symbol,
                description: description,
                transition: .symbolEffect
            )
            .font(.system(size: 38))
            .frame(width: 38, height: 38)

            SymbolView(
                symbol: symbol,
                description: description,
                transition: .opacity
            )
            .font(.system(size: 38))
            .frame(width: 38, height: 38)
        }

        Button("Refresh") {
            withAnimation {
                let picto = Int.random(in: 1...35)
                symbol = PictoMapper.pictoToSFSymbol(
                    picto: picto,
                    isDaylight: Bool.random()
                )
                description = PictoMapper.pictoToDescription(picto: picto)
            }
        }
    }
}
