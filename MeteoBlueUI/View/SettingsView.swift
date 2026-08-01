//
//  SettingsView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 14/04/2026.
//

import SwiftUI

struct SettingsView: View {
    @State private var providerSelection: WeatherProviderType = .current

    var body: some View {
        List {
            ProviderSettingsView(selection: $providerSelection)

            if providerSelection == .meteoblue {
                Section {
                    NavigationLink {
                        APISettingsView(
                            tokenFooter: "settings.api.footer",
                            getToken: { KeychainService().getMetoBlueAPIToken() },
                            setToken: { KeychainService().setMetoBlueAPIToken(token: $0) }
                        )
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
        .navigationBarTitleDisplayMode(.large)
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundColor"))
        .onReceive(NotificationCenter.default.publisher(for: WeatherProviderType.didChangeNotification)) { _ in
            providerSelection = .current
        }
    }
}

private struct SettingsRowLabel: View {
    let symbol: String
    let color: Color
    let titleKey: LocalizedStringKey
    let iconSize: CGFloat = 26
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
                    ProviderIcon(provider: .meteoblue, size: iconSize)
                    Text("settings.provider.meteoblue")
                }.tag(WeatherProviderType.meteoblue)
                HStack {
                    ProviderIcon(provider: .weatherkit, size: iconSize)
                    Text("settings.provider.weatherkit")
                }.tag(WeatherProviderType.weatherkit)
                HStack {
                    ProviderIcon(provider: .openmeteo, size: iconSize)
                    Text("settings.provider.openmeteo")
                }.tag(WeatherProviderType.openmeteo)
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
    let tokenFooter: LocalizedStringKey
    let getToken: () -> String?
    let setToken: (String) -> Void

    @State private var apiToken: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                SecureField("settings.api.token", text: $apiToken)
            } header: {
                Text("settings.api.token")
            } footer: {
                Text(tokenFooter)
            }
        }
        .navigationTitle("settings.api.title")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundColor"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    setToken(apiToken)
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.glassProminent)
                .disabled(apiToken.isEmpty)
            }
        }
        .onAppear {
            apiToken = getToken() ?? ""
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
