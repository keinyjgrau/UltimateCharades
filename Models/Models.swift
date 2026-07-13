//
//  Models.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-08.
//

import Foundation

struct Card: Identifiable, Equatable, Codable {
    let id: UUID
    let text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

struct Pack: Identifiable, Equatable, Codable {
    let id: String           // e.g. "base", "movies_es"
    let title: String        // display name
    let language: String     // "en", "es"
    let cards: [String]
    let categories: [String]?
}

enum CardOutcome: String, Codable {
    case correct
    case pass
}

struct CardEvent: Identifiable, Codable {
    let id: UUID
    let cardText: String
    let outcome: CardOutcome
    let timestamp: Date
    let teamIndex: Int?

    init(id: UUID = UUID(), cardText: String, outcome: CardOutcome, timestamp: Date = .init(), teamIndex: Int? = nil) {
        self.id = id
        self.cardText = cardText
        self.outcome = outcome
        self.timestamp = timestamp
        self.teamIndex = teamIndex
    }
}

