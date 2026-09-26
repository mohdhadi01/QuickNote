import type { MetadataRoute } from "next";
import { SITE_NAME } from "@/lib/site";

export const dynamic = "force-static";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: SITE_NAME,
    short_name: SITE_NAME,
    icons: [
      { src: "/assets/icon/icon-256.png", sizes: "256x256", type: "image/png" },
      { src: "/assets/icon/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    theme_color: "#0b0b0f",
    background_color: "#0b0b0f",
    display: "browser",
  };
}
