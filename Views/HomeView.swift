//
//  HomeView.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-22.
//


import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var app: AppState

    @State private var playPulse = false
    @State private var toast: String?

    var body: some View {
        GeometryReader { geo in

            let isLandscape =
                geo.size.width > geo.size.height

            ZStack {

                homeBackground

                decorativeCards

                ScrollView {
                    if isLandscape {
                        landscapeHome
                    } else {
                        portraitHome
                    }
                }
                .scrollIndicators(.hidden)
            }
            .onAppear {
                app.loadPacksIfNeeded()

                if app.selectdPackIds.isEmpty {
                    app.selectdPackIds =
                        Set(app.packs.map { $0.id })
                }

                playPulse = true
            }
        }
    }

    // MARK: - Portrait

    private var portraitHome: some View {
        VStack(spacing: 22) {

            Spacer(minLength: 28)

            appTitle

            principalCard
                .frame(maxWidth: 430)

            Spacer(minLength: 20)
        }
        .padding(.horizontal, UIStyle.screenPadding)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Landscape

    private var landscapeHome: some View {
        HStack(spacing: 26) {

            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                appTitleLandscape

                Text(
                    "Act it. Guess it. Laugh about it."
                )
                .font(.headline)
                .foregroundStyle(.white.opacity(0.80))
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            principalCardCompact
                .frame(maxWidth: 410)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .frame(
            maxWidth: .infinity,
            minHeight: 350
        )
    }

    // MARK: - App Title

    private var appTitle: some View {
        VStack(spacing: 8) {

            Image(systemName: "theatermasks.fill")
                .font(.system(size: 44))
                .foregroundStyle(.yellow)

            Text("ULTIMATE")
                .font(
                    .system(
                        size: 26,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)

            Text("CHARADES")
                .font(
                    .system(
                        size: 42,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(.yellow)

            Text("Quick party game")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
        }
        .multilineTextAlignment(.center)
    }

    private var appTitleLandscape: some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {

            HStack(spacing: 10) {

                Image(systemName: "theatermasks.fill")
                    .foregroundStyle(.yellow)

                Text("ULTIMATE")
                    .foregroundStyle(.white)
            }
            .font(
                .system(
                    size: 24,
                    weight: .bold,
                    design: .rounded
                )
            )

            Text("CHARADES")
                .font(
                    .system(
                        size: 46,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(.yellow)
        }
    }

    // MARK: - Main Card

    private var principalCard: some View {
        VStack(spacing: 18) {

            VStack(spacing: 4) {
                Text("READY TO PLAY?")
                    .font(
                        .system(
                            size: 22,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                Text("Your current game")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Current settings

            HStack(spacing: 8) {

                gameStat(
                    value: "\(app.roundSeconds)s",
                    label: "Timer",
                    icon: "timer"
                )

                divider

                gameStat(
                    value: app.isTeamsMode
                        ? "Teams"
                        : "FFA",
                    label: "Mode",
                    icon: "person.2.fill"
                )

                divider

                gameStat(
                    value: "\(selectedPackCount())",
                    label: "Packs",
                    icon: "square.stack.3d.up.fill"
                )
            }
            .padding(.vertical, 6)

            // Main Play button

            Button {
                hapticPlayTap()
                startGameNow()
            } label: {

                HStack(spacing: 12) {
                    Image(systemName: "play.fill")

                    Text("Play")
                        .font(
                            .system(
                                size: 23,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                }
                .frame(maxWidth: .infinity)
                .frame(
                    height:
                        UIStyle.primaryButtonHeight + 8
                )
            }
            .buttonStyle(.borderedProminent)
            .scaleEffect(
                playPulse ? 1.02 : 1.0
            )
            .animation(
                .easeInOut(duration: 1.6)
                    .repeatForever(
                        autoreverses: true
                    ),
                value: playPulse
            )

            Divider()

            // Secondary destinations

            HStack(spacing: 14) {

                homeActionButton(
                    title: "Settings",
                    systemImage: "gearshape.fill"
                ) {
                    withAnimation(
                        .easeInOut(
                            duration:
                                UIStyle.standardAnimation
                        )
                    ) {
                        app.flow = .menu
                    }
                }

                homeActionButton(
                    title: "App Info",
                    systemImage: "info.circle.fill"
                ) {
                    withAnimation(
                        .easeInOut(
                            duration:
                                UIStyle.standardAnimation
                        )
                    ) {
                        app.flow = .info
                    }
                }
            }

            if let toast {
                Text(toast)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .stroke(
                .white.opacity(0.18),
                lineWidth: 1
            )
        )
        .shadow(
            color: .black.opacity(0.24),
            radius: 22,
            x: 0,
            y: 12
        )
    }

    private var principalCardCompact: some View {
        VStack(spacing: 14) {

            VStack(spacing: 2) {
                Text("READY TO PLAY?")
                    .font(
                        .system(
                            size: 20,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                Text("Your current game")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {

                gameStat(
                    value: "\(app.roundSeconds)s",
                    label: "Timer",
                    icon: "timer"
                )

                compactDivider

                gameStat(
                    value: app.isTeamsMode ? "Teams" : "FFA",
                    label: "Mode",
                    icon: "person.2.fill"
                )

                compactDivider

                gameStat(
                    value: "\(selectedPackCount())",
                    label: "Packs",
                    icon: "square.stack.3d.up.fill"
                )
            }
            .padding(.vertical, 2)

            Button {
                hapticPlayTap()
                startGameNow()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")

                    Text("Play")
                        .font(
                            .system(
                                size: 21,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                }
                .frame(maxWidth: .infinity)
                .frame(height: UIStyle.primaryButtonHeight)
            }
            .buttonStyle(.borderedProminent)

            Divider()

            HStack(spacing: 12) {

                compactHomeActionButton(
                    title: "Settings",
                    systemImage: "gearshape.fill"
                ) {
                    withAnimation(.easeInOut(duration: UIStyle.standardAnimation)) {
                        app.flow = .menu
                    }
                }

                compactHomeActionButton(
                    title: "App Info",
                    systemImage: "info.circle.fill"
                ) {
                    withAnimation(.easeInOut(duration: UIStyle.standardAnimation)) {
                        app.flow = .info
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(0.24),
            radius: 22,
            x: 0,
            y: 12
        )
    }
    
    private var compactDivider: some View {
        Rectangle()
            .fill(.secondary.opacity(0.18))
            .frame(width: 1, height: 44)
    }

    private func compactHomeActionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.headline)

                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.bordered)
    }
    // MARK: - Game Stat

    private func gameStat(
        value: String,
        label: String,
        icon: String
    ) -> some View {

        VStack(spacing: 5) {

            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(.secondary.opacity(0.18))
            .frame(width: 1, height: 52)
    }

    // MARK: - Secondary Buttons

    private func homeActionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            VStack(spacing: 7) {

                Image(systemName: systemImage)
                    .font(.title3)

                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Background

    private var homeBackground: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.95),
                Color.indigo.opacity(0.95),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // Decorative card shapes

    private var decorativeCards: some View {
        ZStack {

            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .fill(.white.opacity(0.055))
            .frame(width: 230, height: 310)
            .rotationEffect(.degrees(-18))
            .offset(x: -160, y: -230)

            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .fill(.yellow.opacity(0.06))
            .frame(width: 220, height: 300)
            .rotationEffect(.degrees(16))
            .offset(x: 170, y: 240)

            Image(systemName: "questionmark")
                .font(
                    .system(
                        size: 150,
                        weight: .black
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.025)
                )
                .offset(x: 130, y: -180)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Logic

    private func selectedPackCount() -> Int {
        let selected =
            app.packs.filter {
                app.selectdPackIds.contains($0.id)
            }

        return selected.isEmpty
            ? app.packs.count
            : selected.count
    }

    private func startGameNow() {
        app.loadPacksIfNeeded()

        let selected =
            app.packs.filter {
                app.selectdPackIds.contains($0.id)
            }

        let packsToUse =
            selected.isEmpty
                ? app.packs
                : selected

        let words =
            packsToUse.flatMap { $0.cards }

        guard !words.isEmpty else {
            toast =
                "No cards are available. Open Settings and select at least one pack."
            return
        }

        let vm = GameVM(app: app)
        vm.setDeck(words)

        app.game = vm

        withAnimation(
            .easeInOut(
                duration:
                    UIStyle.standardAnimation
            )
        ) {
            app.flow = .game
        }
    }

    // MARK: - Haptic

    private func hapticPlayTap() {
        guard app.hapticsIdx != 0 else {
            return
        }

        if app.hapticsIdx == 2 {
            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(
                style: .light
            )
            .impactOccurred()
        }
    }
}
