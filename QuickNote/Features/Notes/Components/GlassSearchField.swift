import SwiftUI

/// Glass search pill: magnifier, field, clear button. ⌘F focuses it (via the
/// keyboard router), Escape clears it.
struct GlassSearchField: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    var onRequestEditorFocus: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AuroraPalette.tertiaryText)

            TextField("Search Notes", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5))
                .foregroundStyle(AuroraPalette.primaryText)
                .focused($focused)
                .onSubmit(selectFirstResult)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(AuroraPalette.tertiaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(focused ? 0.10 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    focused ? AnyShapeStyle(AuroraPalette.inkGradient.opacity(0.7)) : AnyShapeStyle(AuroraPalette.glassEdgeSoft),
                    lineWidth: 1
                )
        )
        .onChange(of: isFocused) { _, newValue in
            focused = newValue
        }
        .onChange(of: focused) { _, newValue in
            isFocused = newValue
        }
        .accessibilityIdentifier("search-field")
    }

    /// Return in search jumps to the first result's editor — the fastest
    /// search-to-editing path.
    private func selectFirstResult() {
        onRequestEditorFocus()
    }
}
