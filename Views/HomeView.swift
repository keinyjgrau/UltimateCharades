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
    @Environment(\.verticalSizeClass) private var vSize

    @State private var toast: String? = nil
    @State private var playPulse = false

    private var isLandscape: Bool { vSize == .compact }

    var body: some View {
        ZStack {
            Image("home_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.45),
                    .black.opacity(0.10),
                    .black.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Group {
                if isLandscape {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .overlay(alignment: .topTrailing) {
                topBar(compact: isLandscape)
                    .padding(.top, 10)
                    .padding(.trailing, 14)
                    .safeAreaPadding(.top, 2)
                    .safeAreaPadding(.trailing, 2)
            }

            if let toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.footnote)
                        .foregroundStyle(.black.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.thinMaterial.opacity(0.85), in: Capsule())
                        .overlay(Capsule().stroke(.black.opacity(0.08), lineWidth: 1))
                        .padding(.bottom, isLandscape ? 10 : 22)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            app.loadPacksIfNeeded()
            if app.selectdPackIds.isEmpty {
                app.selectdPackIds = Set(app.packs.map { $0.id })
            }
            playPulse = true
        }
    }

    // MARK: - Portrait

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 18)

            titleBlock(compact: false)

            nowPlayingCard
                .padding(.top, 10)

            Spacer(minLength: 16)

            playButton(compact: false)
                .padding(.bottom, 18)
        }
        .padding(.horizontal, UIStyle.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Landscape

    private var landscapeLayout: some View {
        HStack(spacing: UIStyle.sectionSpacing) {
            VStack(alignment: .leading, spacing: 12) {
                titleBlock(compact: true)
                    .padding(.top, 40)

                nowPlayingCard
                    .frame(maxWidth: 360, alignment: .leading)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                Spacer(minLength: 80)

                playButton(compact: true)
                    .frame(maxWidth: 340)
                    .padding(.horizontal, 8)

                Spacer(minLength: 0)
            }
            .frame(width: 360, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    // MARK: - Top Bar

    private func topBar(compact: Bool) -> some View {
        HStack(spacing: 10) {
            iconButton(systemName: "bag.fill", accessibility: "Store", compact: compact) {
                showToast("Store coming soon.")
            }

            iconButton(systemName: "gearshape.fill", accessibility: "Settings", compact: compact) {
                withAnimation(.easeInOut(duration: UIStyle.standardAnimation)) {
                    app.flow = .menu
                }
            }
        }
        .padding(compact ? 6 : 8)
        .background(
            Capsule()
                .fill(.white.opacity(0.25))
                .blur(radius: 2)
        )
        .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 1))
    }

    private func iconButton(
        systemName: String,
        accessibility: String,
        compact: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: compact ? 15 : 17, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: compact ? 34 : 38, height: compact ? 34 : 38)
                .background(Circle().fill(.white.opacity(0.88)))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .accessibilityLabel(accessibility)
    }

    // MARK: - Title

    private func titleBlock(compact: Bool) -> some View {
        VStack(alignment: compact ? .leading : .center, spacing: 6) {
            Text("Charades")
                .font(.system(
                    size: compact ? UIStyle.compactHeroTitleSize : UIStyle.heroTitleSize,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(.white)

            Text("Quick party game")
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: compact ? .leading : .center)
    }

    // MARK: - Now Playing

    private var nowPlayingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Now Playing")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.black.opacity(0.70))

            HStack(spacing: 10) {
                stat("Timer", "\(app.roundSeconds)s")
                divider
                stat("Mode", app.isTeamsMode ? "Teams" : "FFA")
                divider
                stat("Packs", "\(selectedPackCount())")
            }
        }
        .padding(12)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: UIStyle.cardCornerRadius, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: UIStyle.cardCornerRadius, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(.black.opacity(0.10))
            .frame(width: 1, height: 26)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(.black.opacity(0.85))

            Text(label)
                .font(.caption2)
                .foregroundStyle(.black.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Play Button

    private func playButton(compact: Bool) -> some View {
        Button {
            hapticPlayTap()
            startGameNow()
        } label: {
            VStack(spacing: compact ? 4 : 6) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: compact ? 18 : 20, weight: .bold))

                    Text("Play")
                        .font(.system(size: compact ? 22 : 24, weight: .bold, design: .rounded))
                }

                Text("Tap to start")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.70))
            }
            .frame(maxWidth: compact ? 340 : 360)
            .frame(height: compact ? UIStyle.compactLargeButtonHeight : UIStyle.largeButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: UIStyle.buttonCornerRadius, style: .continuous)
                    .fill(.thinMaterial)
                    .opacity(0.55)
            )
            .scaleEffect(playPulse ? 1.03 : 1.0)
            .animation(
                .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                value: playPulse
            )
        }
        .buttonStyle(.borderedProminent)
        .tint(.white)
        .foregroundStyle(.black)
        .shadow(color: .black.opacity(0.26), radius: 14, x: 0, y: 10)
    }

    // MARK: - Logic

    private func selectedPackCount() -> Int {
        let selected = app.packs.filter { app.selectdPackIds.contains($0.id) }
        return selected.isEmpty ? app.packs.count : selected.count
    }

    private func startGameNow() {
        app.loadPacksIfNeeded()

        let selected = app.packs.filter { app.selectdPackIds.contains($0.id) }
        let packsToUse = selected.isEmpty ? app.packs : selected
        let words = packsToUse.flatMap { $0.cards }

        guard !words.isEmpty else {
            showToast("No cards available. Go to Settings and select packs.")
            return
        }

        let vm = GameVM(app: app)
        vm.setDeck(words)

        app.game = vm
        withAnimation(.easeInOut(duration: UIStyle.standardAnimation)) {
            app.flow = .game
        }
    }

    private func showToast(_ msg: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            toast = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeIn(duration: 0.2)) {
                toast = nil
            }
        }
    }

    private func hapticPlayTap() {
        guard app.hapticsIdx != 0 else { return }

        if app.hapticsIdx == 2 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
