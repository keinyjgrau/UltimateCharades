//
//  GameVM.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-07.
//


import Foundation
import Combine

@MainActor
final class GameVM: ObservableObject {

    enum State: Equatable {
        case countdown(Int)
        case playing
        case ended
    }

    private unowned let app: AppState

    // MARK: - Published UI State

    @Published private(set) var state: State = .countdown(3)
    @Published private(set) var timeRemaining: Int = 60
    @Published private(set) var currentWord: String = "—"

    @Published private(set) var score: Int = 0
    @Published private(set) var correctCount: Int = 0
    @Published private(set) var skipCount: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var streak: Int = 0

    @Published private(set) var isPaused: Bool = false

    // MARK: - Results Details

    @Published private(set) var events: [CardEvent] = []

    // MARK: - Teams

    @Published private(set) var activeTeamIndex: Int = 0

    @Published private(set) var teamScores: [Int] = [
        0, 0, 0, 0
    ]

    @Published private(set) var nextTeamName: String = ""

    // MARK: - Round Word Pools

    /*
     unseenWords
     -----------
     Cards that have NOT appeared yet during this round.

     skippedWords
     ------------
     Cards skipped during this round.
     They are kept only for Results/statistics.
     They NEVER return during the same round.

     usedCorrectWords
     ----------------
     Cards guessed correctly.
     They also NEVER return during the same round.
     */

    private var unseenWords: [String] = []
    private var skippedWords: [String] = []
    private var usedCorrectWords: [String] = []

    // MARK: - Runtime

    private var timerTask: Task<Void, Never>? = nil

    private var consecutiveSkips: Int = 0

    private var didBankThisRound: Bool = false

    private var isEndingRound: Bool = false

    // MARK: - Public Round Counts

    var unseenCount: Int {
        unseenWords.count
    }

    /*
     We keep this property name because GameplayView
     already uses it.

     It now means "number skipped this round",
     NOT words waiting to return.
     */
    var skippedPendingCount: Int {
        skippedWords.count
    }

    var usedCorrectCount: Int {
        usedCorrectWords.count
    }

    // MARK: - Init

    init(app: AppState) {
        self.app = app

        self.timeRemaining = app.roundSeconds

        buildDeckFallback()

        updateNextTeamLabel()

        startCountdownAndRound()
    }

    deinit {
        timerTask?.cancel()
    }

    // MARK: - Flow

    func endAndGoToResults() {

        guard !isEndingRound else {
            return
        }

        isEndingRound = true

        stopTimer()

        isPaused = false

        state = .ended

        bankRoundIfNeeded()

        app.flow = .results
    }

    // MARK: - Team Score Banking

    func bankRoundIfNeeded() {

        guard app.isTeamsMode else {
            return
        }

        guard !didBankThisRound else {
            return
        }

        guard teamScores.indices.contains(
            activeTeamIndex
        ) else {
            return
        }

        teamScores[activeTeamIndex] += score

        didBankThisRound = true
    }

    func advanceTeamForNextRoundIfNeeded() {

        guard app.isTeamsMode else {
            return
        }

        activeTeamIndex =
            (activeTeamIndex + 1)
            % app.teamCount

        updateNextTeamLabel()
    }

    // MARK: - Deck Injection

    func setDeck(
        _ words: [String],
        restart: Bool = true
    ) {

        let cleaned =
            sanitizeWords(words)

        guard !cleaned.isEmpty else {
            return
        }

        prepareRoundPools(
            from: cleaned
        )

        // Reset round statistics
        score = 0
        correctCount = 0
        skipCount = 0
        bestStreak = 0
        streak = 0

        consecutiveSkips = 0

        isPaused = false

        events = []

        didBankThisRound = false
        isEndingRound = false

        timeRemaining =
            app.roundSeconds

        state = .countdown(3)

        currentWord = "—"

        if restart {

            startCountdownAndRound()

        } else {

            showNextWord()
        }
    }

    // MARK: - Restart

    func restartRoundKeepingTeams() {

        stopTimer()

        state = .countdown(3)

        score = 0
        correctCount = 0
        skipCount = 0
        bestStreak = 0
        streak = 0

        consecutiveSkips = 0

        isPaused = false

        events = []

        didBankThisRound = false
        isEndingRound = false

        timeRemaining =
            app.roundSeconds

        currentWord = "—"

        /*
         Starting a NEW round means all cards become
         eligible again, including cards skipped in the
         previous round.
         */

        let sourceWords =
            usedCorrectWords
            + skippedWords
            + unseenWords

        let cleaned =
            sanitizeWords(sourceWords)

        if !cleaned.isEmpty {

            prepareRoundPools(
                from: cleaned
            )
        }

        startCountdownAndRound()
    }

    // MARK: - Pause

    func togglePause() {

        guard state == .playing else {
            return
        }

        guard !isEndingRound else {
            return
        }

        isPaused.toggle()
    }

    // MARK: - Correct

