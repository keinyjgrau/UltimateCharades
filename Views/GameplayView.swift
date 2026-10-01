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
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("No active game.")
                        .font(.headline)

                    Button("Back to Home") {
                        withAnimation(
                            .easeInOut(
                                duration: UIStyle.standardAnimation
                            )
                        ) {
                            app.flow = .home
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

// MARK: - Gameplay Screen

private struct GameplayScreen: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var vm: GameVM

    @StateObject private var tilt = TiltMotionManager()

    private enum WordMoveDirection {
        case correct
        case skip
    }

    // Word feedback
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
            let isLandscape =
                geo.size.width > geo.size.height

            ZStack {
                gameplayBackground

                if isLandscape {
                    landscapeLayout(geo: geo)
                } else {
                    portraitLayout(geo: geo)
                }
            }
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
        .onChange(of: app.tiltModeOn) { _, isOn in
            if isOn {
                if !vm.isPaused && !showIntroOverlay {
                    tilt.start()
                }
            } else {
                tilt.stop()
            }
        }
        .onChange(of: vm.isPaused) { _, paused in
            guard app.tiltModeOn else { return }

            if paused {
                tilt.stop()
            } else if !showIntroOverlay {
                tilt.start()
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

                if app.tiltModeOn && !vm.isPaused {
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 0.22
                    ) {
                        if !showIntroOverlay {
                            tilt.start()
                        }
                    }
                }

            case .ended:
                showIntroOverlay = false
                lastCountdownHapticValue = nil
                tilt.stop()
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

    // MARK: - Portrait Layout

    private func portraitLayout(
        geo: GeometryProxy
    ) -> some View {

        let cardHeight =
            min(
                max(
                    geo.size.height * 0.36,
                    220
                ),
                350
            )

        return VStack(spacing: 14) {

            topHUD(
                compact: false
            )

            if app.isTeamsMode {
                teamHeader
            }

            mainCardArea(
                isLandscape: false
            )
            .frame(height: cardHeight)
            .padding(.horizontal, UIStyle.screenPadding)

            scoreRow

            progressRow(
                vertical: false
            )

            actionButtons(
                compact: false
            )

            Spacer(minLength: 8)

            endRoundButton(
                compact: false
            )
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(
            width: geo.size.width,
            height: geo.size.height,
            alignment: .top
        )
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(
        geo: GeometryProxy
    ) -> some View {

        HStack(
            alignment: .center,
            spacing: 18
        ) {

            // LEFT SIDE - CARD
            VStack(spacing: 10) {

                if app.isTeamsMode {
                    compactTeamLabel
                }

                mainCardArea(
                    isLandscape: true
                )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

            // RIGHT SIDE - CONTROLS
            landscapeControlPanel
                .frame(
                    width:
                        min(
                            max(
                                geo.size.width * 0.34,
                                285
                            ),
                            360
                        )
                )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(
            width: geo.size.width,
            height: geo.size.height
        )
    }

    // MARK: - Landscape Control Panel

    private var landscapeControlPanel: some View {
        VStack(spacing: 12) {

            topHUD(
                compact: true
            )

            Divider()
                .overlay(
                    Color.white.opacity(0.12)
                )

            VStack(spacing: 8) {
                HStack {
                    Text("Score")
                        .foregroundStyle(
                            .white.opacity(0.70)
                        )

                    Spacer()

                    Text("\(vm.score)")
                        .font(
                            .system(
                                size: 28,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.white)
                }

                HStack(spacing: 14) {

                    Label(
                        "\(vm.correctCount)",
                        systemImage:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)

                    Label(
                        "\(vm.skipCount)",
                        systemImage:
                            "forward.fill"
                    )
                    .foregroundStyle(.orange)

                    Spacer()
                }
                .font(.headline)
            }

            Divider()
                .overlay(
                    Color.white.opacity(0.12)
                )

            progressRow(
                vertical: true
            )

            Spacer(minLength: 0)

            actionButtons(
                compact: true
            )

            endRoundButton(
                compact: true
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(
                cornerRadius:
                    UIStyle.cardCornerRadius,
                style: .continuous
            )
            .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius:
                    UIStyle.cardCornerRadius,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.10),
                lineWidth: 1
            )
        )
    }

    // MARK: - Top HUD

    private func topHUD(
        compact: Bool
    ) -> some View {

        HStack(spacing: 10) {

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(vm.stateLabel)
                    .font(
                        compact
                        ? .subheadline.bold()
                        : .headline
                    )
                    .foregroundStyle(.white)

                if compact &&
                    app.isTeamsMode {

                    Text(currentTeamName)
                        .font(.caption)
                        .foregroundStyle(
                            .white.opacity(0.65)
                        )
                }
            }

            Spacer()

            if app.tiltModeOn {
                Image(
                    systemName: "gyroscope"
                )
                .foregroundStyle(
                    .white.opacity(0.65)
                )
            }

            Button {
                vm.togglePause()
                hapticTap()
            } label: {

                Image(
                    systemName:
                        vm.isPaused
                        ? "play.fill"
                        : "pause.fill"
                )
                .font(
                    .system(
                        size:
                            compact
                            ? 15
                            : 18,
                        weight: .semibold
                    )
                )
                .frame(
                    width:
                        compact
                        ? 34
                        : 42,
                    height:
                        compact
                        ? 34
                        : 42
                )
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .disabled(
                vm.state != .playing
                || showIntroOverlay
            )

            Text(
                "\(vm.timeRemaining)"
            )
            .font(
                .system(
                    size:
                        compact
                        ? 28
                        : 34,
                    weight: .bold,
                    design: .rounded
                )
            )
            .foregroundStyle(.white)
            .frame(
                minWidth:
                    compact
                    ? 42
                    : 55,
                alignment: .trailing
            )
        }
        .padding(
            .horizontal,
            compact
            ? 0
            : UIStyle.screenPadding
        )
    }

    // MARK: - Team Labels

    private var teamHeader: some View {
        HStack {

            Text(
                "Team: \(currentTeamName)"
            )
            .foregroundStyle(.white)

            Spacer()

            Text(
                "Up next: \(vm.nextTeamName)"
            )
            .foregroundStyle(
                .white.opacity(0.65)
            )
        }
        .font(.subheadline)
        .padding(
            .horizontal,
            UIStyle.screenPadding
        )
    }

    private var compactTeamLabel: some View {
        HStack {

            Image(
                systemName:
                    "person.2.fill"
            )

            Text(currentTeamName)
                .font(.subheadline.bold())

            Spacer()

            if !vm.nextTeamName.isEmpty {
                Text(
                    "Next: \(vm.nextTeamName)"
                )
                .font(.caption)
                .foregroundStyle(
                    .white.opacity(0.65)
                )
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
    }

    // MARK: - Main Card Area

    private func mainCardArea(
        isLandscape: Bool
    ) -> some View {

        ZStack {

            gameplayWordCard(
                isLandscape:
                    isLandscape
            )
            .opacity(
                showIntroOverlay
                ? 0
                : 1
            )
            .scaleEffect(
                showIntroOverlay
                ? 0.98
                : 1.0
            )

            if showIntroOverlay {

                roundIntroCard(
                    isLandscape:
                        isLandscape
                )
                .transition(
                    .opacity
                        .combined(
                            with:
                                .scale(
                                    scale: 0.96
                                )
                        )
                )
            }
        }
        .animation(
            .easeInOut(
                duration: 0.18
            ),
            value: showIntroOverlay
        )
    }

    // MARK: - Gameplay Card

    private func gameplayWordCard(
        isLandscape: Bool
    ) -> some View {

        ZStack {

            // NEW DEFAULT / BASIC CARD DESIGN
            RoundedRectangle(
                cornerRadius:
                    UIStyle.cardCornerRadius,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(
                            red: 0.10,
                            green: 0.17,
                            blue: 0.46
                        ),
                        Color(
                            red: 0.05,
                            green: 0.35,
                            blue: 0.72
                        )
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius:
                        UIStyle.cardCornerRadius,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(0.16),
                    lineWidth: 1
                )
            )
            .shadow(
                color:
                    .black.opacity(0.30),
                radius: 18,
                x: 0,
                y: 10
            )
            .scaleEffect(
                bounce
                ? 1.025
                : 1.0
            )
            .animation(
                .spring(
                    response: 0.22,
                    dampingFraction: 0.72
                ),
                value: bounce
            )

            // Decorative card detail
            Image(
                systemName:
                    "theatermasks.fill"
            )
            .font(
                .system(
                    size:
                        isLandscape
                        ? 120
                        : 150,
                    weight: .bold
                )
            )
            .foregroundStyle(
                .white.opacity(0.035)
            )
            .offset(
                x:
                    isLandscape
                    ? 130
                    : 110,
                y:
                    isLandscape
                    ? -40
                    : -70
            )

            Text(vm.currentWord)
                .id(vm.currentWord)
                .font(
                    .system(
                        size:
                            isLandscape
                            ? 46
                            : 44,
                        weight: .bold,
                        design: .rounded
                    )
                )

                // IMPORTANT:
                // NEVER adaptive primary
                // on this fixed dark card.
                .foregroundStyle(
                    flashCorrect
                    ? Color.green
                    : (
                        flashSkip
                        ? Color.orange
                        : Color.white
                    )
                )
                .padding(28)
                .minimumScaleFactor(0.35)
                .lineLimit(3)
                .multilineTextAlignment(
                    .center
                )
                .opacity(
                    vm.isPaused
                    ? 0.25
                    : 1.0
                )
                .transition(wordTransition)
                .animation(
                    .easeInOut(
                        duration: 0.20
                    ),
                    value:
                        vm.currentWord
                )
        }
        .overlay {

            if vm.isPaused {

                VStack(spacing: 8) {

                    Image(
                        systemName:
                            "pause.fill"
                    )
                    .font(.title2)

                    Text("Paused")
                        .font(
                            .title2.bold()
                        )
                }
                .foregroundStyle(.white)
                .padding(
                    .horizontal,
                    20
                )
                .padding(
                    .vertical,
                    14
                )
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )
            }
        }
        .gesture(
            DragGesture(
                minimumDistance: 20
            )
            .onEnded { gesture in

                guard canInteract else {
                    return
                }

                let dx =
                    gesture.translation.width

                let dy =
                    gesture.translation.height

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

    // MARK: - Intro Card

    private func roundIntroCard(
        isLandscape: Bool
    ) -> some View {

        ZStack {

            stackedCardsBackground

            VStack(
                spacing:
                    isLandscape
                    ? 8
                    : 14
            ) {

                Text(introTitle)
                    .font(
                        .system(
                            size:
                                isLandscape
                                ? 25
                                : 28,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        .white
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .opacity(
                        introTextVisible
                        ? 1
                        : 0
                    )
                    .offset(
                        y:
                            introTextVisible
                            ? 0
                            : -10
                    )

                Text(introSubtitle)
                    .font(
                        isLandscape
                        ? .subheadline
                        : .headline
                    )
                    .foregroundStyle(
                        .white.opacity(0.68)
                    )
                    .opacity(
                        introTextVisible
                        ? 1
                        : 0
                    )

                Text(
                    "\(countdownValue)"
                )
                .font(
                    .system(
                        size:
                            isLandscape
                            ? 60
                            : 72,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .white
                )
                .contentTransition(
                    .numericText()
                )
                .scaleEffect(
                    introAnimate
                    ? 1
                    : 0.82
                )
                .animation(
                    .spring(
                        response: 0.30,
                        dampingFraction: 0.68
                    ),
                    value:
                        countdownValue
                )
            }
            .padding(24)
            .animation(
                .easeOut(
                    duration: 0.25
                ),
                value:
                    introTextVisible
            )
        }
        .opacity(
            introCollapseOut
            ? 0
            : 1
        )
        .scaleEffect(
            introCollapseOut
            ? 0.92
            : 1.0
        )
    }

    // MARK: - Stacked Intro Cards

    private var stackedCardsBackground: some View {
        ZStack {

            RoundedRectangle(
                cornerRadius:
                    UIStyle.cardCornerRadius,
                style: .continuous
            )
            .fill(
                Color.indigo.opacity(0.55)
            )
            .rotationEffect(
                .degrees(
                    introCollapseOut
                    ? -2
                    : (
                        introAnimate
                        ? -11
                        : -6
                    )
                )
            )
            .offset(
                x:
                    introCollapseOut
                    ? -4
                    : (
                        introAnimate
                        ? -22
                        : -14
                    ),
                y:
                    introCollapseOut
                    ? 2
                    : (
                        introAnimate
                        ? 12
                        : 8
                    )
            )

            RoundedRectangle(
                cornerRadius:
                    UIStyle.cardCornerRadius,
                style: .continuous
            )
            .fill(
                Color.blue.opacity(0.70)
            )
            .rotationEffect(
                .degrees(
                    introCollapseOut
                    ? 2
                    : (
                        introAnimate
                        ? 9
                        : 5
                    )
                )
            )
            .offset(
                x:
                    introCollapseOut
                    ? 4
                    : (
                        introAnimate
                        ? 22
                        : 14
                    ),
                y:
                    introCollapseOut
                    ? 1
                    : (
                        introAnimate
                        ? 7
                        : 4
                    )
            )

            RoundedRectangle(
                cornerRadius:
                    UIStyle.cardCornerRadius,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color.indigo,
                        Color.blue
                    ],
                    startPoint:
                        .topLeading,
                    endPoint:
                        .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius:
                        UIStyle.cardCornerRadius,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(0.16),
                    lineWidth: 1
                )
            )
            .shadow(
                color:
                    .black.opacity(0.30),
                radius: 18,
                x: 0,
                y: 10
            )
        }
        .animation(
            .easeInOut(
                duration: 0.18
            ),
            value:
                introCollapseOut
        )
        .animation(
            .easeInOut(
                duration: 0.40
            ),
            value:
                introAnimate
        )
    }

    // MARK: - Score Row

    private var scoreRow: some View {
        HStack {

            Text(
                "Score: \(vm.score)"
            )
            .font(.headline)
            .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 14) {

                Label(
                    "\(vm.correctCount)",
                    systemImage:
                        "checkmark.circle.fill"
                )
                .foregroundStyle(.green)

                Label(
                    "\(vm.skipCount)",
                    systemImage:
                        "forward.fill"
                )
                .foregroundStyle(.orange)
            }
            .font(.headline)
        }
        .padding(
            .horizontal,
            UIStyle.screenPadding
        )
    }

    // MARK: - Progress

    @ViewBuilder
    private func progressRow(
        vertical: Bool
    ) -> some View {

        if vertical {

            VStack(spacing: 8) {

                landscapeProgressItem(
                    title: "Unseen",
                    value: vm.unseenCount,
                    systemImage:
                        "square.stack.3d.up"
                )

                landscapeProgressItem(
                    title: "Skipped",
                    value:
                        vm.skippedPendingCount,
                    systemImage:
                        "arrow.uturn.backward.circle"
                )

                landscapeProgressItem(
                    title: "Correct",
                    value:
                        vm.usedCorrectCount,
                    systemImage:
                        "checkmark.circle"
                )
            }

        } else {

            HStack(spacing: 8) {

                InfoChip(
                    title: "Unseen",
                    value:
                        "\(vm.unseenCount)",
                    systemImage:
                        "square.stack.3d.up"
                )

                InfoChip(
                    title: "Skipped",
                    value:
                        "\(vm.skippedPendingCount)",
                    systemImage:
                        "arrow.uturn.backward.circle"
                )

                InfoChip(
                    title: "Correct",
                    value:
                        "\(vm.usedCorrectCount)",
                    systemImage:
                        "checkmark.circle"
                )
            }
            .padding(
                .horizontal,
                UIStyle.screenPadding
            )
        }
    }

    private func landscapeProgressItem(
        title: String,
        value: Int,
        systemImage: String
    ) -> some View {

        HStack(spacing: 10) {

            Image(systemName: systemImage)
                .foregroundStyle(
                    .white.opacity(0.65)
                )
                .frame(width: 20)

            Text(title)
                .foregroundStyle(
                    .white.opacity(0.70)
                )

            Spacer()

            Text("\(value)")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            8
        )
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
        )
    }

    // MARK: - Game Actions

    private func actionButtons(
        compact: Bool
    ) -> some View {

        HStack(spacing: 12) {

            Button {
                skip()
            } label: {

                Label(
                    "Skip",
                    systemImage:
                        "forward.fill"
                )
                .frame(
                    maxWidth:
                        compact
                        ? .infinity
                        : nil
                )
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .disabled(!canInteract)

            Button {
                correct()
            } label: {

                Label(
                    "Correct",
                    systemImage:
                        "checkmark.circle.fill"
                )
                .frame(
                    maxWidth:
                        compact
                        ? .infinity
                        : nil
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            .tint(.blue)
            .disabled(!canInteract)
        }
        .padding(
            .horizontal,
            compact
            ? 0
            : UIStyle.screenPadding
        )
    }

    private func endRoundButton(
        compact: Bool
    ) -> some View {

        Button {
            vm.endAndGoToResults()
        } label: {

            Label(
                "End Round",
                systemImage:
                    "stop.circle"
            )
            .frame(
                maxWidth:
                    compact
                    ? .infinity
                    : nil
            )
        }
        .buttonStyle(.bordered)
        .tint(.white)
        .disabled(
            vm.state == .ended
        )
        .padding(
            .horizontal,
            compact
            ? 0
            : UIStyle.screenPadding
        )
    }

    // MARK: - Derived State

    private var canInteract: Bool {
        vm.state == .playing
        && !vm.isPaused
        && !showIntroOverlay
    }

    private var isCountdownState: Bool {
        if case .countdown =
            vm.state {
            return true
        }

        return false
    }

    private var countdownValue: Int {
        if case .countdown(let n) =
            vm.state {
            return n
        }

        return 0
    }

    private var currentTeamName: String {
        if
            app.isTeamsMode,
            app.teamNames.indices.contains(
                vm.activeTeamIndex
            )
        {
            return
                app.teamNames[
                    vm.activeTeamIndex
                ]
        }

        return "Player"
    }

    private var introTitle: String {
        if app.isTeamsMode {

            return
                "\(currentTeamName), your turn"

        } else {

            return "Get Ready"
        }
    }

    private var introSubtitle: String {
        app.isTeamsMode
        ? "Get Ready"
        : "Round Starting"
    }

    // MARK: - Background

    private var gameplayBackground: some View {
        LinearGradient(
            colors: [
                Color(
                    red: 0.025,
                    green: 0.045,
                    blue: 0.12
                ),
                Color(
                    red: 0.02,
                    green: 0.08,
                    blue: 0.20
                ),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Intro Sequence

    private func beginIntroSequence() {
        showIntroOverlay = true
        introCollapseOut = false
        introAnimate = false
        introTextVisible = false

        tilt.stop()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.03
        ) {
            introAnimate = true
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.12
        ) {
            introTextVisible = true
        }
    }

    private func collapseIntroOut() {
        guard showIntroOverlay else {
            return
        }

        withAnimation(
            .easeInOut(
                duration: 0.18
            )
        ) {
            introCollapseOut = true
            introTextVisible = false
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.18
        ) {
            showIntroOverlay = false
            introCollapseOut = false
        }
    }

    // MARK: - Word Transition

    private var wordTransition: AnyTransition {
        switch wordMoveDirection {

        case .correct:
            return .asymmetric(
                insertion:
                    .move(edge: .trailing)
                    .combined(with: .opacity),
                removal:
                    .move(edge: .leading)
                    .combined(with: .opacity)
            )

        case .skip:
            return .asymmetric(
                insertion:
                    .move(edge: .leading)
                    .combined(with: .opacity),
                removal:
                    .move(edge: .trailing)
                    .combined(with: .opacity)
            )
        }
    }

    // MARK: - Correct

    private func correct() {
        guard canInteract else {
            return
        }

        wordMoveDirection = .correct

        withAnimation(
            .easeInOut(
                duration: 0.20
            )
        ) {
            vm.onCorrect()
        }

        bounce.toggle()

        flashSkip = false
        flashCorrect = true

        hapticSuccess()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.12
        ) {
            flashCorrect = false
        }
    }

    // MARK: - Skip

    private func skip() {
        guard canInteract else {
            return
        }

        wordMoveDirection = .skip

        withAnimation(
            .easeInOut(
                duration: 0.20
            )
        ) {
            vm.onSkip()
        }

        bounce.toggle()

        flashCorrect = false
        flashSkip = true

        hapticSkip()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.12
        ) {
            flashSkip = false
        }
    }

    // MARK: - Countdown Haptic

    private func handleCountdownHaptic() {
        guard isCountdownState else {
            return
        }

        guard
            countdownValue
                != lastCountdownHapticValue
        else {
            return
        }

        lastCountdownHapticValue =
            countdownValue

        hapticCountdownPulse()
    }

    // MARK: - Haptics

    private func hapticTap() {
        guard app.hapticsIdx != 0 else {
            return
        }

        let style:
            UIImpactFeedbackGenerator.FeedbackStyle =
                app.hapticsIdx == 2
                ? .medium
                : .light

        UIImpactFeedbackGenerator(
            style: style
        )
        .impactOccurred()
    }

    private func hapticSuccess() {
        guard app.hapticsIdx != 0 else {
            return
        }

        if app.hapticsIdx == 2 {

            UINotificationFeedbackGenerator()
                .notificationOccurred(
                    .success
                )

        } else {

            UIImpactFeedbackGenerator(
                style: .light
            )
            .impactOccurred()
        }
    }

    private func hapticSkip() {
        guard app.hapticsIdx != 0 else {
            return
        }

        UIImpactFeedbackGenerator(
            style:
                app.hapticsIdx == 2
                ? .heavy
                : .light
        )
        .impactOccurred()
    }

    private func hapticCountdownPulse() {
        guard app.hapticsIdx != 0 else {
            return
        }

        UIImpactFeedbackGenerator(
            style:
                app.hapticsIdx == 2
                ? .medium
                : .light
        )
        .impactOccurred()
    }
}

// MARK: - GameVM UI Label

private extension GameVM {
    var stateLabel: String {
        switch state {

        case .countdown(let number):
            return "Starting: \(number)"

        case .playing:
            return "Playing"

        case .ended:
            return "Ended"
        }
    }
}
