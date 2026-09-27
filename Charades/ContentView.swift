//
//  ContentView.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-07.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            switch app.flow {

            case .boot:
                BootView()
                    .transition(.opacity)

            case .home:
                HomeView()
                    .transition(
                        .opacity
                            .combined(with: .scale(scale: 1.02))
                    )

            case .menu:
                MainMenuView()
                    .transition(.opacity)

            case .game:
                GameplayView()
                    .transition(
                        .opacity
                            .combined(with: .scale(scale: 0.98))
                    )

            case .results:
                ResultsView()
                    .transition(.opacity)

            case .info:
                AppInfoView()
                    .transition(.opacity)
            }
        }
        .animation(
            .easeInOut(duration: UIStyle.standardAnimation),
            value: app.flow
        )
    }
}
