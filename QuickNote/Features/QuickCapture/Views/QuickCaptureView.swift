import SwiftUI

/// The quick capture surface content (spec §7, §10, §12, §13).
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
        .background {
            if flags.reduceTransparency {
                // Reduce Transparency: solid backdrop instead of glass.
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.capture)
                    .fill(Color(nsColor: .windowBackgroundColor))
            }
        }
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
                Text("Capture a thought…")
                    .font(Typography.capturePlaceholder)
                    .foregroundStyle(.secondary)
                    .opacity(0.7)
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
                    .foregroundStyle(.red)
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
                keyHint("↩", "Save")
                keyHint("⇧↩", "New Line")
                keyHint("esc", "Dismiss")
            }
            Spacer()
        }
        .font(Typography.captureHint)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .frame(height: DesignTokens.CapturePanel.footerHeight)
        .accessibilityElement(children: .combine)
    }

    private func keyHint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
            Text(label)
        }
    }
}
