import AppKit
import SwiftUI

/// The keyboard-capturing view behind the shortcut recorder. While first
/// responder it consumes all key events, preventing accidental text input
/// (spec §6).
final class ShortcutRecorderField: NSView {
    enum Outcome {
        case captured(KeyboardShortcut)
        case cancelled
    }

    var onOutcome: ((Outcome) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        becomeFirstResponder()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func keyDown(with event: NSEvent) {
        let modifiers = ModifierSet.from(event.modifierFlags)
        let keyCode = UInt32(event.keyCode)

        if keyCode == VirtualKey.escape {
            onOutcome?(.cancelled)
            return
        }
        // Ignore bare modifier presses (flagsChanged handles those separately).
        guard KeyDisplay.displayName(for: keyCode) != nil, keyCode != VirtualKey.fn else { return }

        let shortcut = KeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
        if shortcut.isValid {
            onOutcome?(.captured(shortcut))
        } else {
            // Invalid combination: reject with a shake-like no-op; the caller
            // surfaces guidance.
            onOutcome?(.cancelled)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        // Consume so bare modifiers don't beep while recording.
    }
}

/// Native-looking shortcut recorder with recording state (spec §6).
struct ShortcutRecorderView: View {
    @Binding var shortcut: KeyboardShortcut
    @State private var isRecording = false
    @State private var guidance: String?
    @FocusState private var recorderFocused: Bool

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            recorderChip
            VStack(alignment: .leading, spacing: 2) {
                Button(isRecording ? "Press keys…" : "Change") {
                    startRecording()
                }
                .buttonStyle(.bordered)
                .disabled(isRecording)
                if let guidance {
                    Text(guidance)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quick capture shortcut")
    }

    private var recorderChip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.s)
                .fill(
                    isRecording
                        ? AnyShapeStyle(AuroraPalette.accentGradient.opacity(0.22))
                        : AnyShapeStyle(Color.white.opacity(0.06))
                )
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.s)
                .strokeBorder(
                    isRecording
                        ? AnyShapeStyle(AuroraPalette.accentGradient.opacity(0.8))
                        : AnyShapeStyle(AuroraPalette.glassEdge),
                    lineWidth: 1
                )
            Text(isRecording ? "Type a shortcut" : shortcut.displayString)
                .font(Typography.shortcutGlyph)
                .foregroundStyle(AuroraPalette.primaryText)
        }
        .frame(width: 150, height: 34)
        .contentShape(Rectangle())
        .onTapGesture { startRecording() }
        .overlay {
            if isRecording {
                ShortcutRecorderRepresentable(outcome: handleOutcome)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
            }
        }
        .accessibilityValue(isRecording ? "Recording" : shortcut.displayString)
    }

    private func startRecording() {
        isRecording = true
        guidance = "Press a key combination. Escape cancels."
    }

    private func handleOutcome(_ outcome: ShortcutRecorderField.Outcome) {
        switch outcome {
        case .cancelled:
            isRecording = false
            guidance = nil
        case .captured(let newShortcut):
            shortcut = newShortcut
            isRecording = false
            guidance = nil
        }
    }
}

struct ShortcutRecorderRepresentable: NSViewRepresentable {
    let outcome: (ShortcutRecorderField.Outcome) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderField {
        let field = ShortcutRecorderField()
        field.onOutcome = outcome
        DispatchQueue.main.async {
            field.window?.makeFirstResponder(field)
        }
        return field
    }

    func updateNSView(_ nsView: ShortcutRecorderField, context: Context) {
        nsView.onOutcome = outcome
    }
}
