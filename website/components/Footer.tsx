import Link from "next/link";

export function Footer() {
  return (
    <footer className="footer">
      <div className="footer-inner">
        <div className="footer-brand">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/assets/icon/icon-256.png" alt="" width={22} height={22} />
          <span>QuickNote</span>
        </div>
        <p className="footer-tag">A calm home for quick thoughts.</p>
        <nav className="footer-links" aria-label="Footer">
          <a href="/#how">How it works</a>
          <a href="/#notes">Your notes</a>
          <a href="/#privacy">Privacy</a>
          <a href="/#download">Download</a>
          <Link href="/blog/">Blog</Link>
        </nav>
        <p className="footer-fine">
          © <span id="year">{new Date().getFullYear()}</span> QuickNote · Built with native
          SwiftUI · No trackers on this site
        </p>
      </div>
    </footer>
  );
}