    func onCorrect() {

        guard state == .playing else {
            return
        }

        guard !isPaused else {
            return
        }

        guard !isEndingRound else {
            return
        }

        guard
            currentWord != "—",
            currentWord != "No words!",
            currentWord != "No more cards!"
        else {
            return
        }

        let word =
            currentWord

        let team =
            app.isTeamsMode
            ? activeTeamIndex
            : nil

        events.append(
            CardEvent(
                cardText: word,
                outcome: .correct,
                teamIndex: team
            )
        )

        // Correct cards are permanently out
        // for the remainder of THIS round.
        usedCorrectWords.append(
            word
        )

        score += 1
        correctCount += 1

        streak += 1

        bestStreak =
            max(
                bestStreak,
                streak
            )

        consecutiveSkips = 0

        showNextWord()
    }

    // MARK: - Skip

    func onSkip() {

        guard state == .playing else {
            return
        }

        guard !isPaused else {
            return
        }

        guard !isEndingRound else {
            return
        }

        guard
            currentWord != "—",
            currentWord != "No words!",
            currentWord != "No more cards!"
        else {
            return
        }

        let word =
            currentWord

        let team =
            app.isTeamsMode
            ? activeTeamIndex
            : nil

        events.append(
            CardEvent(
                cardText: word,
                outcome: .pass,
                teamIndex: team
            )
        )

        /*
         IMPORTANT CHANGE:

         The skipped card is stored for Results,
         but NEVER placed back in unseenWords.
         */

        skippedWords.append(
            word
        )

        skipCount += 1

        streak = 0

        consecutiveSkips += 1

        if app.isTeamsMode &&
            consecutiveSkips >= 2 {

            score -= 1

            consecutiveSkips = 0
        }

        showNextWord()
    }

    // MARK: - Countdown + Timer

    private func startCountdownAndRound() {

        stopTimer()

        state = .countdown(3)

        timerTask =
            Task { [weak self] in

                guard let self else {
                    return
                }

                // 3...2...1
                for value in stride(
                    from: 3,
                    through: 1,
                    by: -1
                ) {

                    self.state =
                        .countdown(value)

                    try? await Task.sleep(
                        nanoseconds:
                            700_000_000
                    )
                }

                guard !Task.isCancelled else {
                    return
                }

                self.state = .playing

                self.timeRemaining =
                    self.app.roundSeconds

                self.showNextWord()

                // Timer
                while
                    !Task.isCancelled
                    && self.timeRemaining > 0
                    && self.state == .playing
                {

                    // Pause support
                    while
                        !Task.isCancelled
                        && self.isPaused
                    {

                        try? await Task.sleep(
                            nanoseconds:
                                200_000_000
                        )
                    }

                    guard !Task.isCancelled else {
                        break
                    }

                    /*
                     showNextWord() can automatically
                     end the round when cards run out.
                     */

                    guard
                        self.state == .playing,
                        !self.isEndingRound
                    else {
                        break
                    }

                    try? await Task.sleep(
                        nanoseconds:
                            1_000_000_000
                    )

                    if
                        !self.isPaused,
                        self.state == .playing
                    {

                        self.timeRemaining -= 1
                    }
                }

                /*
                 Only end from the timer if the
                 round hasn't already ended because
                 the deck was exhausted.
                 */

                if
                    !Task.isCancelled,
                    self.state == .playing,
                    !self.isEndingRound
                {

                    self.endAndGoToResults()
                }
            }
    }

    private func stopTimer() {

        timerTask?.cancel()

        timerTask = nil
    }

    // MARK: - Word Pools

    private func sanitizeWords(
        _ words: [String]
    ) -> [String] {

        words
            .map {
                $0.trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }
    }

    private func prepareRoundPools(
        from words: [String]
    ) {

        // Fresh shuffled deck
        unseenWords =
            words.shuffled()

        skippedWords = []

        usedCorrectWords = []
    }

    // MARK: - Next Card

    private func showNextWord() {

        /*
         NO MORE RECYCLING SKIPPED WORDS.

         Once unseenWords is empty, every card in
         the round has already been shown once.
         */

        guard !unseenWords.isEmpty else {

            currentWord =
                "No more cards!"

            finishRoundBecauseCardsAreExhausted()

            return
        }

        currentWord =
            unseenWords.removeFirst()
    }

    // MARK: - Automatic End When Deck Finishes

    private func finishRoundBecauseCardsAreExhausted() {

        guard state == .playing else {
            return
        }

        guard !isEndingRound else {
            return
        }

        /*
         Tiny delay so Correct/Skip feedback can
         finish visually before Results appears.
         */

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.30
        ) { [weak self] in

            guard let self else {
                return
            }

            guard
                self.state == .playing,
                !self.isEndingRound
            else {
                return
            }

            self.endAndGoToResults()
        }
    }

    // MARK: - Fallback Deck

    private func buildDeckFallback() {

        let fallback = [
            "Elephant",
            "Guitar",
            "New York",
            "Spider-Man",
            "Volcano",
            "Pizza",
            "Dinosaur",
            "Astronaut",
            "Hurricane",
            "Ballet"
        ]

        prepareRoundPools(
            from: fallback
        )
    }

    // MARK: - Next Team

    private func updateNextTeamLabel() {

        if app.isTeamsMode {

            let next =
                (activeTeamIndex + 1)
                % app.teamCount

            let safeNames =
                app.teamNames

            nextTeamName =
                safeNames.indices.contains(
                    next
                )
                ? safeNames[next]
                : "Next Team"

        } else {

            nextTeamName = ""
        }
    }
}
