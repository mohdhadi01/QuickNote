"use client";

import { useEffect, useState } from "react";

/**
 * Theme cycling (system → light → dark) + scroll/reveal/hero observers.
 * All visuals start in their static, no-JS state; this component upgrades them.
 */
export function ClientEffects() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  useEffect(() => {
    document.documentElement.classList.add("js");

    const systemDark = window.matchMedia("(prefers-color-scheme: dark)");
    const stored = () => {
      try {
        const v = localStorage.getItem("qn-theme");
        return v === "light" || v === "dark" || v === "system" ? v : "system";
      } catch {
        return "system";
      }
    };

    const apply = () => {
      const pref = stored();
      const dark = pref === "dark" || (pref === "system" && systemDark.matches);
      document.documentElement.dataset.theme = dark ? "dark" : "light";
      document.documentElement.dataset.themePref = pref;
    };

    const onSystemChange = () => {
      if (stored() === "system") apply();
    };
    systemDark.addEventListener("change", onSystemChange);
    apply();

    return () => systemDark.removeEventListener("change", onSystemChange);
  }, []);

  // Expose the cycle handler for the nav toggle (rendered server-side).
  useEffect(() => {
    const handler = () => {
      const order = { system: "light", light: "dark", dark: "system" } as const;
      const current = (() => {
        try {
          const v = localStorage.getItem("qn-theme");
          return v === "light" || v === "dark" || v === "system" ? v : "system";
        } catch {
          return "system";
        }
      })();
      const next = order[current];
      try {
        localStorage.setItem("qn-theme", next);
      } catch {
        /* private mode — theme still applies for the session */
      }
      const dark =
        next === "dark" ||
        (next === "system" &&
          window.matchMedia("(prefers-color-scheme: dark)").matches);
      document.documentElement.dataset.theme = dark ? "dark" : "light";
      document.documentElement.dataset.themePref = next;
    };
    window.addEventListener("qn:toggle-theme", handler);
    return () => window.removeEventListener("qn:toggle-theme", handler);
  }, []);

  // Nav glass on scroll.
  useEffect(() => {
    const nav = document.querySelector(".nav");
    if (!nav) return;
    const onScroll = () => nav.classList.toggle("scrolled", window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Reveal on scroll.
  useEffect(() => {
    const els = Array.from(document.querySelectorAll(".reveal"));
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced || !("IntersectionObserver" in window)) {
      els.forEach((el) => el.classList.add("in-view"));
      return;
    }
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("in-view");
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -40px 0px" }
    );
    els.forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, []);

  // Hero loop: run only while the stage is on screen.
  useEffect(() => {
    const stage = document.getElementById("hero-stage");
    if (!stage) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const io = new IntersectionObserver(
      (entries) =>
        entries.forEach((entry) =>
          stage.classList.toggle("animate", entry.isIntersecting)
        ),
      { threshold: 0.3 }
    );
    io.observe(stage);
    return () => io.disconnect();
  }, []);

  return null;
}

/** Nav theme button — dispatches the event ClientEffects listens for. */
export function ThemeToggleButton() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  return (
    <button
      className="icon-btn"
      id="theme-toggle"
      type="button"
      aria-label="Switch color theme (system, light, dark)"
      data-mounted={mounted || undefined}
      onClick={() => window.dispatchEvent(new Event("qn:toggle-theme"))}
    >
      <svg className="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><circle cx="12" cy="12" r="4.2" /><path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M4.9 4.9l1.6 1.6M17.5 17.5l1.6 1.6M19.1 4.9l-1.6 1.6M6.5 17.5l-1.6 1.6" /></svg>
      <svg className="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5Z" /></svg>
      <svg className="icon-system" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4.5" width="18" height="12" rx="2.5" /><path d="M9 20h6M12 16.5V20" /></svg>
    </button>
  );
}
