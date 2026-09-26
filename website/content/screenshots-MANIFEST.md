# QuickNote website asset manifest

All screenshots are PNG, captured at 2x (Retina) from the Debug build with
curated demo content only (`-quicknote.demoData -quicknote.inMemoryStore`),
never real user notes. `-light` / `-dark` suffix = aqua / darkAqua theme.

## Screenshots (`website/assets/screenshots/`)

| File | What it shows |
| --- | --- |
| `main-light.png` | Main notes workspace, light theme. Demo Inbox ("Launch the portfolio site" on top, detail pane open). |
| `main-dark.png` | Main notes workspace, dark theme. Same demo Inbox and hero note. |
| `capture-empty-light.png` | Quick Capture panel content, light, empty state ("Capture a thought…" placeholder + keycap hints). |
| `capture-empty-dark.png` | Quick Capture panel content, dark, empty state. |
| `capture-typed-light.png` | Quick Capture panel content, light, first demo note typed ("Launch the portfolio site / Buy the domain / Ship the about page / Write the first post"). |
| `capture-typed-dark.png` | Quick Capture panel content, dark, first demo note typed. |
| `settings-general-light.png` | Settings › General ("Launch at Login" toggle), light. |
| `settings-general-dark.png` | Settings › General, dark. |
| `settings-capture-light.png` | Settings › Quick Capture (shortcut recorder ^⇧Space, panel position), light. |
| `settings-capture-dark.png` | Settings › Quick Capture, dark. |
| `settings-privacy-light.png` | Settings › Privacy (source-application recording off, "notes stay on this Mac"), light. |
| `settings-privacy-dark.png` | Settings › Privacy, dark. |
| `settings-appearance-light.png` | Settings › Appearance (theme picker), light. |
| `settings-appearance-dark.png` | Settings › Appearance, dark. |
| `settings-about-light.png` | Settings › About (app icon, version 1.0), light. |
| `settings-about-dark.png` | Settings › About, dark. |
| `onboarding-light.png` | First-launch onboarding (icon, tagline, shortcut intro, "Get Started"), light. |
| `onboarding-dark.png` | First-launch onboarding, dark. |

## Icon (`website/assets/icon/`)

| File | Size | Source |
| --- | --- | --- |
| `icon-1024.png` | 1024×1024 | `Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png` (same art as the app's `AppIcon.icns`) |
| `icon-512.png` | 512×512 | downscale of the 1024 master |
| `icon-256.png` | 256×256 | downscale of the 1024 master |

## Downloads (`website/downloads/`)

| File | What it is |
| --- | --- |
| `QuickNote-1.0.dmg` | Release DMG (universal, drag-to-install), copied from `dist/QuickNote-1.0.dmg`. |
