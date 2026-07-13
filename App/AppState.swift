//
//  AppState.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-07.
//
import Foundation
import Combine

final class AppState: ObservableObject {

    // MARK: - Flow
    @Published var flow: AppFlow = .boot

    // MARK: - Active Game Session
    @Published var game: GameVM? = nil

    // MARK: - Content Packs Cache
    @Published var packs: [Pack] = []

    func loadPacksIfNeeded() {
        if packs.isEmpty {
            packs = PackStore.loadPacks()
        }
    }

    // MARK: - Game Options
    @Published var timerIdx: Int = 2          // 0:30 1:45 2:60
    @Published var modeIdx: Int = 0           // 0:FFA 1:Teams

    // MARK: - Teams
    @Published var teamCountIdx: Int = 0      // 0:2 1:3 2:4
    @Published var teamNames: [String] = ["Team 1","Team 2","Team 3","Team 4"]

    // MARK: - Content
    @Published var difficultyIdx: Int = 2     // 0:Easy 1:Expert 2:Mix
    @Published var languageIdx: Int = 0       // 0:en 1:es
    @Published var category: String = "All"
    @Published var selectdPackIds: Set<String> = []

    // MARK: - Settings
    @Published var soundOn: Bool = true
    @Published var soundVol: Float = 0.8
    @Published var hapticsIdx: Int = 2
    @Published var allowAdultContent: Bool = false
    @Published var tiltModeOn: Bool = false
    
    // MARK: - Helpers
    var roundSeconds: Int { [30,45,60][max(0, min(timerIdx, 2))] }
    var teamCount: Int { [2,3,4][max(0, min(teamCountIdx, 2))] }
    var languageCode: String { languageIdx == 1 ? "es" : "en" }

    // MARK: - Convenience
    var isTeamsMode: Bool { modeIdx == 1 }

    // MARK: - Persistence
    private let defaults = UserDefaults.standard
    private var cancellables: Set<AnyCancellable> = []

    private enum Keys {
        static let timerIdx = "settings.timerIdx"
        static let modeIdx = "settings.modeIdx"
        static let teamCountIdx = "settings.teamCountIdx"
        static let teamNames = "settings.teamNames"

        static let difficultyIdx = "settings.difficultyIdx"
        static let languageIdx = "settings.languageIdx"
        static let category = "settings.category"
        static let selectedPackIds = "settings.selectedPackIds"

        static let soundOn = "settings.soundOn"
        static let soundVol = "settings.soundVol"
        static let hapticsIdx = "settings.hapticsIdx"
        static let allowAdultContent = "settings.allowAdultContent"
        
        static let tiltModeOn = "settings.tiltModeOn"
    }

    init() {
        loadPersistedSettings()
        setupAutoSave()
    }

    private func loadPersistedSettings() {
        // Ints
        if defaults.object(forKey: Keys.timerIdx) != nil {
            timerIdx = defaults.integer(forKey: Keys.timerIdx)
        }
        if defaults.object(forKey: Keys.modeIdx) != nil {
            modeIdx = defaults.integer(forKey: Keys.modeIdx)
        }
        if defaults.object(forKey: Keys.teamCountIdx) != nil {
            teamCountIdx = defaults.integer(forKey: Keys.teamCountIdx)
        }
        if defaults.object(forKey: Keys.difficultyIdx) != nil {
            difficultyIdx = defaults.integer(forKey: Keys.difficultyIdx)
        }
        if defaults.object(forKey: Keys.languageIdx) != nil {
            languageIdx = defaults.integer(forKey: Keys.languageIdx)
        }
        if defaults.object(forKey: Keys.hapticsIdx) != nil {
            hapticsIdx = defaults.integer(forKey: Keys.hapticsIdx)
        }

        // Bools
        if defaults.object(forKey: Keys.soundOn) != nil {
            soundOn = defaults.bool(forKey: Keys.soundOn)
        }
        if defaults.object(forKey: Keys.allowAdultContent) != nil {
            allowAdultContent = defaults.bool(forKey: Keys.allowAdultContent)
        }
        if defaults.object(forKey: Keys.tiltModeOn) != nil {
            tiltModeOn = defaults.bool(forKey: Keys.tiltModeOn)
        }

        // Float
        if defaults.object(forKey: Keys.soundVol) != nil {
            soundVol = defaults.float(forKey: Keys.soundVol)
        }

        // Strings
        if let cat = defaults.string(forKey: Keys.category) {
            category = cat
        }

        // Arrays
        if let names = defaults.array(forKey: Keys.teamNames) as? [String], !names.isEmpty {
            // Keep exactly 4 slots to match your UI
            var padded = names
            if padded.count < 4 { padded += Array(repeating: "Team", count: 4 - padded.count) }
            teamNames = Array(padded.prefix(4))
        }

        // Set<String> saved as [String]
        if let ids = defaults.array(forKey: Keys.selectedPackIds) as? [String] {
            selectdPackIds = Set(ids)
        }
    }

    private func setupAutoSave() {
        // Ints
        $timerIdx
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.timerIdx) }
            .store(in: &cancellables)

        $modeIdx
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.modeIdx) }
            .store(in: &cancellables)

        $teamCountIdx
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.teamCountIdx) }
            .store(in: &cancellables)

        $difficultyIdx
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.difficultyIdx) }
            .store(in: &cancellables)

        $languageIdx
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.languageIdx) }
            .store(in: &cancellables)

        $hapticsIdx
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.hapticsIdx) }
            .store(in: &cancellables)

        // Bools
        $soundOn
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.soundOn) }
            .store(in: &cancellables)

        $allowAdultContent
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.allowAdultContent) }
            .store(in: &cancellables)
        
        $tiltModeOn
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.tiltModeOn) }
            .store(in: &cancellables)

        // Float
        $soundVol
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.soundVol) }
            .store(in: &cancellables)

        // Strings
        $category
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.category) }
            .store(in: &cancellables)

        // Arrays
        $teamNames
            .dropFirst()
            .sink { [weak self] v in self?.defaults.set(v, forKey: Keys.teamNames) }
            .store(in: &cancellables)

        // Set<String> as [String]
        $selectdPackIds
            .dropFirst()
            .sink { [weak self] set in
                self?.defaults.set(Array(set).sorted(), forKey: Keys.selectedPackIds)
            }
            .store(in: &cancellables)
    }
}
