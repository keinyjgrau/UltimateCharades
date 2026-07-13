//
//  MainMenuView.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-02-07.
//


import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var app: AppState
    @State private var errorText: String? = nil

    private var visiblePacks: [Pack] {
        let selectedCategory = app.category
        if selectedCategory == "All" { return app.packs }

        return app.packs.filter { pack in
            let cats = pack.categories ?? []
            return cats.contains(selectedCategory)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color(.secondarySystemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    if isLandscape {
                        landscapeLayout
                    } else {
                        portraitLayout
                    }
                }
                .padding(UIStyle.screenPadding)
                .padding(.bottom, 20)
            }
            .onAppear {
                app.loadPacksIfNeeded()

                if app.packs.isEmpty {
                    errorText = "packs.json loaded, but no packs decoded. Check JSON structure."
                } else {
                    errorText = nil
                }

                if app.selectdPackIds.isEmpty {
                    app.selectdPackIds = Set(app.packs.map { $0.id })
                }

                let cats = Set(allCategories())
                if !cats.contains(app.category) {
                    app.category = "All"
                }
            }
        }
    }

    // MARK: - Layouts

    private var portraitLayout: some View {
        VStack(spacing: UIStyle.sectionSpacing) {
            headerCard

            if let errorText {
                messageCard(errorText, isError: true)
            }

            if app.packs.isEmpty {
                messageCard("No packs found. Make sure packs.json is included in the app target.", isError: false)
            } else {
                settingsCard
                categoryCard
                packsCard
                startCard
            }
        }
    }

    private var landscapeLayout: some View {
        VStack(spacing: UIStyle.sectionSpacing) {
            headerCard

            if let errorText {
                messageCard(errorText, isError: true)
            }

            if app.packs.isEmpty {
                messageCard("No packs found. Make sure packs.json is included in the app target.", isError: false)
            } else {
                HStack(alignment: .top, spacing: UIStyle.sectionSpacing) {
                    VStack(spacing: UIStyle.sectionSpacing) {
                        settingsCard
                        categoryCard
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: UIStyle.sectionSpacing) {
                        packsCard
                        startCard
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.system(size: UIStyle.pageTitleSize, weight: .bold, design: .rounded))

                HStack {
                    LabelPill(text: "Timer \(app.roundSeconds)s")
                    LabelPill(text: app.isTeamsMode ? "Teams" : "Free-for-all")
                    LabelPill(text: "\(selectedPackCount()) Packs")
                }
            }
        }
    }

    // MARK: - Settings

    private var settingsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderLabel(text: "Game Settings", systemImage: "slider.horizontal.3")

                settingRow("Timer") {
                    Picker("Timer", selection: $app.timerIdx) {
                        Text("30s").tag(0)
                        Text("45s").tag(1)
                        Text("60s").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                settingRow("Mode") {
                    Picker("Mode", selection: $app.modeIdx) {
                        Text("Free-for-all").tag(0)
                        Text("Teams").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                if app.isTeamsMode {
                    settingRow("Teams") {
                        Picker("Teams", selection: $app.teamCountIdx) {
                            Text("2").tag(0)
                            Text("3").tag(1)
                            Text("4").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Team Names")
                            .font(.subheadline.bold())

                        ForEach(0..<app.teamCount, id: \.self) { i in
                            TextField("Team \(i + 1)", text: Binding(
                                get: { app.teamNames[i] },
                                set: { newValue in
                                    var names = app.teamNames
                                    names[i] = newValue.isEmpty ? "Team \(i + 1)" : newValue
                                    app.teamNames = names
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                        }
                    }
                }

                Divider()

                settingRow("Haptics") {
                    Picker("Haptics", selection: $app.hapticsIdx) {
                        Text("Off").tag(0)
                        Text("Light").tag(1)
                        Text("Strong").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Toggle("Sound", isOn: $app.soundOn)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Volume")
                        Spacer()
                        Text("\(Int(app.soundVol * 100))%")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(app.soundVol) },
                        set: { app.soundVol = Float($0) }
                    ), in: 0...1)
                    .disabled(!app.soundOn)
                    .opacity(app.soundOn ? 1.0 : 0.45)
                }

                Toggle("Allow Adult Content", isOn: $app.allowAdultContent)
                Toggle("Tilt Mode", isOn: $app.tiltModeOn)
            }
        }
    }

    // MARK: - Category

    private var categoryCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderLabel(text: "Category", systemImage: "square.grid.2x2")

                Picker("Category", selection: $app.category) {
                    ForEach(allCategories(), id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(.menu)

                Text("Showing \(visiblePacks.count) pack(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Packs

    private var packsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderLabel(text: "Packs", systemImage: "square.stack.3d.up")

                if visiblePacks.isEmpty {
                    Text("No packs match this category.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(visiblePacks) { pack in
                            packRow(pack)
                        }
                    }
                }
            }
        }
    }

    private func packRow(_ pack: Pack) -> some View {
        let isSelected = app.selectdPackIds.contains(pack.id)

        return Button {
            togglePack(pack.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .green : .secondary)
                    .imageScale(.large)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let cats = pack.categories, !cats.isEmpty {
                        Text(cats.joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("\(pack.cards.count) cards")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(pack.language.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("\(pack.cards.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: UIStyle.smallCardCornerRadius, style: .continuous)
                    .fill(isSelected ? Color.green.opacity(0.10) : .thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIStyle.smallCardCornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.green.opacity(0.30) : Color.black.opacity(0.04), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Start

    private var startCard: some View {
        AppCard {
            VStack(spacing: 12) {
                Button {
                    startGame()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Start Game")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: UIStyle.primaryButtonHeight)
                }
                .buttonStyle(.borderedProminent)
                .disabled(visiblePacks.isEmpty)

                Button("Back to Home") {
                    withAnimation(.easeInOut(duration: UIStyle.standardAnimation)) {
                        app.flow = .home
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .frame(height: UIStyle.primaryButtonHeight)
            }
        }
    }

    // MARK: - Helpers

    private func allCategories() -> [String] {
        var set = Set<String>()
        for p in app.packs {
            for c in (p.categories ?? []) {
                let trimmed = c.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { set.insert(trimmed) }
            }
        }
        return ["All"] + set.sorted()
    }

    private func togglePack(_ id: String) {
        if app.selectdPackIds.contains(id) {
            app.selectdPackIds.remove(id)
        } else {
            app.selectdPackIds.insert(id)
        }
    }

    private func startGame() {
        let selected = visiblePacks.filter { app.selectdPackIds.contains($0.id) }
        let packsToUse = selected.isEmpty ? visiblePacks : selected

        let words = packsToUse.flatMap { $0.cards }
        guard !words.isEmpty else {
            errorText = "No cards available in the selected packs."
            return
        }

        let vm = GameVM(app: app)
        vm.setDeck(words)

        app.game = vm

        withAnimation(.easeInOut(duration: UIStyle.standardAnimation)) {
            app.flow = .game
        }
    }

    private func selectedPackCount() -> Int {
        let selected = app.packs.filter { app.selectdPackIds.contains($0.id) }
        return selected.isEmpty ? app.packs.count : selected.count
    }

    @ViewBuilder
    private func settingRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
            content()
        }
    }

    @ViewBuilder
    private func messageCard(_ text: String, isError: Bool) -> some View {
        AppCard {
            Text(text)
                .foregroundStyle(isError ? .red : .secondary)
        }
    }
}

