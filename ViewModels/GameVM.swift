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

    // Published UI state
    @Published private(set) var state: State = .countdown(3)
    @Published private(set) var timeRemaining: Int = 60
    @Published private(set) var currentWord: String = "—"
    @Published private(set) var score: Int = 0
    @Published private(set) var correctCount: Int = 0
    @Published private(set) var skipCount: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var streak: Int = 0
    @Published private(set) var isPaused: Bool = false

    // Results details
    @Published private(set) var events: [CardEvent] = []

    // Teams foundation
    @Published private(set) var activeTeamIndex: Int = 0
    @Published private(set) var teamScores: [Int] = [0,0,0,0]
    @Published private(set) var nextTeamName: String = ""

    // NEW: Round word pools
    private var unseenWords: [String] = []
    private var skippedWords: [String] = []
    private var usedCorrectWords: [String] = []

    private var timerTask: Task<Void, Never>? = nil
    private var consecutiveSkips: Int = 0
    private var didBankThisRound: Bool = false
    private var isEndingRound: Bool = false
    
    //Properties
    var unseenCount: Int {unseenWords.count}
    var skippedPendingCount: Int {skippedWords.count}
    var usedCorrectCount: Int {usedCorrectWords.count}

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
        guard !isEndingRound else { return }
        isEndingRound = true

        stopTimer()
        isPaused = false
        state = .ended

        bankRoundIfNeeded()
        app.flow = .results
    }

    func bankRoundIfNeeded() {
        guard app.isTeamsMode else { return }
        guard !didBankThisRound else { return }
        teamScores[activeTeamIndex] += score
        didBankThisRound = true
    }

    func advanceTeamForNextRoundIfNeeded() {
        guard app.isTeamsMode else { return }
        activeTeamIndex = (activeTeamIndex + 1) % app.teamCount
        updateNextTeamLabel()
    }

    // MARK: - Deck injection

    func setDeck(_ words: [String], restart: Bool = true) {
        let cleaned = sanitizeWords(words)
        guard !cleaned.isEmpty else { return }

        prepareRoundPools(from: cleaned)

        // Reset round stats
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

        timeRemaining = app.roundSeconds
        state = .countdown(3)
        currentWord = "—"

        if restart {
            startCountdownAndRound()
        } else {
            showNextWord()
        }
    }

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

        timeRemaining = app.roundSeconds
        currentWord = "—"

        // Rebuild from the same current round content:
        let sourceWords = usedCorrectWords + skippedWords + unseenWords
        let cleaned = sanitizeWords(sourceWords)
        if !cleaned.isEmpty {
            prepareRoundPools(from: cleaned)
        }

        startCountdownAndRound()
    }

    // MARK: - Pause

    func togglePause() {
        guard state == .playing else { return }
        guard !isEndingRound else { return }
        isPaused.toggle()
    }

    // MARK: - Actions

    func onCorrect() {
        guard state == .playing else { return }
        guard !isPaused else { return }
        guard !isEndingRound else { return }
        guard currentWord != "—", currentWord != "No words!" else { return }

        let word = currentWord

        let team = app.isTeamsMode ? activeTeamIndex : nil
        events.append(CardEvent(cardText: word, outcome: .correct, teamIndex: team))

        usedCorrectWords.append(word)

        score += 1
        correctCount += 1
        streak += 1
        bestStreak = max(bestStreak, streak)
        consecutiveSkips = 0

        showNextWord()
    }

    func onSkip() {
        guard state == .playing else { return }
        guard !isPaused else { return }
        guard !isEndingRound else { return }
        guard currentWord != "—", currentWord != "No words!" else { return }

        let word = currentWord

        let team = app.isTeamsMode ? activeTeamIndex : nil
        events.append(CardEvent(cardText: word, outcome: .pass, teamIndex: team))

        skippedWords.append(word)

        skipCount += 1
        streak = 0
        consecutiveSkips += 1

        if app.isTeamsMode && consecutiveSkips >= 2 {
            score -= 1
            consecutiveSkips = 0
        }

        showNextWord()
    }

    // MARK: - Countdown + Timer

    private func startCountdownAndRound() {
        stopTimer()
        state = .countdown(3)

        timerTask = Task { [weak self] in
            guard let self else { return }

            for t in stride(from: 3, through: 1, by: -1) {
                self.state = .countdown(t)
                try? await Task.sleep(nanoseconds: 700_000_000)
            }

            self.state = .playing
            self.timeRemaining = self.app.roundSeconds
            self.showNextWord()

            while !Task.isCancelled && self.timeRemaining > 0 {
                while !Task.isCancelled && self.isPaused {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }
                guard !Task.isCancelled else { break }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !self.isPaused {
                    self.timeRemaining -= 1
                }
            }

            if !Task.isCancelled {
                self.endAndGoToResults()
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Round word pools

    private func sanitizeWords(_ words: [String]) -> [String] {
        words
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func prepareRoundPools(from words: [String]) {
        unseenWords = words.shuffled()
        skippedWords = []
        usedCorrectWords = []
    }

    private func showNextWord() {
        if unseenWords.isEmpty {
            if !skippedWords.isEmpty {
                unseenWords = skippedWords.shuffled()
                skippedWords = []
            }
        }

        guard !unseenWords.isEmpty else {
            currentWord = "No words!"
            return
        }

        currentWord = unseenWords.removeFirst()
    }

    // MARK: - Fallback deck

    private func buildDeckFallback() {
        let fallback = [
            "Elephant","Guitar","New York","Spider-Man","Volcano",
            "Pizza","Dinosaur","Astronaut","Hurricane","Ballet"
        ]
        prepareRoundPools(from: fallback)
    }

    private func updateNextTeamLabel() {
        if app.isTeamsMode {
            let next = (activeTeamIndex + 1) % app.teamCount
            let safeNames = app.teamNames
            nextTeamName = safeNames.indices.contains(next) ? safeNames[next] : "Next Team"
        } else {
            nextTeamName = ""
        }
    }
}
