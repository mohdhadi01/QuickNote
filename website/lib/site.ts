/**
 * Central site config. Everything SEO-related derives from here.
 * NEXT_PUBLIC_SITE_URL is set at build/deploy time (Vercel/Netlify env var,
 * or a .env.local file). Keep the trailing slash off.
 */
export const SITE_URL =
  process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") || "https://quicknote.app";

export const SITE_NAME = "QuickNote";

export const SITE_TITLE = "QuickNote — Capture a thought before it disappears";

export const SITE_DESCRIPTION =
  "QuickNote is a native Mac app that turns one keystroke into a note. Press ⌃⇧Space anywhere, type, hit return — it's saved. Free, fast, and your notes never leave your Mac.";

export const DOWNLOAD_PATH = "/downloads/QuickNote-1.0.dmg";

export const DOWNLOAD_VERSION = "1.0";

/** Replace with the real Search Console token when registering the domain. */
export const GOOGLE_SITE_VERIFICATION =
  process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION || "";

export const KEYWORDS = [
  "quick notes app for mac",
  "mac quick capture",
  "global hotkey notes app",
  "menu bar notes app mac",
  "keyboard shortcut notes mac",
  "minimal notes app mac",
  "apple notes alternative",
  "capture ideas mac",
  "private notes app mac",
  "local notes app no cloud",
];
