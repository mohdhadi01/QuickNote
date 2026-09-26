import puppeteer from "puppeteer-core";
import fs from "node:fs";

const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const BASE = "http://localhost:8123";
const OUT = "/tmp/qn-qa";
fs.mkdirSync(OUT, { recursive: true });

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: "new",
  args: ["--no-first-run", "--disable-features=Translate"],
});

async function shoot(name, { url = "/", width = 1440, height = 900, scheme = "light", fullPage = false, settle = 900, preScroll = 0 } = {}) {
  const page = await browser.newPage();
  await page.setViewport({ width, height, deviceScaleFactor: 2 });
  await page.emulateMediaFeatures([{ name: "prefers-color-scheme", value: scheme }]);
  await page.goto(BASE + url, { waitUntil: "networkidle0", timeout: 30000 });
  await page.evaluate(() => document.fonts.ready);
  if (preScroll) {
    await page.evaluate((y) => window.scrollTo({ top: y, behavior: "instant" }), preScroll);
  }
  // Walk the page so every scroll-reveal fires before capture.
  await page.evaluate(async () => {
    const step = window.innerHeight * 0.7;
    for (let y = 0; y <= document.body.scrollHeight; y += step) {
      window.scrollTo({ top: y, behavior: "instant" });
      await new Promise((r) => setTimeout(r, 90));
    }
    window.scrollTo({ top: 0, behavior: "instant" });
  });
  await new Promise((r) => setTimeout(r, settle)); // let reveals settle
  await page.screenshot({ path: `${OUT}/${name}.png`, fullPage });
  await page.close();
  console.log("saved", name);
}

// Hero animation phase check: 3 timed frames on a fresh page
{
  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900, deviceScaleFactor: 2 });
  await page.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "dark" }]);
  await page.goto(BASE + "/", { waitUntil: "networkidle0" });
  const grab = async (ms, name) => {
    await new Promise((r) => setTimeout(r, ms));
    await page.screenshot({ path: `${OUT}/${name}.png` });
    console.log("saved", name);
  };
  await grab(1600, "anim-a-panel-empty");
  await grab(1900, "anim-b-typed");      // ~3.5s → 39% (typed visible)
  await grab(3600, "anim-c-result");     // ~7.1s → 79% (result window visible)
  const opacities = await page.evaluate(() => {
    const o = (s) => { const el = document.querySelector(s); return el ? getComputedStyle(el).opacity : null; };
    return { panel: o(".capture-frame"), typed: o(".capture-typed"), result: o(".result-holder") };
  });
  console.log("opacities at end:", JSON.stringify(opacities));
  await page.close();
}

await shoot("desktop-light-hero");
await shoot("desktop-light-full", { fullPage: true });
await shoot("desktop-dark-hero", { scheme: "dark" });
await shoot("desktop-dark-full", { scheme: "dark", fullPage: true });
await shoot("desktop-light-notes", { preScroll: 1500 });
await shoot("mobile-light-hero", { width: 390, height: 844 });
await shoot("mobile-light-full", { width: 390, height: 844, fullPage: true });
await shoot("mobile-dark-hero", { width: 390, height: 844, scheme: "dark" });
await shoot("blog-index-light", { url: "/blog/" });
await shoot("blog-post-light", { url: "/blog/how-to-take-quick-notes-on-mac/" });
await shoot("blog-post-dark", { url: "/blog/apple-notes-vs-quicknote/", scheme: "dark" });

await browser.close();
console.log("done");
