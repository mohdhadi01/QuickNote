# QuickNote Website

Production landing site for QuickNote — a native macOS instant-notes app — built
with **Next.js (App Router, TypeScript)** and statically exported. No Tailwind,
no CMS, no trackers: the smoke-glass design is plain CSS in `app/globals.css`.

```
website/
├── app/
│   ├── layout.tsx            # shared nav/footer, SEO metadata, theme bootstrap
│   ├── page.tsx              # landing page (hero, how it works, features, privacy, download)
│   ├── globals.css           # design system: light/dark, glass, animations, blog styles
│   ├── blog/page.tsx         # blog index
│   ├── blog/[slug]/page.tsx  # post pages (static, from content/posts/*.md)
│   ├── sitemap.ts            # → /sitemap.xml
│   ├── robots.ts             # → /robots.txt
│   └── manifest.ts           # → /manifest.webmanifest
├── components/               # Nav, Footer, MacWindow, ClientEffects (theme/reveal/hero)
├── content/
│   ├── product-truth.md      # feature truth table — READ before editing copy
│   ├── screenshots-MANIFEST.md
│   └── posts/*.md            # blog posts (frontmatter: title, description, date, keywords)
├── lib/
│   ├── site.ts               # site URL, titles, download path, verification token
│   └── posts.ts              # markdown loading (gray-matter + marked, build-time only)
└── public/
    ├── assets/screenshots/   # real captures from the app (demo notes only)
    ├── assets/icon/          # app icon exports
    ├── assets/og/og.png      # 1200×630 social share image
    └── downloads/QuickNote-1.0.dmg   # the real distributable, served with the site
```

## Develop

```
cd website
npm install
npm run dev        # → http://localhost:3000
```

## Build & preview

```
npm run build      # static export → out/
npx serve out      # or: python3 -m http.server -d out 8080
```

`out/` is a fully static site (with the DMG inside) — deploy it anywhere.

## Deploy

Pick one:

- **Vercel** (native fit): import the repo, root directory `website`. Framework
  preset Next.js, no other settings. Set `NEXT_PUBLIC_SITE_URL` to your domain.
- **Netlify / Cloudflare Pages**: build command `npm run build`, publish
  directory `website/out`.
- **GitHub Pages**: enable `basePath` in `next.config.ts` (e.g. `"/quicknote"`),
  push the `out/` folder to `gh-pages`.

The DMG ships with the site at `/downloads/QuickNote-1.0.dmg`; the Download
button links there directly. If you move hosting of builds (GitHub Releases,
CDN), update `DOWNLOAD_PATH` in `lib/site.ts`.

## SEO checklist (what's already wired)

- Per-page `title`/`description`, canonical URLs, Open Graph + Twitter cards
  (`metadataBase` comes from `NEXT_PUBLIC_SITE_URL`, default `https://quicknote.app`
  — **set it to your real domain**).
- `/sitemap.xml` (pages + posts) and `/robots.txt` generated at build.
- JSON-LD: `SoftwareApplication` (home), `Blog` (index), `BlogPosting` +
  `BreadcrumbList` (posts).
- Blog posts target search keywords; frontmatter `keywords` are optional
  metadata — rankings come from titles/headings/content, so keep them natural.
- **Google Search Console**: put your verification token in
  `NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION` (env var or `lib/site.ts` default), then
  register the domain and submit `${SITE_URL}/sitemap.xml`.

## Updating screenshots

Screenshots are real captures from the app, generated with **curated demo notes
only** (never real user data):

```
.build/DD/Build/Products/Debug/QuickNote.app/Contents/MacOS/QuickNote \
  -hasCompletedOnboarding 1 -quicknote.demoData -quicknote.inMemoryStore 1 \
  -quicknote.debugSnapshot
```

Copy the PNGs from the app's temp `quicknote-snapshots/` directory into
`public/assets/screenshots/` using the names in `content/screenshots-MANIFEST.md`.

## Editing rules

1. **Read `content/product-truth.md` first.** Only claim features in the ✅ list.
   No sync, no tags, no mobile versions, no notarization claims.
2. Animations stay `transform`/`opacity` only; keep the
   `prefers-reduced-motion` static fallbacks working.
3. New blog post = new `.md` file in `content/posts/` (frontmatter: title,
   description, date, keywords). It appears in the index, sitemap, and RSS-less
   blog automatically on the next build.
4. Keep the stack boring: no npm frameworks beyond what's in `package.json`.
