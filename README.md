# QuickNote

A native macOS instant-notes utility: press a global shortcut from anywhere,
type, press Return — the thought is saved locally and the panel disappears.
Built with Swift + SwiftUI + AppKit + SwiftData, targeting macOS 26+.

## The core interaction

```
⌃⇧Space   (default shortcut, configurable)
  → floating glass panel appears near your cursor, already focused
  → type
  → Return saves the note and dismisses the panel
```

- The default shortcut is **⌃⇧Space** — chosen to avoid stock macOS bindings
  (⌘Space Spotlight, ⌃Space/⌃⌥Space input switching) and common app defaults
  (e.g. VS Code's ⌘⇧Space). Change it in **Settings → Quick Capture** with the
  native shortcut recorder (Escape cancels recording).
- **⇧Return** inserts a newline, **Return** saves, **Escape** discards.
- Clicking away with text in the panel **saves** it (never loses text); with an
  empty panel it dismisses. Quitting with unsaved text also preserves it.

## Features

- **Multi-select**: ⌘-click toggles, ⇧-click selects a range, ⌘A selects all; batch Pin/Unpin/Copy/Merge/Trash panel; Esc collapses to one note.
- **Drag & drop**: drag rows out as text; drag notes onto sidebar sections to pin/trash/restore them; drop text or .txt files into the list to create notes.
- **First-line-as-heading editor**: quick captures have no title field — the first line renders as a heading visually only; stored content is never modified.

- Quick capture panel: Liquid Glass (`NSGlassEffectView`), non-activating
  NSPanel that works over any app, Space, and full-screen app; positioned near
  the cursor (or centered on screen — a setting); grows with content.
- Main window: Inbox / Today / All Notes / Pinned / Trash sidebar, note list
  with derived titles + previews + relative timestamps, document-like editor
  with autosave (debounced), search (debounced, case-insensitive, global).
- Pin/unpin via editor button or context menu; trash/restore; permanent delete
  requires confirmation.
- Settings: Launch at Login (SMAppService), shortcut recorder, panel position,
  Record Source Application (**off by default** — stores only app name +
  bundle ID), appearance (system/light/dark).
- Menu bar item: New Quick Note, New Note, Open Notes, Search Notes, **Launch at Login toggle**, Settings, Quit.
- Onboarding is a single card on first launch — no accounts, no permissions.
- Persistence via SwiftData with graceful recovery: an unreadable store is
  quarantined (never deleted) and a fresh one is created; the app surfaces a
  banner instead of crashing. Notes are CloudKit-friendly by design (stable
  UUIDs, createdAt/updatedAt, no transient UI state).
- Accessibility: full labels, keyboard navigation, Reduce Motion and Reduce
  Transparency support, VoiceOver-friendly rows.

## Build & run

Requirements: Xcode 26+ (built with Xcode 27 on macOS 26.6), macOS 26+.

```bash
open QuickNote.xcodeproj        # then ⌘R in Xcode
# or
xcodebuild -project QuickNote.xcodeproj -scheme QuickNote -configuration Debug build
xcodebuild -project QuickNote.xcodeproj -scheme QuickNote -configuration Release build
```

The app is ad-hoc signed with App Sandbox; no special permissions are
requested (no Accessibility permission needed — the hotkey uses Carbon
`RegisterEventHotKey`).

## Tests

```bash
xcodebuild -project QuickNote.xcodeproj -scheme QuickNote \
  -destination 'platform=macOS' -only-testing:QuickNoteTests test      # 65 unit tests

xcodebuild -project QuickNote.xcodeproj -scheme QuickNote \
  -destination 'platform=macOS' -only-testing:QuickNoteUITests test    # UI tests
```

UI tests run against a fresh in-memory store and use documented QA launch
hooks (below) because headless runs cannot synthesize hardware keyboard
events. Real typing should be verified manually.

## QA launch flags (intentional, documented hooks)

| Flag | Effect |
| --- | --- |
| `-quicknote.debugShowCapture` | Opens the capture panel 1 s after launch |
| `-quicknote.debugOpenSettings` | Opens Settings 1 s after launch |
| `-quicknote.debugSnapshot` | Renders light+dark PNGs of all windows to the app container's `tmp/quicknote-snapshots/`, then quits |
| `-quicknote.forceOnboarding` | Always starts at onboarding |
| `-quicknote.seedNote <text>` | Seeds one note at launch |
| `-quicknote.inMemoryStore 1` | Fresh in-memory store per launch |

## Manual test checklist

- Hotkey from Safari/Xcode/Terminal/Finder/Slack, full-screen apps, each Space,
  each connected display (panel follows the cursor's screen).
- Rapid repeated hotkey (toggles the panel), rapid repeated Return (single note).
- Display disconnect while the panel is open (it repositions).
- Light/dark, Reduce Motion, Reduce Transparency, Increased Contrast.
- Settings: re-record shortcut (try one already in use to see the error),
  Launch at Login toggle, panel position.
- Restart the app: notes persist.

## Project layout

```
QuickNote/
├── App/            # entry point, composition root, lifecycle, coordinator
├── Core/           # Note model, repository, persistence, formatting, errors
├── Platform/       # Carbon hotkey, NSPanel + placement, login item, a11y flags
├── Services/       # settings, notes, search, shortcut services
├── Features/       # QuickCapture, Notes, Settings, MenuBar, Onboarding
├── DesignSystem/   # tokens, typography, motion
└── Support/        # logging (OSLog), QA snapshot tooling
QuickNoteTests/     # 65 unit tests (all green)
QuickNoteUITests/   # hermetic UI tests
Scripts/            # app-icon generator (swift Scripts/GenerateAppIcon.swift)
```

Design rule: *every extra interaction is a product bug unless it provides real
value* — shortcut → type → Return stays sacred.
