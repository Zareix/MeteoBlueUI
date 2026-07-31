//
//  SettingsView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 14/04/2026.
//

import SwiftUI

struct SettingsView<Label: View>: View {
    @State private var isSheetOpen = false
    @State private var providerSelection: WeatherProviderType = .current

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
                    ProviderSettingsView(selection: $providerSelection)

                    if providerSelection == .meteoblue {
                        Section {
                            NavigationLink {
                                APISettingsView()
                            } label: {
                                SettingsRowLabel(
                                    symbol: "key.fill",
                                    color: .purple,
                                    titleKey: "settings.api.title"
                                )
                            }
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

private struct SettingsRowLabel: View {
    let symbol: String
    let color: Color
    let titleKey: LocalizedStringKey
    let iconSize: CGFloat = 30
    let inset: CGFloat = 4

    var body: some View {
        Label {
            Text(titleKey)
        } icon: {
            Image(systemName: symbol)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.white)
                .aspectRatio(contentMode: .fit)
                .padding(inset)
                .frame(width: iconSize, height: iconSize)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6.5))
        }
    }
}

private struct ProviderSettingsView: View {
    @Binding var selection: WeatherProviderType
    let iconSize: CGFloat = 28

    var body: some View {
        Section(footer: Text("settings.provider.footer")) {
            Picker(selection: $selection) {
                HStack {
                    Image("MeteoBlueIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(RoundedRectangle(cornerRadius: 6.5))
                    Text("settings.provider.meteoblue")
                }.tag(WeatherProviderType.meteoblue)
                HStack {
                    Image(systemName: "applelogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(2)
                        .frame(width: iconSize, height: iconSize)
                    Text("settings.provider.weatherkit")
                }.tag(WeatherProviderType.weatherkit)
            } label: {
                SettingsRowLabel(
                    symbol: "cloud.sun.fill",
                    color: .blue,
                    titleKey: "settings.provider.title"
                )
            }
            .pickerStyle(.inline)
            .labelsHidden()
            .onChange(of: selection) { _, newValue in
                WeatherProviderType.current = newValue
            }
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
        Image(systemName: "gearshape")
            .foregroundColor(.primary)
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
