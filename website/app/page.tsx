import type { CSSProperties } from "react";
import { MacWindow } from "@/components/MacWindow";
import { DOWNLOAD_VERSION } from "@/lib/site";

const d = (s: string) => ({ "--d": s }) as CSSProperties;

export default function Home() {
  return (
    <>
      {/* ============ HERO ============ */}
      <section className="hero">
        <div className="hero-inner">
          <div className="hero-copy">
            <p className="chip-badge reveal">
              Built for macOS 26 · Liquid&nbsp;Glass native
            </p>
            <h1 className="reveal" style={d("0.05s")}>
              Capture a thought
              <br />
              <span className="accent">before it disappears.</span>
            </h1>
            <p className="lede reveal" style={d("0.1s")}>
              QuickNote turns a single keystroke into a note. Press{" "}
              <span className="kbd-inline">⌃⇧Space</span> anywhere, type, hit return — it&apos;s
              saved and waiting. No windows to hunt for, no account, and nothing ever leaves
              your Mac.
            </p>
            <div className="hero-cta reveal" style={d("0.15s")}>
              <a className="btn btn-primary" href="#download">Download for Mac</a>
              <a className="btn btn-ghost" href="#how">See how it works</a>
            </div>
          </div>

          <div
            className="hero-stage"
            id="hero-stage"
            role="img"
            aria-label="Demo: pressing the shortcut opens the capture panel, a note is typed, and it appears in the notes list"
          >
            <div className="keys" aria-hidden="true">
              <span className="key">⌃</span>
              <span className="key">⇧</span>
              <span className="key key-space">Space</span>
              <span className="key key-return">↩</span>
            </div>

            <div className="capture-frame" aria-hidden="true">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img className="shot only-light" src="/assets/screenshots/capture-empty-light.png" alt="" />
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img className="shot only-dark" src="/assets/screenshots/capture-empty-dark.png" alt="" />
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img className="shot capture-typed only-light" src="/assets/screenshots/capture-typed-light.png" alt="" />
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img className="shot capture-typed only-dark" src="/assets/screenshots/capture-typed-dark.png" alt="" />
            </div>

            <div className="result-holder" aria-hidden="true">
              <MacWindow className="result-window">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img className="shot only-light" src="/assets/screenshots/main-light.png" alt="" />
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img className="shot only-dark" src="/assets/screenshots/main-dark.png" alt="" />
              </MacWindow>
            </div>
          </div>
        </div>
      </section>

      {/* ============ HOW IT WORKS ============ */}
      <section className="section" id="how">
        <div className="section-inner">
          <p className="eyebrow reveal">How it works</p>
          <h2 className="reveal" style={d("0.05s")}>Shortcut. Thought. Saved.</h2>
          <p className="section-lede reveal" style={d("0.1s")}>
            The idea isn&apos;t to write documents. It&apos;s to catch the thought while it&apos;s
            still there — then get back to whatever you were doing. The whole loop takes three
            seconds.
          </p>

          <ol className="steps">
            <li className="step card reveal">
              <span className="step-num">01</span>
              <h3>Press the shortcut — anywhere</h3>
              <p>
                In the middle of a call, deep in Xcode, on any display. A slim glass panel drops
                over your work. Registered at the system level — no Accessibility permission,
                ever.
              </p>
              <div className="mini-keys" aria-hidden="true">
                <span className="mini-key">⌃</span>
                <span className="mini-key">⇧</span>
                <span className="mini-key">Space</span>
              </div>
            </li>
            <li className="step card reveal" style={d("0.08s")}>
              <span className="step-num">02</span>
              <h3>Just start typing</h3>
              <p>
                No &quot;new note&quot; button, no title field. The first line becomes the heading
                and everything after it becomes the body — exactly the way the thought arrived.
              </p>
              <div className="mini-note" aria-hidden="true">
                <span className="mini-note-title">Coffee brewing ratios</span>
                <span className="mini-note-body">1:16 for a milder cup…</span>
              </div>
            </li>
            <li className="step card reveal" style={d("0.16s")}>
              <span className="step-num">03</span>
              <h3>Hit return. It&apos;s saved.</h3>
              <p>
                The panel vanishes and the note is already in your inbox. QuickNote sits quietly
                in the menu bar — optional launch at login keeps it ready all day.
              </p>
              <div className="mini-saved" aria-hidden="true">
                <span className="mini-check">✓</span>
                <span>Saved to Inbox</span>
              </div>
            </li>
          </ol>
        </div>
      </section>

      {/* ============ SHOWCASE ============ */}
      <section className="section showcase" id="notes">
        <div className="section-inner">
          <p className="eyebrow reveal">Your notes, at a glance</p>
          <h2 className="reveal" style={d("0.05s")}>
            A calm home for quick thoughts.
          </h2>
          <p className="section-lede reveal" style={d("0.1s")}>
            Captures land in a fast, keyboard-friendly list — organize them when you feel like
            it, or don&apos;t. It&apos;s your inbox, not a project.
          </p>

          <MacWindow className="app-window reveal" >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              className="shot only-light"
              src="/assets/screenshots/main-light.png"
              alt="QuickNote main window in light mode: sidebar with Inbox, All Notes and Pinned, a note list, and the selected note open in the editor"
            />
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              className="shot only-dark"
              src="/assets/screenshots/main-dark.png"
              alt="QuickNote main window in dark mode: sidebar with Inbox, All Notes and Pinned, a note list, and the selected note open in the editor"
            />
          </MacWindow>
        </div>
      </section>

      {/* ============ BENTO FEATURES ============ */}
      <section className="section" id="features">
        <div className="section-inner">
          <p className="eyebrow reveal">Features</p>
          <h2 className="reveal" style={d("0.05s")}>
            Everything you need. Nothing you don&apos;t.
          </h2>
          <p className="section-lede reveal" style={d("0.1s")}>
            Power when you want it, silence when you don&apos;t. Every feature is built to keep
            the capture loop instant.
          </p>

          <div className="bento">
            <div className="card feature span-4 reveal">
              <span className="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round"><circle cx="11" cy="11" r="6.5" /><path d="m20 20-3.8-3.8" /></svg>
              </span>
              <h3>Search that keeps up</h3>
              <p>Filter every note as you type. Hit <span className="kbd-inline">⌘F</span> and the list narrows with every keystroke — no search page, no waiting.</p>
              <div className="mini-search" aria-hidden="true">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><circle cx="11" cy="11" r="6.5" /><path d="m20 20-3.8-3.8" /></svg>
                <span>brewing</span>
                <span className="caret" />
              </div>
            </div>

            <div className="card feature span-2 reveal" style={d("0.08s")}>
              <span className="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d="M9 4h6l1 4 2.5 2.5c.8.8.2 2.5-1 2.5h-11c-1.2 0-1.8-1.7-1-2.5L8 8Z" /><path d="M12 13v7" /></svg>
              </span>
              <h3>Pin what matters</h3>
              <p>Keep today&apos;s shortlist one keystroke from the top.</p>
              <div className="mini-rows" aria-hidden="true">
                <span className="mini-row is-pinned">
                  <span className="pin-ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 4h6l1 4 2.5 2.5c.8.8.2 2.5-1 2.5h-11c-1.2 0-1.8-1.7-1-2.5L8 8Z" /><path d="M12 13v7" /></svg></span>
                  Ship the about page
                  <span className="dim">Pinned</span>
                </span>
                <span className="mini-row">Book notes — Systems</span>
              </div>
            </div>

            <div className="card feature span-2 reveal">
              <span className="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d="m12 3 9 5-9 5-9-5Z" /><path d="m5.5 12.5-2.5 1.5 9 5 9-5-2.5-1.5" /></svg>
              </span>
              <h3>Select many, act once</h3>
              <p>Multi-select notes to move, pin, or merge them into one.</p>
            </div>

            <div className="card feature span-4 reveal" style={d("0.08s")}>
              <span className="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round"><rect x="3" y="6" width="18" height="12" rx="2.5" /><path d="M7 10h.01M11 10h.01M15 10h.01M7 14h10" /></svg>
              </span>
              <h3>Keyboard first, everywhere</h3>
              <p>Walk the list with <span className="kbd-inline">↑</span><span className="kbd-inline">↓</span>, jump between sections with <span className="kbd-inline">⌘1–5</span>, search with <span className="kbd-inline">⌘F</span>, escape with <span className="kbd-inline">esc</span>. Your hands never leave the keys.</p>
            </div>

            <div className="card feature span-3 reveal">
              <span className="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d="M12 16V4m0 0L7.5 8.5M12 4l4.5 4.5" /><path d="M4 16v2.5A1.5 1.5 0 0 0 5.5 20h13a1.5 1.5 0 0 0 1.5-1.5V16" /></svg>
              </span>
              <h3>Drag to organize</h3>
              <p>Drag notes onto a sidebar section — or drop text and <span className="kbd-inline">.txt</span> files anywhere to create new notes.</p>
            </div>

            <div className="card feature span-3 reveal" style={d("0.08s")}>
              <span className="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d="M4 7h16M9.5 7V5.5A1.5 1.5 0 0 1 11 4h2a1.5 1.5 0 0 1 1.5 1.5V7" /><path d="M6.5 7l.8 12a1.5 1.5 0 0 0 1.5 1.4h6.4a1.5 1.5 0 0 0 1.5-1.4l.8-12" /></svg>
              </span>
              <h3>Delete without fear</h3>
              <p>Everything lands in Trash first. Empty it only when you&apos;re ready.</p>
            </div>
          </div>
        </div>
      </section>

      {/* ============ MADE FOR MAC ============ */}
      <section className="section" id="mac">
        <div className="section-inner">
          <div className="made-grid">
            <div>
              <p className="eyebrow reveal">Made for Mac</p>
              <h2 className="reveal" style={d("0.05s")}>
                Quietly, deeply native.
              </h2>
              <p className="section-lede reveal" style={d("0.1s")}>
                Not an Electron shell, not a web app in a wrapper. QuickNote is Swift and
                SwiftUI from the first line — and it behaves the way a Mac utility should.
              </p>
              <ul className="made-list">
                <li className="reveal">
                  <span className="tick">✓</span>
                  <div><strong>Truly global capture</strong><span>System-registered hotkey over any app, any display, any space.</span></div>
                </li>
                <li className="reveal" style={d("0.06s")}>
                  <span className="tick">✓</span>
                  <div><strong>Lives in the menu bar</strong><span>Optional launch at login — silent, no window, just ready.</span></div>
                </li>
                <li className="reveal" style={d("0.12s")}>
                  <span className="tick">✓</span>
                  <div><strong>Liquid Glass, light &amp; dark</strong><span>Real vibrancy and blur that follows your system appearance.</span></div>
                </li>
                <li className="reveal" style={d("0.18s")}>
                  <span className="tick">✓</span>
                  <div><strong>Apple silicon &amp; Intel</strong><span>One universal binary, a few megabytes on disk, zero setup.</span></div>
                </li>
              </ul>
            </div>
            <div className="made-visual reveal" style={d("0.1s")}>
              <MacWindow>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  className="shot only-light"
                  src="/assets/screenshots/settings-appearance-light.png"
                  alt="QuickNote appearance settings in light mode"
                />
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  className="shot only-dark"
                  src="/assets/screenshots/settings-appearance-dark.png"
                  alt="QuickNote appearance settings in dark mode"
                />
              </MacWindow>
            </div>
          </div>
        </div>
      </section>

      {/* ============ PRIVACY ============ */}
      <section className="section" id="privacy">
        <div className="section-inner">
          <div className="privacy-panel reveal">
            <p className="eyebrow">Privacy</p>
            <h2>Your thoughts stay on your Mac.</h2>
            <p className="section-lede">
              Notes are stored in a local database — no account, no cloud, no sync service, no
              analytics. This website has no trackers either.
            </p>
            <ul className="privacy-list">
              <li><strong>No accounts</strong>Nothing to sign up for, nothing to reset.</li>
              <li><strong>No network</strong>QuickNote doesn&apos;t phone home — it has no reason to.</li>
              <li><strong>No telemetry</strong>We can&apos;t see your notes. They never leave your machine.</li>
            </ul>
          </div>
        </div>
      </section>

      {/* ============ DOWNLOAD ============ */}
      <section className="section" id="download">
        <div className="section-inner">
          <div className="download-card reveal">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img className="download-icon" src="/assets/icon/icon-256.png" alt="" width={84} height={84} />
            <h2>Ready in a minute.</h2>
            <p className="download-meta">
              QuickNote {DOWNLOAD_VERSION} · macOS 26 or later · Apple silicon &amp; Intel · ~3 MB · Free
            </p>
            <a className="btn btn-primary btn-big" href="/downloads/QuickNote-1.0.dmg" download>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M12 4v11m0 0 4.5-4.5M12 15l-4.5-4.5" /><path d="M4.5 17.5V19A1.5 1.5 0 0 0 6 20.5h12a1.5 1.5 0 0 0 1.5-1.5v-1.5" /></svg>
              Download QuickNote&nbsp;(.dmg)
            </a>
            <p className="download-note">Free direct download — nothing to install before the app itself.</p>

            <ol className="install-steps">
              <li><strong>Open the DMG</strong> and drag QuickNote to your Applications folder.</li>
              <li>
                <strong>First launch:</strong> macOS shows a one-time warning
                (&ldquo;Apple could not verify QuickNote&rdquo;) because the build isn&apos;t
                notarized yet. Click <em>Done</em>, then open System Settings → Privacy &amp;
                Security → <em>Open Anyway</em> → <em>Open</em>.
              </li>
              <li><strong>That&apos;s it.</strong> No permissions to grant — set your shortcut in Settings and start capturing.</li>
            </ol>
          </div>
        </div>
      </section>
    </>
  );
}
