//
//  PackStore.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-08.
//

import Foundation

enum PackStore {
    static func loadPacks() -> [Pack] {
        guard let url = Bundle.main.url(forResource: "packs", withExtension: "json") else {
            print("❌ packs.json not found in app bundle. Check Target Membership / Copy Bundle Resources.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Pack].self, from: data)
        } catch {
            print("❌ Failed to load/decode packs.json:", error)
            return []
        }
    }
}
