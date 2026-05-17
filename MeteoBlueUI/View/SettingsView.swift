//
//  SettingsView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 14/04/2026.
//

import SwiftUI

struct SettingsView<Label: View>: View {
    @State private var isSheetOpen = false

    let label: Label?

    init(@ViewBuilder label: () -> Label) {
        self.label = label()
    }

    var body: some View {
        Button {
            isSheetOpen.toggle()
        } label: {
            label
        }
        .sheet(isPresented: $isSheetOpen) {
            NavigationStack {
                List {
                    Section {
                        NavigationLink {
                            APISettingsView()
                        } label: {
                            SettingsRow(
                                symbol: "key.fill",
                                color: .blue,
                                titleKey: "settings.api.title"
                            )
                        }
                    }
                }
                .navigationTitle("settings.title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isSheetOpen = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
        }
    }
}

private struct SettingsRow: View {
    let symbol: String
    let color: Color
    let titleKey: LocalizedStringKey

    var body: some View {
        SwiftUI.Label {
            Text(titleKey)
        } icon: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color, in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

private struct APISettingsView: View {
    let keyChainService = KeychainService()
    @State private var apiToken: String = ""
    @Environment(\.dismiss) private var dismiss
    

    var body: some View {
        Form {
            Section {
                SecureField("settings.api.token", text: $apiToken)
            } header: {
                Text("settings.api.token")
            } footer: {
                Text("settings.api.footer")
            }
        }
        .navigationTitle("settings.api.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    keyChainService.setMetoBlueAPIToken(token: apiToken)
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.glassProminent)
                .disabled(apiToken.isEmpty)
            }
        }
        .onAppear {
            apiToken = keyChainService.getMetoBlueAPIToken() ?? ""
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
