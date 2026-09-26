import type { Metadata } from "next";
import Link from "next/link";
import { getAllPosts } from "@/lib/posts";
import { SITE_NAME, SITE_URL } from "@/lib/site";

export const metadata: Metadata = {
  title: "Blog — quick capture, keyboard workflows & a calmer Mac",
  description:
    "Practical guides for taking quick notes on macOS: capture workflows, keyboard shortcuts, menu bar tools, and keeping your thoughts organized — from the makers of QuickNote.",
  alternates: { canonical: "/blog" },
  openGraph: {
    title: `Blog · ${SITE_NAME}`,
    description:
      "Practical guides for taking quick notes on macOS — capture workflows, keyboard shortcuts, and menu bar tools.",
    url: "/blog",
    type: "website",
  },
};

export default function BlogIndex() {
  const posts = getAllPosts();

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Blog",
    name: `${SITE_NAME} Blog`,
    url: `${SITE_URL}/blog/`,
    blogPost: posts.map((p) => ({
      "@type": "BlogPosting",
      headline: p.title,
      description: p.description,
      datePublished: p.date,
      url: `${SITE_URL}/blog/${p.slug}/`,
    })),
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <header className="blog-header">
        <p className="eyebrow">Blog</p>
        <h1>Capture faster. Think clearer.</h1>
        <p className="section-lede">
          Short, practical guides about quick capture, keyboard-first workflows, and keeping a
          Mac tidy — written by the person who built QuickNote.
        </p>
      </header>

      <ul className="post-list">
        {posts.map((post) => (
          <li key={post.slug}>
            <Link className="post-card card reveal" href={`/blog/${post.slug}/`}>
              <h3>{post.title}</h3>
              <p>{post.description}</p>
              <div className="post-meta">
                <time dateTime={post.date}>
                  {new Date(post.date + "T00:00:00").toLocaleDateString("en-US", {
                    year: "numeric",
                    month: "long",
                    day: "numeric",
                  })}
                </time>
                <span>{post.readingTime} min read</span>
              </div>
              <span className="post-more">Read the guide →</span>
            </Link>
          </li>
        ))}
      </ul>
    </>
  );
}
