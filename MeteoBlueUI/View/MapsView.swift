//
//  MapsView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 06/03/2026.
//

import SwiftUI
import WebKit

// MARK: - WebView (WKWebView wrapper)

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = true
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: - MapsView

struct MapsView: View {
    private var mapURL: URL {
        URL(string: "https://www.meteoblue.com/en/weather/maps/widget/paris_france_2988507?gust=0&satellite=0&cloudsAndPrecipitation=1&windAnimation=0&temperature=1&sunshine=0&extremeForecastIndex=0&geoloc=fixed&tempunit=C&lengthunit=metric&windunit=km%252Fh&zoom=9&autowidth=auto")!
    }

    var body: some View {
        WebView(url: mapURL)
            .navigationTitle("maps.title")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("BackgroundColor"))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MapsView()
    }
}
