import SwiftUI

/// Small, understated empty states (spec §47).
struct EmptyStateView: View {
    let symbolName: String
    let title: String

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.s) {
            Image(systemName: symbolName)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
