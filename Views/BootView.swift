//
//  BootView.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-07.
//


import SwiftUI

struct BootView: View {
    @EnvironmentObject var app: AppState
    @State private var show = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                Text("CHARADES")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(show ? 1 : 0)
                    .scaleEffect(show ? 1 : 0.92)
                    .animation(.easeOut(duration: 0.35), value: show)

                Text("Loading…")
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .onAppear {
            
            app.loadPacksIfNeeded()
            
            show = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    app.flow = .home
                }
                
            }
            

        }
    }
}
