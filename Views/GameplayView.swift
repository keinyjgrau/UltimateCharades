//
//  GameplayView.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-07.
//

import SwiftUI
import UIKit

struct GameplayView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        if let vm = app.game {
            GameplayScreen(vm: vm)
        } else {
            VStack(spacing: 12) {
                Text("No active game.")
                Button("Back to Menu") {
                    withAnimation(.easeInOut(duration: UIStyle.standardAnimation)) {
                        app.flow = .menu
                    }
                }
            }
        }
    }
}

private struct GameplayScreen: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var vm: GameVM

    @StateObject private var tilt = TiltMotionManager()

    private enum WordMoveDirection {
        case correct
        case skip
    }

    @State private var flashCorrect = false
    @State private var flashSkip = false
    @State private var bounce = false
    @State private var wordMoveDirection: WordMoveDirection = .correct

    // Intro animation
    @State private var introAnimate = false
    @State private var introTextVisible = false
    @State private var lastCountdownHapticValue: Int? = nil
    @State private var showIntroOverlay = true
    @State private var introCollapseOut = false

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            VStack(spacing: isLandscape ? 10 : UIStyle.sectionSpacing) {

                // Top HUD
                HStack {
                    Text(vm.stateLabel)
                        .font(.headline)

                    Spacer()

                    if app.tiltModeOn {
                        Label("Tilt", systemImage: "gyroscope")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        vm.togglePause()
                        hapticTap()
                    } label: {
                        Label(
                            vm.isPaused ? "Resume" : "Pause",
                            systemImage: vm.isPaused ? "play.fill" : "pause.fill"
                        )
                        .labelStyle(.iconOnly)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(10)
                    }
                    .buttonStyle(.bordered)
                    .disabled(vm.state != .playing || showIntroOverlay)

                    Text("\(vm.timeRemaining)")
                        .font(.system(size: isLandscape ? 28 : 34, weight: .bold, design: .rounded))
                        .frame(minWidth: 60, alignment: .trailing)
                }
                .padding(.horizontal, UIStyle.screenPadding)

                if app.isTeamsMode {
                    HStack {
                        let currentName = app.teamNames.indices.contains(vm.activeTeamIndex)
                            ? app.teamNames[vm.activeTeamIndex]
                            : "Team"

                        Text("Team: \(currentName)")

                        Spacer()

                        Text("Up next: \(vm.nextTeamName)")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, UIStyle.screenPadding)
                    .font(.subheadline)
                }

                let cardHeight: CGFloat = {
                    if isLandscape {
                        return min(max(geo.size.height * 0.38, 160), 220)
                    } else {
                        return min(max(geo.size.height * 0.38, 220), 360)
                    }
                }()

                // Main card area
                ZStack {
                    gameplayWordCard(isLandscape: isLandscape)
                        .opacity(showIntroOverlay ? 0 : 1)
                        .scaleEffect(showIntroOverlay ? 0.98 : 1.0)

                    if showIntroOverlay {
                        roundIntroCard(isLandscape: isLandscape)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .animation(.easeInOut(duration: 0.18), value: showIntroOverlay)
                .frame(height: cardHeight)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, UIStyle.screenPadding)

                // Score row
                HStack {
                    Text("Score: \(vm.score)")
                    Spacer()
                    Text("✅ \(vm.correctCount)   ⏭ \(vm.skipCount)")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, UIStyle.screenPadding)

                // Round progress
                HStack(spacing: 10) {
                    InfoChip(title: "Unseen", value: "\(vm.unseenCount)", systemImage: "square.stack.3d.up")
                    InfoChip(title: "Skipped", value: "\(vm.skippedPendingCount)", systemImage: "arrow.uturn.backward.circle")
                    InfoChip(title: "Correct", value: "\(vm.usedCorrectCount)", systemImage: "checkmark.circle")
                }
                .padding(.horizontal, UIStyle.screenPadding)

                // Buttons
                HStack(spacing: 16) {
                    Button("Skip") {
                        skip()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canInteract)

                    Button("Correct") {
                        correct()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canInteract)
                }
                .padding(.top, isLandscape ? 0 : 8)

                if !isLandscape {
                    Spacer(minLength: 8)
                }

                Button("End Round") {
                    vm.endAndGoToResults()
                }
                .buttonStyle(.bordered)
                .disabled(vm.state == .ended)
                .padding(.bottom, isLandscape ? 6 : 10)
            }
            .padding(.top, isLandscape ? 6 : 10)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .onAppear {
            if app.tiltModeOn {
                tilt.start()
            }
            beginIntroSequence()
            handleCountdownHaptic()
        }
        .onDisappear {
            tilt.stop()
        }
        .onChange(of: app.tiltModeOn) { _, on in
            if on {
                tilt.start()
            } else {
                tilt.stop()
            }
        }
        .onChange(of: vm.isPaused) { _, paused in
            if app.tiltModeOn {
                if paused {
                    tilt.stop()
                } else if !showIntroOverlay {
                    tilt.start()
                }
            }
        }
        .onChange(of: vm.state) { _, newState in
            switch newState {
            case .countdown:
                beginIntroSequence()
                handleCountdownHaptic()
            case .playing:
                collapseIntroOut()
                lastCountdownHapticValue = nil
            case .ended:
                showIntroOverlay = false
                lastCountdownHapticValue = nil
            }
        }
        .onChange(of: countdownValue) { _, _ in
            if isCountdownState {
                handleCountdownHaptic()
            }
        }
        .onChange(of: tilt.lastAction) { _, action in
            guard let action else { return }
            guard app.tiltModeOn else { return }
            guard canInteract else { return }

            switch action {
            case .correct:
                correct()
            case .skip:
                skip()
            }
        }
    }

    // MARK: - Derived state

    private var canInteract: Bool {
        vm.state == .playing && !vm.isPaused && !showIntroOverlay
    }

    private var isCountdownState: Bool {
        if case .countdown = vm.state { return true }
        return false
    }

    private var countdownValue: Int {
        if case .countdown(let n) = vm.state { return n }
        return 0
    }

    private var introTitle: String {
        if app.isTeamsMode {
            if app.teamNames.indices.contains(vm.activeTeamIndex) {
                return "\(app.teamNames[vm.activeTeamIndex]), your turn"
            } else {
                return "Your turn"
            }
        } else {
            return "Get Ready"
        }
    }

    private var introSubtitle: String {
        app.isTeamsMode ? "Get Ready" : "Round Starting"
    }

    // MARK: - Intro sequencing

    private func beginIntroSequence() {
        showIntroOverlay = true
        introCollapseOut = false
        introAnimate = false
        introTextVisible = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            introAnimate = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            introTextVisible = true
        }
    }

    private func collapseIntroOut() {
        guard showIntroOverlay else { return }

        withAnimation(.easeInOut(duration: 0.18)) {
            introCollapseOut = true
            introTextVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            showIntroOverlay = false
            introCollapseOut = false
        }
    }

    // MARK: - Intro card

    @ViewBuilder
    private func roundIntroCard(isLandscape: Bool) -> some View {
        ZStack {
            stackedCardsBackground

            VStack(spacing: isLandscape ? 10 : 14) {
                Text(introTitle)
                    .font(.system(size: isLandscape ? 22 : 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .opacity(introTextVisible ? 1 : 0)
                    .offset(y: introTextVisible ? 0 : -10)

                Text(introSubtitle)
                    .font(isLandscape ? .subheadline : .headline)
                    .foregroundStyle(.secondary)
                    .opacity(introTextVisible ? 1 : 0)
                    .offset(y: introTextVisible ? 0 : -8)

                Text("\(countdownValue)")
                    .font(.system(size: isLandscape ? 56 : 72, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .scaleEffect(introAnimate ? 1.0 : 0.82)
                    .animation(.spring(response: 0.30, dampingFraction: 0.68), value: countdownValue)
            }
            .padding(24)
            .animation(.easeOut(duration: 0.25), value: introTextVisible)
        }
        .opacity(introCollapseOut ? 0 : 1)
        .scaleEffect(introCollapseOut ? 0.92 : 1.0)
    }

    private var stackedCardsBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UIStyle.cardCornerRadius, style: .continuous)
                .fill(.white.opacity(0.55))
                .rotationEffect(.degrees(introCollapseOut ? -2 : (introAnimate ? -11 : -6)))
                .offset(
                    x: introCollapseOut ? -4 : (introAnimate ? -22 : -14),
                    y: introCollapseOut ? 2 : (introAnimate ? 12 : 8)
                )
                .scaleEffect(introCollapseOut ? 0.96 : (introAnimate ? 1.00 : 0.95))

            RoundedRectangle(cornerRadius: UIStyle.cardCornerRadius, style: .continuous)
                .fill(.white.opacity(0.72))
                .rotationEffect(.degrees(introCollapseOut ? 2 : (introAnimate ? 9 : 5)))
                .offset(
                    x: introCollapseOut ? 4 : (introAnimate ? 22 : 14),
                    y: introCollapseOut ? 1 : (introAnimate ? 7 : 4)
                )
                .scaleEffect(introCollapseOut ? 0.97 : (introAnimate ? 1.01 : 0.96))

            RoundedRectangle(cornerRadius: UIStyle.cardCornerRadius, style: .continuous)
                .fill(.white.opacity(0.96))
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
                .scaleEffect(introCollapseOut ? 0.98 : (introAnimate ? 1.0 : 0.97))
        }
        .animation(.easeInOut(duration: 0.18), value: introCollapseOut)
        .animation(.easeInOut(duration: 0.40), value: introAnimate)
    }

    // MARK: - Normal gameplay card

    @ViewBuilder
    private func gameplayWordCard(isLandscape: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: UIStyle.cardCornerRadius, style: .continuous)
                .fill(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
                .scaleEffect(bounce ? 1.04 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: bounce)

            ZStack {
                Text(vm.currentWord)
                    .id(vm.currentWord)
                    .font(.system(size: isLandscape ? 34 : 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        flashCorrect ? Color.green :
                        (flashSkip ? Color.red : Color.primary)
                    )
                    .padding(24)
                    .minimumScaleFactor(isLandscape ? 0.35 : 0.45)
                    .multilineTextAlignment(.center)
                    .opacity(vm.isPaused ? 0.45 : 1.0)
                    .transition(wordTransition)
            }
            .animation(.easeInOut(duration: 0.20), value: vm.currentWord)
        }
        .overlay {
            if vm.isPaused {
                Text("Paused")
                    .font(.title2.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20).onEnded { g in
                guard canInteract else { return }

                let dx = g.translation.width
                let dy = g.translation.height

                if abs(dx) > abs(dy) {
                    if dx > 40 {
                        correct()
                    } else if dx < -40 {
                        skip()
                    }
                } else {
                    if dy < -60 {
                        correct()
                    } else if dy > 60 {
                        skip()
                    }
                }
            }
        )
    }



    // MARK: - Word transitions

    private var wordTransition: AnyTransition {
        switch wordMoveDirection {
        case .correct:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .skip:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }

    // MARK: - Actions

    private func correct() {
        guard canInteract else { return }

        wordMoveDirection = .correct

        withAnimation(.easeInOut(duration: 0.20)) {
            vm.onCorrect()
        }

        bounce.toggle()
        flashSkip = false
        flashCorrect = true
        hapticSuccess()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            flashCorrect = false
        }
    }

    private func skip() {
        guard canInteract else { return }

        wordMoveDirection = .skip

        withAnimation(.easeInOut(duration: 0.20)) {
            vm.onSkip()
        }

        bounce.toggle()
        flashCorrect = false
        flashSkip = true
        hapticSkip()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            flashSkip = false
        }
    }

    private func handleCountdownHaptic() {
        guard isCountdownState else { return }
        guard countdownValue != lastCountdownHapticValue else { return }
        lastCountdownHapticValue = countdownValue
        hapticCountdownPulse()
    }

    // MARK: - Haptics

    private func hapticTap() {
        guard app.hapticsIdx != 0 else { return }

        let style: UIImpactFeedbackGenerator.FeedbackStyle =
            (app.hapticsIdx == 2) ? .medium : .light

        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func hapticSuccess() {
        guard app.hapticsIdx != 0 else { return }

        if app.hapticsIdx == 2 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func hapticSkip() {
        guard app.hapticsIdx != 0 else { return }

        UIImpactFeedbackGenerator(
            style: app.hapticsIdx == 2 ? .heavy : .light
        ).impactOccurred()
    }

    private func hapticCountdownPulse() {
        guard app.hapticsIdx != 0 else { return }

        if app.hapticsIdx == 2 {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

private extension GameVM {
    var stateLabel: String {
        switch state {
        case .countdown(let n):
            return "Starting: \(n)"
        case .playing:
            return "Playing"
        case .ended:
            return "Ended"
        }
    }
}
