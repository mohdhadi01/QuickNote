import fs from "node:fs";
import path from "node:path";
import matter from "gray-matter";
import { marked } from "marked";

/**
 * Blog content lives in content/posts/*.md with frontmatter:
 *   title, description, date (YYYY-MM-DD), keywords (comma-separated)
 * Rendered to HTML at build time (static export — no runtime cost).
 */

const POSTS_DIR = path.join(process.cwd(), "content", "posts");

export interface PostMeta {
  slug: string;
  title: string;
  description: string;
  date: string;
  readingTime: number;
  keywords: string[];
}

export interface Post extends PostMeta {
  html: string;
}

marked.setOptions({ async: false, gfm: true });

function readPostFile(slug: string): Post {
  const raw = fs.readFileSync(path.join(POSTS_DIR, `${slug}.md`), "utf8");
  const { data, content } = matter(raw);
  const words = content.split(/\s+/).filter(Boolean).length;

  const keywords = Array.isArray(data.keywords)
    ? (data.keywords as string[])
    : String(data.keywords ?? "")
        .split(",")
        .map((k) => k.trim())
        .filter(Boolean);

  return {
    slug,
    title: String(data.title ?? slug),
    description: String(data.description ?? ""),
    date: String(data.date ?? ""),
    readingTime: Math.max(1, Math.round(words / 200)),
    keywords,
    html: marked.parse(content) as string,
  };
}

export function getPostSlugs(): string[] {
  if (!fs.existsSync(POSTS_DIR)) return [];
  return fs
    .readdirSync(POSTS_DIR)
    .filter((f) => f.endsWith(".md"))
    .map((f) => f.replace(/\.md$/, ""));
}

export function getAllPosts(): PostMeta[] {
  return getPostSlugs()
    .map((slug) => {
      const { html: _html, ...meta } = readPostFile(slug);
      return meta;
    })
    .sort((a, b) => (a.date < b.date ? 1 : -1));
}

export function getPost(slug: string): Post | undefined {
  if (!getPostSlugs().includes(slug)) return undefined;
  return readPostFile(slug);
}
