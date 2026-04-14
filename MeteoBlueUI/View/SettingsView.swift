//
//  SettingsView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 14/04/2026.
//

import SwiftUI

struct SettingsView<Label: View>: View {
    let keyChainService = KeychainService()
    @State private var isSheetOpen = false
    @State private var apiToken: String

    let label: Label?

    init(@ViewBuilder label: () -> Label) {
        self.label = label()
        apiToken = keyChainService.getMetoBlueAPIToken() ?? ""
    }

    func clearAPIToken() {
        keyChainService.clearMetoBlueAPIToken()
    }

    func saveToKeychain() {
        keyChainService.setMetoBlueAPIToken(token: apiToken)
    }

    var body: some View {
        Button {
            isSheetOpen.toggle()
        } label: {
            label
        }
        .sheet(
            isPresented: $isSheetOpen,
            onDismiss: {
                isSheetOpen = false
            }
        ) {
            NavigationStack {
                VStack(alignment: .leading) {
                    Text("MeteoBlue API token")
                        .font(.headline)
                    SecureField("API Token", text: $apiToken)
                        .textFieldStyle(.roundedBorder)

                    Spacer()
                }
                .padding()
                .navigationTitle("settings.title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isSheetOpen = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            saveToKeychain()
                            isSheetOpen = false
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(apiToken.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

extension SettingsView where Label == DefaultSettingsIcon {
    init() {
        self.init {
            DefaultSettingsIcon()
        }
    }
}

struct DefaultSettingsIcon: View {
    var body: some View {
        Image(systemName: "gearshape.fill")
            .foregroundColor(.blue)
    }
}

#Preview {
    @Previewable @State var mock = MockMeteoData()
    NavigationStack {
        VStack {
            SettingsView {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                    Text("settings.title")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                SettingsView()
            }
        }
    }
}
