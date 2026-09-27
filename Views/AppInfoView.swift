//
//  AppInfoView.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-09-26.
//



import SwiftUI

struct AppInfoView: View {
    @EnvironmentObject var app: AppState

    private var versionText: String {
        let version =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? "1.0"

        let build =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleVersion"
            ) as? String ?? "1"

        return "Version \(version) (\(build))"
    }

    var body: some View {
        ZStack {

            background

            ScrollView {
                VStack(spacing: UIStyle.sectionSpacing) {

                    // MARK: Header

                    VStack(spacing: 8) {
                        Image(systemName: "theatermasks.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)

                        Text("Ultimate Charades")
                            .font(
                                .system(
                                    size: UIStyle.pageTitleSize,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .multilineTextAlignment(.center)

                        Text(versionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)

                    // MARK: About

                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {

                            SectionHeaderLabel(
                                text: "About",
                                systemImage: "info.circle.fill"
                            )

                            Text(
                                "Ultimate Charades is a fast party game for friends and family. Pick your packs, start a round, and act out or guess as many cards as you can before time runs out."
                            )
                            .foregroundStyle(.secondary)
                        }
                    }

                    // MARK: How To Play

                    AppCard {
                        VStack(alignment: .leading, spacing: 14) {

                            SectionHeaderLabel(
                                text: "How to Play",
                                systemImage: "gamecontroller.fill"
                            )

                            instructionRow(
                                number: "1",
                                title: "Choose your game",
                                text: "Select your timer, mode and card packs in Settings."
                            )

                            instructionRow(
                                number: "2",
                                title: "Start the round",
                                text: "When the countdown finishes, the first card appears."
                            )

                            instructionRow(
                                number: "3",
                                title: "Correct or Skip",
                                text: "Mark the card Correct when guessed, or Skip to move on."
                            )

                            instructionRow(
                                number: "4",
                                title: "Check the results",
                                text: "At the end of the round, review the score and cards played."
                            )
                        }
                    }

                    // MARK: Controls

                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {

                            SectionHeaderLabel(
                                text: "Controls",
                                systemImage: "hand.tap.fill"
                            )

                            Label(
                                "Use the Correct and Skip buttons during a round.",
                                systemImage: "checkmark.circle"
                            )

                            Label(
                                "Tilt controls can be enabled in Settings.",
                                systemImage: "gyroscope"
                            )

                            Text(
                                "We are refining tilt controls during beta testing."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    // MARK: Back

                    Button {
                        withAnimation(
                            .easeInOut(
                                duration: UIStyle.standardAnimation
                            )
                        ) {
                            app.flow = .home
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                            Text("Back to Home")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: UIStyle.primaryButtonHeight)
                    }
                    .buttonStyle(.borderedProminent)

                }
                .padding(UIStyle.screenPadding)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.30),
                Color.indigo.opacity(0.18),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Instruction Row

    private func instructionRow(
        number: String,
        title: String,
        text: String
    ) -> some View {

        HStack(alignment: .top, spacing: 12) {

            Text(number)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.blue)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
