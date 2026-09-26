# Product Truth — QuickNote website

Every claim on the website maps to something the app actually does. Use this
table when editing copy: if a feature isn't listed here, don't market it.

Legend: ✅ shipped in QuickNote 1.0 · ❌ do not claim

| Website claim | Source of truth in the app | Status |
|---|---|---|
| Global shortcut (default ⌃⇧Space), customizable in Settings | `GlobalHotkeyService` (Carbon `RegisterEventHotKey`), `ShortcutService`, Settings → Shortcut | ✅ |
| Capture panel drops down anywhere, no Accessibility permission | `QuickCapturePanel` (NSPanel + NSGlassEffectView, non-activating) | ✅ |
| First line becomes the heading, rest becomes the body | `FlowingTextView` first-line attributed styling | ✅ |
| Return saves and closes the panel | `CapturePanelController` commit flow | ✅ |
| "No windows to hunt for" — one-keystroke capture | Same as above | ✅ |
| Notes land in an inbox; list + editor home window | `NotesViewModel`, `NotesListView`, `NoteEditorView`, `SidebarView` (Inbox / All Notes / Pinned / Trash) | ✅ |
| Search filters as you type (⌘F) | `SearchService`, ⌘F via `MainWindowKeyboardRouter` | ✅ |
| Pin notes, pin section in sidebar | pin toggling + Pinned section | ✅ |
| Keyboard navigation: ↑/↓ walk list, ⌘1–5 switch sections, Return opens, Esc contextual | `MainWindowKeyboardRouter` (local `NSEvent` monitor) | ✅ |
| Multi-select; move/pin/merge many at once | `NotesViewModel.selectedNoteIDs`, `moveSelection`, `mergeSelected` | ✅ |
| Drag notes onto a sidebar section to organize | `NoteRowView` drag provider + `SidebarView` `onDrop` | ✅ |
| Drop text or `.txt` files anywhere to create notes | drop handling in `NotesListView` / `SidebarView` | ✅ |
| Trash with restore and permanent delete | Trash section, delete/restore flows | ✅ |
| Launch at login, sits in the menu bar | `SMAppService` toggle (Settings + menu bar), `MenuBarExtra` | ✅ |
| Light & dark, follows the system | adaptive `AuroraPalette` / `GlassStyle`, appearance-reactive views | ✅ |
| Local database, no accounts / sync / network / telemetry | SwiftData `@Model Note`, no networking code, no analytics | ✅ |
| Native Swift & SwiftUI, macOS 26+, Apple silicon & Intel (universal) | project settings (MACOSX_DEPLOYMENT_TARGET 26.0, ARCHS arm64 + x86_64) | ✅ |
| ~3 MB download | `dist/QuickNote-1.0.dmg` size at packaging time | ✅ (re-verify on new builds) |
| "QuickNote isn't notarized yet" + Open Anyway instructions | app signed with Apple Development identity, no notarization ticket | ✅ (remove this line if/when notarized) |
| Onboarding on first launch | `OnboardingView`, `-quicknote.forceOnboarding` flag | ✅ (shown in-app; not marketed on site) |

## Deliberately NOT claimed

- ❌ iCloud sync / cross-device sync — not implemented.
- ❌ iPhone / iPad / visionOS versions — macOS only.
- ❌ Tags, folders, wiki links, attachments, images — not implemented.
- ❌ Markdown export, printing, sharing extensions — not implemented.
- ❌ Encryption claims — storage is the system default; don't market security guarantees.
- ❌ Windows / Linux versions.
- ❌ Any pricing other than free (there is no payment flow).
- ❌ Notarized / "no warnings on open" — currently false.

## Screenshot integrity

All screenshots in `assets/screenshots/` were captured from the real app via its
built-in snapshot driver with **curated demo notes only** (`-quicknote.demoData`
+ `-quicknote.inMemoryStore`), never real user data. Regenerate them with:

```
.build/DD/Build/Products/Debug/QuickNote.app/Contents/MacOS/QuickNote \
  -hasCompletedOnboarding 1 -quicknote.demoData -quicknote.inMemoryStore 1 \
  -quicknote.debugSnapshot
```

Output lands in the app's temporary directory (`quicknote-snapshots/`). See
`content/screenshots-MANIFEST.md` for what each file shows.
