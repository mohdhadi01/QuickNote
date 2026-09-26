import SwiftUI

/// About tab.
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.l) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("QuickNote")
                    .font(.system(size: 18, weight: .semibold))
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text("Capture a thought from anywhere, instantly.\nYour notes stay on this Mac.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Spacing.xl)
    }
}
