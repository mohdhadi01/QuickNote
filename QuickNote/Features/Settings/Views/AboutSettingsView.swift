import SwiftUI

/// About tab.
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.l) {
            Spacer()
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .shadow(color: AuroraPalette.graphite.opacity(0.5), radius: 16, y: 6)
                .accessibilityHidden(true)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("QuickNote")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AuroraPalette.primaryText)
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AuroraPalette.secondaryText)
            }

            Text("Capture a thought from anywhere, instantly.\nYour notes stay on this Mac.")
                .font(.system(size: 12))
                .foregroundStyle(AuroraPalette.secondaryText)
                .multilineTextAlignment(.center)

            Text(Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "")
                .font(.system(size: 10))
                .foregroundStyle(AuroraPalette.tertiaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
