import type { ReactNode } from "react";

/** CSS depiction of a macOS window around a real screenshot. */
export function MacWindow({ children, className = "" }: { children: ReactNode; className?: string }) {
  return (
    <figure className={`mac-window ${className}`.trim()}>
      <figcaption className="mac-titlebar">
        <span className="dot dot-r" />
        <span className="dot dot-y" />
        <span className="dot dot-g" />
        <span className="mac-title">QuickNote</span>
      </figcaption>
      <div className="mac-content">{children}</div>
    </figure>
  );
}
