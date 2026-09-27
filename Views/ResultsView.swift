//
//  ResultsView.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-07.
//


import SwiftUI
import UIKit

struct ResultsView: View {
    @EnvironmentObject var app: AppState

    @State private var showTimeline = false

    // Results entrance animations
    @State private var showCelebration = false
    @State private var showHeroSummary = false
    @State private var displayedScore = 0

    @State private var showCorrectBadge = false
    @State private var showSkippedBadge = false
    @State private var showStreakBadge = false

    @State private var showSparkleAccent = false

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            ScrollView {
                if isLandscape {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
            .scrollIndicators(.hidden)
            .padding(UIStyle.screenPadding)
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color(.secondarySystemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .onAppear {
                prepareResultsAnimation()
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: UIStyle.sectionSpacing) {
            headerCard

            if let vm = app.game {

                celebrationBannerCard(vm)

                heroSummaryCard(vm)

                packsSummaryCard

                if app.isTeamsMode {
                    cumulativeCard(vm)
                }

                detailsCard(vm)

                actionsCard(vm)

            } else {
                noGameCard
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        VStack(spacing: UIStyle.sectionSpacing) {
            headerCard

            if let vm = app.game {

                celebrationBannerCard(vm)

                HStack(
                    alignment: .top,
                    spacing: UIStyle.sectionSpacing
                ) {

                    // LEFT COLUMN
                    VStack(spacing: UIStyle.sectionSpacing) {

                        heroSummaryCard(vm)

                        if app.isTeamsMode {
                            cumulativeCard(vm)
                        }

                        actionsCard(vm)
                    }
                    .frame(maxWidth: .infinity)

                    // RIGHT COLUMN
                    VStack(spacing: UIStyle.sectionSpacing) {

                        packsSummaryCard

                        detailsCard(vm)
                    }
                    .frame(maxWidth: .infinity)
                }

            } else {
                noGameCard
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Header

    private var headerCard: some View {
        AppCard {
            HStack {
                Text("Results")
                    .font(
                        .system(
                            size: UIStyle.pageTitleSize,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                Spacer()

                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Celebration

    private func celebrationBannerCard(
        _ vm: GameVM
    ) -> some View {

        let subtitle = celebrationSubtitle(vm)

        return AppCard {
            HStack(spacing: 14) {

                ZStack {

                    Circle()
                        .fill(
                            celebrationSymbolColor(vm)
                                .opacity(0.14)
                        )
                        .frame(width: 52, height: 52)

                    Image(
                        systemName:
                            celebrationSymbolName(vm)
                    )
                    .font(.title2)
                    .foregroundStyle(
                        celebrationSymbolColor(vm)
                    )

                    if showSparkleAccent {

                        Image(systemName: "sparkle")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .offset(x: -25, y: -20)

                        Image(systemName: "sparkle")
                            .font(.caption2)
                            .foregroundStyle(
                                .yellow.opacity(0.8)
                            )
                            .offset(x: 23, y: -22)

                        Image(systemName: "sparkle")
                            .font(.caption2)
                            .foregroundStyle(
                                .yellow.opacity(0.75)
                            )
                            .offset(x: 24, y: 20)
                    }
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Round Complete")
                        .font(
                            .system(
                                size: 24,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .opacity(
            showCelebration ? 1 : 0
        )
        .offset(
            y: showCelebration ? 0 : -14
        )
    }

    // MARK: - Celebration Text

    private func celebrationSubtitle(
        _ vm: GameVM
    ) -> String {

        if app.isTeamsMode {

            let scores =
                Array(
                    vm.teamScores.prefix(
                        app.teamCount
                    )
                )

            guard !scores.isEmpty else {
                return "The next round is ready."
            }

            let leaderIndex =
                leadingTeamIndex(in: scores)

            let leaderName =
                teamName(for: leaderIndex)

            let leaderScore =
                scores[leaderIndex]

            let leaders =
                scores.enumerated()
                    .filter {
                        $0.element == leaderScore
                    }
                    .map {
                        $0.offset
                    }

            let nextIndex =
                (vm.activeTeamIndex + 1)
                % app.teamCount

            let nextName =
                teamName(for: nextIndex)

            // Tie
            if leaders.count > 1 {

                if leaders.count == 2 {

                    let names =
                        leaders
                            .map {
                                teamName(for: $0)
                            }
                            .joined(
                                separator: " and "
                            )

                    return
                        "It’s a tie between \(names). \(nextName) is up next."

                } else {

                    return
                        "It’s a close game. \(nextName) is up next."
                }
            }

            // Single leader
            let sortedScores =
                scores.sorted(by: >)

            let secondScore =
                sortedScores.count > 1
                ? sortedScores[1]
                : 0

            let margin =
                leaderScore - secondScore

            if margin >= 4 {

                return
                    "\(leaderName) extends the lead. \(nextName) is up next."

            } else if margin >= 2 {

                return
                    "\(leaderName) is in front. \(nextName) is up next."

            } else {

                return
                    "\(leaderName) narrowly leads. \(nextName) is up next."
            }

        } else {

            if vm.bestStreak >= 6 {

                return
                    "Amazing streak! That was a hot round."

            } else if vm.correctCount >= 10 {

                return
                    "Excellent round! You were on fire."

            } else if vm.correctCount >= 6 {

                return
                    "Great job! Solid score."

            } else if vm.correctCount >= 3 {

                return
                    "Nice round! Ready for another?"

            } else {

                return
                    "Warm-up round complete. Try again!"
            }
        }
    }

    // MARK: - Celebration Symbol

    private func celebrationSymbolName(
        _ vm: GameVM
    ) -> String {

        if app.isTeamsMode {

            let scores =
                Array(
                    vm.teamScores.prefix(
                        app.teamCount
                    )
                )

            guard !scores.isEmpty else {
                return "checkmark.seal.fill"
            }

            let leaderScore =
                scores.max() ?? 0

            let leaders =
                scores.filter {
                    $0 == leaderScore
                }

            if leaders.count > 1 {
                return "flag.2.crossed.fill"
            }

            return isStrongRound(vm)
                ? "sparkles"
                : "crown.fill"

        } else {

            return isStrongRound(vm)
                ? "sparkles"
                : "checkmark.seal.fill"
        }
    }

    private func celebrationSymbolColor(
        _ vm: GameVM
    ) -> Color {

        if app.isTeamsMode {

            let scores =
                Array(
                    vm.teamScores.prefix(
                        app.teamCount
                    )
                )

            let leaderScore =
                scores.max() ?? 0

            let leaders =
                scores.filter {
                    $0 == leaderScore
                }

            if leaders.count > 1 {
                return .orange
            }

            return isStrongRound(vm)
                ? .yellow
                : .blue
        }

        return isStrongRound(vm)
            ? .yellow
            : .green
    }

    private func leadingTeamIndex(
        in scores: [Int]
    ) -> Int {

        guard
            let maxScore = scores.max(),
            let index =
                scores.firstIndex(
                    of: maxScore
                )
        else {
            return 0
        }

        return index
    }

    // MARK: - Hero Summary

    private func heroSummaryCard(
        _ vm: GameVM
    ) -> some View {

        AppCard {

            VStack(spacing: 14) {

                Text("Round Summary")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(displayedScore)")
                    .font(
                        .system(
                            size: UIStyle.heroScoreSize,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .contentTransition(
                        .numericText()
                    )

                Text("Score")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {

                    metricBadge(
                        title: "Correct",
                        value: vm.correctCount,
                        systemImage:
                            "checkmark.circle.fill",
                        tint: .green
                    )
                    .opacity(
                        showCorrectBadge ? 1 : 0
                    )
                    .offset(
                        y:
                            showCorrectBadge
                            ? 0
                            : 10
                    )
                    .scaleEffect(
                        showCorrectBadge
                        ? 1
                        : 0.94
                    )

                    metricBadge(
                        title: "Skipped",
                        value: vm.skipCount,
                        systemImage:
                            "forward.fill",
                        tint: .orange
                    )
                    .opacity(
                        showSkippedBadge ? 1 : 0
                    )
                    .offset(
                        y:
                            showSkippedBadge
                            ? 0
                            : 10
                    )
                    .scaleEffect(
                        showSkippedBadge
                        ? 1
                        : 0.94
                    )

                    metricBadge(
                        title: "Best Streak",
                        value: vm.bestStreak,
                        systemImage:
                            "flame.fill",
                        tint: .blue
                    )
                    .opacity(
                        showStreakBadge ? 1 : 0
                    )
                    .offset(
                        y:
                            showStreakBadge
                            ? 0
                            : 10
                    )
                    .scaleEffect(
                        showStreakBadge
                        ? 1
                        : 0.94
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(
            showHeroSummary ? 1 : 0
        )
        .scaleEffect(
            showHeroSummary ? 1 : 0.96
        )
    }

    private func metricBadge(
        title: String,
        value: Int,
        systemImage: String,
        tint: Color
    ) -> some View {

        VStack(spacing: 6) {

            Image(systemName: systemImage)
                .foregroundStyle(tint)

            Text("\(value)")
                .font(.headline)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(
                cornerRadius:
                    UIStyle.smallCardCornerRadius,
                style: .continuous
            )
            .fill(
                tint.opacity(0.08)
            )
        )
    }

    // MARK: - Packs

    private var packsSummaryCard: some View {

        let selectedPacks =
            app.packs.filter {
                app.selectdPackIds.contains($0.id)
            }

        return AppCard {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                SectionHeaderLabel(
                    text: "Selected Packs",
                    systemImage:
                        "square.stack.3d.up"
                )

                Text(
                    "\(selectedPacks.isEmpty ? app.packs.count : selectedPacks.count) pack(s)"
                )
                .foregroundStyle(.secondary)

                if selectedPacks.isEmpty {

                    Text(
                        "Using all available packs."
                    )
                    .foregroundStyle(.secondary)

                } else {

                    ForEach(
                        selectedPacks.prefix(4)
                    ) { pack in

                        Text("• \(pack.title)")
                            .foregroundStyle(
                                .secondary
                            )
                    }

                    if selectedPacks.count > 4 {

                        Text(
                            "• +\(selectedPacks.count - 4) more"
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
            }
        }
    }

    // MARK: - Cumulative Teams

    private func cumulativeCard(
        _ vm: GameVM
    ) -> some View {

        AppCard {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                SectionHeaderLabel(
                    text: "Cumulative",
                    systemImage: "person.3.fill"
                )

                ForEach(
                    0..<app.teamCount,
                    id: \.self
                ) { index in

                    HStack {

                        Text(
                            teamName(
                                for: index
                            )
                        )

                        Spacer()

                        Text(
                            "\(safeTeamScore(vm, index: index))"
                        )
                        .font(.headline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Details

    private func detailsCard(
        _ vm: GameVM
    ) -> some View {

        let snapshot = vm.events

        let correct =
            snapshot.filter {
                $0.outcome == .correct
            }

        let skipped =
            snapshot.filter {
                $0.outcome == .pass
            }

        return AppCard {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                HStack {

                    SectionHeaderLabel(
                        text: "Details",
                        systemImage:
                            "list.bullet.rectangle"
                    )

                    Spacer()

                    Toggle(
                        "Timeline",
                        isOn: $showTimeline
                    )
                    .labelsHidden()
                }

                if snapshot.isEmpty {

                    Text(
                        "No actions recorded."
                    )
                    .foregroundStyle(.secondary)

                } else if showTimeline {

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        ForEach(snapshot) { event in

                            HStack(
                                alignment: .top,
                                spacing: 10
                            ) {

                                Image(
                                    systemName:
                                        event.outcome
                                            == .correct
                                        ? "checkmark.circle.fill"
                                        : "forward.fill"
                                )
                                .foregroundStyle(
                                    event.outcome
                                        == .correct
                                    ? .green
                                    : .orange
                                )

                                VStack(
                                    alignment: .leading,
                                    spacing: 3
                                ) {

                                    Text(
                                        event.cardText
                                    )

                                    if
                                        let teamIndex =
                                            event.teamIndex,
                                        app.isTeamsMode
                                    {

                                        Text(
                                            teamName(
                                                for:
                                                    teamIndex
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundStyle(
                                            .secondary
                                        )
                                    }
                                }

                                Spacer()

                                Text(
                                    event.timestamp,
                                    style: .time
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }
                    }

                } else {

                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {

                        if !correct.isEmpty {

                            groupedEventSection(
                                title: "Correct",
                                symbol:
                                    "checkmark.circle.fill",
                                tint: .green,
                                events: correct
                            )
                        }

                        if !skipped.isEmpty {

                            groupedEventSection(
                                title: "Skipped",
                                symbol:
                                    "forward.fill",
                                tint: .orange,
                                events: skipped
                            )
                        }
                    }
                }
            }
        }
    }

    private func groupedEventSection(
        title: String,
        symbol: String,
        tint: Color,
        events: [CardEvent]
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack(spacing: 8) {

                Image(systemName: symbol)
                    .foregroundStyle(tint)

                Text(
                    "\(title) (\(events.count))"
                )
                .font(.subheadline.bold())
            }

            ForEach(events) { event in

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text("• \(event.cardText)")
                        .foregroundStyle(
                            .secondary
                        )

                    if
                        let teamIndex =
                            event.teamIndex,
                        app.isTeamsMode
                    {

                        Text(
                            teamName(
                                for: teamIndex
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary.opacity(0.9)
                        )
                        .padding(
                            .leading,
                            12
                        )
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func actionsCard(
        _ vm: GameVM
    ) -> some View {

        AppCard {

            VStack(spacing: 14) {

                Text("What’s Next?")
                    .font(.headline)
                    .frame(
                        maxWidth: .infinity
                    )

                HStack(spacing: 12) {

                    // PLAY AGAIN / NEXT TEAM
                    resultActionButton(
                        title:
                            app.isTeamsMode
                            ? "Next Team"
                            : "Play Again",
                        systemImage:
                            "arrow.clockwise",
                        prominent: true
                    ) {
                        playAgain(vm)
                    }

                    // HOME
                    resultActionButton(
                        title: "Home",
                        systemImage:
                            "house.fill",
                        prominent: false
                    ) {

                        app.game = nil

                        withAnimation(
                            .easeInOut(
                                duration:
                                    UIStyle
                                        .standardAnimation
                            )
                        ) {
                            app.flow = .home
                        }
                    }

                    // SETTINGS
                    resultActionButton(
                        title: "Settings",
                        systemImage:
                            "gearshape.fill",
                        prominent: false
                    ) {

                        app.game = nil

                        withAnimation(
                            .easeInOut(
                                duration:
                                    UIStyle
                                        .standardAnimation
                            )
                        ) {
                            app.flow = .menu
                        }
                    }
                }

                if app.isTeamsMode {

                    Text(
                        "Up next: \(teamName(for: (vm.activeTeamIndex + 1) % app.teamCount))"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity
                    )
                }
            }
        }
    }

    // MARK: - Result Action Button

    @ViewBuilder
    private func resultActionButton(
        title: String,
        systemImage: String,
        prominent: Bool,
        action: @escaping () -> Void
    ) -> some View {

        if prominent {

            Button(action: action) {

                resultActionLabel(
                    title: title,
                    systemImage: systemImage
                )
            }
            .buttonStyle(.borderedProminent)

        } else {

            Button(action: action) {

                resultActionLabel(
                    title: title,
                    systemImage: systemImage
                )
            }
            .buttonStyle(.bordered)
        }
    }

    private func resultActionLabel(
        title: String,
        systemImage: String
    ) -> some View {

        VStack(spacing: 8) {

            Image(systemName: systemImage)
                .font(
                    .system(
                        size: 22,
                        weight: .semibold
                    )
                )

            Text(title)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 74)
    }

    // MARK: - Play Again / Next Team

    private func playAgain(
        _ vm: GameVM
    ) {

        if app.isTeamsMode {
            vm.advanceTeamForNextRoundIfNeeded()
        }

        let words =
            buildWordsForNextRound()

        if !words.isEmpty {

            vm.setDeck(words)

        } else {

            vm.restartRoundKeepingTeams()
        }

        withAnimation(
            .easeInOut(
                duration:
                    UIStyle.standardAnimation
            )
        ) {
            app.flow = .game
        }
    }

    // MARK: - No Game

    private var noGameCard: some View {

        AppCard {

            VStack(spacing: 14) {

                Image(
                    systemName:
                        "exclamationmark.circle"
                )
                .font(.title)
                .foregroundStyle(.secondary)

                Text("No active game.")
                    .font(.headline)

                Button {
                    withAnimation(
                        .easeInOut(
                            duration:
                                UIStyle
                                    .standardAnimation
                        )
                    ) {
                        app.flow = .home
                    }

                } label: {

                    Label(
                        "Back to Home",
                        systemImage: "house.fill"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(
                        height:
                            UIStyle
                                .primaryButtonHeight
                    )
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private func buildWordsForNextRound()
        -> [String] {

        let selected =
            app.packs.filter {
                app.selectdPackIds.contains(
                    $0.id
                )
            }

        let packsToUse =
            selected.isEmpty
            ? app.packs
            : selected

        return packsToUse.flatMap {
            $0.cards
        }
    }

    private func teamName(
        for index: Int
    ) -> String {

        if app.teamNames.indices.contains(
            index
        ) {
            return app.teamNames[index]
        }

        return "Team \(index + 1)"
    }

    private func safeTeamScore(
        _ vm: GameVM,
        index: Int
    ) -> Int {

        guard
            vm.teamScores.indices.contains(index)
        else {
            return 0
        }

        return vm.teamScores[index]
    }

    // MARK: - Animation Setup

    private func prepareResultsAnimation() {

        app.loadPacksIfNeeded()

        showCelebration = false
        showHeroSummary = false
        displayedScore = 0

        showCorrectBadge = false
        showSkippedBadge = false
        showStreakBadge = false

        showSparkleAccent = false

        playResultsHaptic()

        withAnimation(
            .easeOut(duration: 0.28)
        ) {
            showCelebration = true
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.12
        ) {

            withAnimation(
                .spring(
                    response: 0.38,
                    dampingFraction: 0.82
                )
            ) {
                showHeroSummary = true
            }

            if let vm = app.game {

                animateScore(
                    to: vm.score
                )

                if isStrongRound(vm) {

                    withAnimation(
                        .easeOut(
                            duration: 0.35
                        )
                    ) {
                        showSparkleAccent = true
                    }
                }
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.24
        ) {
            withAnimation(
                .spring(
                    response: 0.34,
                    dampingFraction: 0.82
                )
            ) {
                showCorrectBadge = true
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.32
        ) {
            withAnimation(
                .spring(
                    response: 0.34,
                    dampingFraction: 0.82
                )
            ) {
                showSkippedBadge = true
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.40
        ) {
            withAnimation(
                .spring(
                    response: 0.34,
                    dampingFraction: 0.82
                )
            ) {
                showStreakBadge = true
            }
        }
    }

    // MARK: - Score Count Up

    private func animateScore(
        to finalScore: Int
    ) {

        displayedScore = 0

        guard finalScore != 0 else {
            return
        }

        let direction =
            finalScore > 0 ? 1 : -1

        let steps =
            abs(finalScore)

        let totalDuration: Double =
            0.6

        let stepDuration =
            max(
                0.02,
                totalDuration
                    / Double(
                        max(steps, 1)
                    )
            )

        for step in 1...steps {

            DispatchQueue.main.asyncAfter(
                deadline:
                    .now()
                    + Double(step)
                    * stepDuration
            ) {

                displayedScore =
                    step * direction
            }
        }
    }

    // MARK: - Haptic

    private func playResultsHaptic() {

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

    // MARK: - Strong Round

    private func isStrongRound(
        _ vm: GameVM
    ) -> Bool {

        if app.isTeamsMode {

            return
                vm.score >= 5
                || vm.bestStreak >= 4

        } else {

            return
                vm.score >= 6
                || vm.bestStreak >= 5
        }
    }
}
