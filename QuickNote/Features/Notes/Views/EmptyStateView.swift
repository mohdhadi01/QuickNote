import SwiftUI

/// Small, understated empty states with a glassy icon.
struct EmptyStateView: View {
    let symbolName: String
    let title: String
    var hint: String?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.m) {
            Image(systemName: symbolName)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(AuroraPalette.inkGradient.opacity(0.8))
                .frame(width: 58, height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AuroraPalette.glassEdgeSoft, lineWidth: 1)
                )
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AuroraPalette.secondaryText)
                .multilineTextAlignment(.center)
            if let hint {
                HStack(spacing: DesignTokens.Spacing.s) {
                    GlassKeycap(label: hint)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
