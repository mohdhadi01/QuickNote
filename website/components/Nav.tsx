import Link from "next/link";
import { ThemeToggleButton } from "@/components/ClientEffects";

export function Nav() {
  return (
    <div className="nav-wrap">
      <header className="nav" id="top">
        <Link className="brand" href="/">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img className="brand-icon" src="/assets/icon/icon-256.png" alt="" width={28} height={28} />
          <span>QuickNote</span>
        </Link>
        <nav className="nav-links" aria-label="Sections">
          <a href="/#how">How it works</a>
          <a href="/#features">Features</a>
          <a href="/#mac">Made for Mac</a>
          <a href="/#privacy">Privacy</a>
          <Link href="/blog/">Blog</Link>
        </nav>
        <div className="nav-actions">
          <ThemeToggleButton />
          <a className="btn btn-primary btn-small" href="/#download">Download</a>
        </div>
      </header>
    </div>
  );
}
