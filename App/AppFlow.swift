//
//  AppFlow.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-07.
//
import Foundation

enum AppFlow: Equatable {
    case boot
    case home
    case menu       // Game settings for now
    case game
    case results
    case info       // NEW
}
