//
//  UIComponents.swift
//  Charades
//
//  Created by Keiny.Grau.a1 on 2026-07-12.
//


import SwiftUI

struct AppCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(UIStyle.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: UIStyle.cardCornerRadius, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIStyle.cardCornerRadius, style: .continuous)
                .stroke(.black.opacity(UIStyle.cardBorderOpacity), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(UIStyle.cardShadowOpacity),
            radius: UIStyle.cardShadowRadius,
            x: 0,
            y: 3
        )
    }
}

struct SectionHeaderLabel: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.headline)
        }
    }
}

struct LabelPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, UIStyle.chipHorizontalPadding)
            .padding(.vertical, UIStyle.chipVerticalPadding)
            .background(
                Capsule()
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
    }
}

struct InfoChip: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption)

            Text(value)
                .font(.subheadline.weight(.semibold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, UIStyle.chipHorizontalPadding)
        .padding(.vertical, UIStyle.chipVerticalPadding)
        .background(.thinMaterial, in: Capsule())
    }
}

// MARK: - Back Arrow

struct BackArrowButton: View {

    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Image(
                systemName: "chevron.left"
            )
            .font(
                .system(
                    size: 18,
                    weight: .bold
                )
            )
            .frame(
                width: 42,
                height: 42
            )
            .contentShape(Circle())
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .controlSize(.regular)
        .accessibilityLabel("Back")
    }
}
