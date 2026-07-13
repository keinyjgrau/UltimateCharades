//
//  CharadesApp.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-07.
//

import SwiftUI

@main
struct CharadesApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
