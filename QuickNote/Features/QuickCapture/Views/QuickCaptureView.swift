import SwiftUI

/// The quick capture surface content (spec §7, §10, §12, §13): aurora glass
/// with a gradient rim, focused input, and keycap hints.
struct QuickCaptureView: View {
    @ObservedObject var viewModel: QuickCaptureViewModel
    @ObservedObject var flags: AccessibilityEnvironmentFlags
    let onTextViewReady: (CaptureTextViewImpl) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.CapturePanel.footerSpacing) {
            editorArea
            footer
        }
        .padding(.horizontal, DesignTokens.CapturePanel.horizontalPadding)
        .padding(.vertical, DesignTokens.CapturePanel.verticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(rim)
        .background {
            if flags.reduceTransparency {
                // Reduce Transparency: solid backdrop instead of glass.
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.capture)
                    .fill(Color(nsColor: .windowBackgroundColor))
            }
        }
    }

    /// Gradient rim + top sheen: light bending around the glass edge.
    private var rim: some View {
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.capture, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.38),
                        AuroraPalette.steel.opacity(0.30),
                        AuroraPalette.silver.opacity(0.22),
                        Color.white.opacity(0.10),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .allowsHitTesting(false)
    }

    private var editorArea: some View {
        ZStack(alignment: .topLeading) {
            CaptureTextView(
                text: $viewModel.text,
                onEdit: { _, height in
                    viewModel.contentHeight = height
                },
                onReturn: { [weak viewModel] in
                    guard let viewModel else { return false }
                    if viewModel.canSave || viewModel.saveError == nil {
                        viewModel.onSaveRequested?()
                        return true
                    }
                    return false
                },
                onEscape: { [weak viewModel] in
                    viewModel?.onCancelRequested?()
                    return true
                },
                onViewReady: onTextViewReady
            )
            .accessibilityLabel("Quick Capture")
            .accessibilityHint("Type a note, then press Return to save it")

            if viewModel.text.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AuroraPalette.inkGradient.opacity(0.85))
                    Text("Capture a thought…")
                        .font(Typography.capturePlaceholder)
                        .foregroundStyle(AuroraPalette.tertiaryText)
                }
                .allowsHitTesting(false)
                .padding(.leading, 4)
                .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var footer: some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            if let error = viewModel.saveError {
                Text(error)
                    .foregroundStyle(.red.opacity(0.95))
                Button("Retry") {
                    viewModel.clearSaveError()
                    viewModel.onSaveRequested?()
                }
                .buttonStyle(.link)
                .font(Typography.captureHint)
            } else if viewModel.isSaving {
                ProgressView()
                    .controlSize(.small)
            } else {
                keyHint(keys: ["⏎"], label: "Save")
                keyHint(keys: ["⇧", "⏎"], label: "New Line")
                keyHint(keys: ["esc"], label: "Dismiss")
            }
            Spacer()
        }
        .font(Typography.captureHint)
        .foregroundStyle(AuroraPalette.secondaryText)
        .lineLimit(1)
        .frame(height: DesignTokens.CapturePanel.footerHeight)
        .accessibilityElement(children: .combine)
    }

    private func keyHint(keys: [String], label: String) -> some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(keys, id: \.self) { GlassKeycap(label: $0) }
            }
            Text(label)
        }
    }
}
