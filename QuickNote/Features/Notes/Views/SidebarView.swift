import SwiftUI

/// Aurora sidebar: app identity, section rows with gradient icon tiles,
/// counts, glass selection pill, and hover glow.
struct SidebarView: View {
    @ObservedObject var viewModel: NotesViewModel

    private let columns: [(filter: NoteFilter, shortcut: String)] = [
        (.inbox, "1"), (.today, "2"), (.all, "3"), (.pinned, "4"), (.trash, "5"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.top, 42) // clears the traffic-light controls
                .padding(.horizontal, DesignTokens.Spacing.l)
                .padding(.bottom, DesignTokens.Spacing.xl)

            VStack(spacing: 4) {
                ForEach(columns.indices, id: \.self) { index in
                    sectionRow(columns[index].filter, shortcut: columns[index].shortcut)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.m)

            Spacer(minLength: 0)

            footer
                .padding(.horizontal, DesignTokens.Spacing.l)
                .padding(.bottom, DesignTokens.Spacing.l)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityLabel("Sections")
    }

    // MARK: Pieces

    private var header: some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .shadow(color: AuroraPalette.accentIndigo.opacity(0.45), radius: 8, y: 3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("QuickNote")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AuroraPalette.primaryText)
                Text("Instant Notes")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(AuroraPalette.tertiaryText)
            }
            Spacer()
        }
    }

    private func sectionRow(_ filter: NoteFilter, shortcut: String) -> some View {
        let isSelected = viewModel.filter == filter
        let count = viewModel.counts[filter] ?? 0

        return Button {
            withAnimation(Motion.panelSpring) {
                viewModel.filter = filter
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.m) {
                iconTile(filter.symbolName, isActive: isSelected)
                Text(filter.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.white : AuroraPalette.primaryText.opacity(0.82))
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : AuroraPalette.tertiaryText)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(
                                isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.06)
                            )
                        )
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(AuroraPalette.accentGradientWide)
                        .shadow(color: AuroraPalette.accentIndigo.opacity(0.5), radius: 10, y: 3)
                }
            }
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(filter.title), \(count) notes")
        .accessibilityHint("Section ⌘\(shortcut)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func iconTile(_ symbol: String, isActive: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                isActive
                    ? AnyShapeStyle(Color.white.opacity(0.22))
                    : AnyShapeStyle(AuroraPalette.accentGradient.opacity(0.85))
            )
            .frame(width: 24, height: 24)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.95))
            )
            .shadow(color: AuroraPalette.accentIndigo.opacity(0.35), radius: 4, y: 1)
    }

    private var footer: some View {
        HStack(spacing: DesignTokens.Spacing.s) {
            GlassKeycap(label: "⌘1–5")
            Text("sections")
                .font(.system(size: 10.5))
                .foregroundStyle(AuroraPalette.tertiaryText)
            Spacer()
        }
        .accessibilityHidden(true)
    }
}
