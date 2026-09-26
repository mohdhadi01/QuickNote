import type { NextConfig } from "next";

/**
 * Static export: `npm run build` produces a fully static `out/` folder that
 * deploys to any host (Vercel, Netlify, GitHub Pages, Cloudflare Pages).
 * The DMG is served from the same origin at /downloads/.
 */
const nextConfig: NextConfig = {
  output: "export",
  images: { unoptimized: true },
  // Deploying under a subpath (e.g. GitHub Pages /repo)? Set basePath here:
  // basePath: "/quicknote",
  trailingSlash: true,
};

export default nextConfig;
