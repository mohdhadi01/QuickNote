import puppeteer from "puppeteer-core";

const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const browser = await puppeteer.launch({ executablePath: CHROME, headless: "new" });
const page = await browser.newPage();
await page.setViewport({ width: 1440, height: 900 });
await page.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "light" }]);
await page.goto("http://localhost:8123/", { waitUntil: "networkidle0" });
await new Promise((r) => setTimeout(r, 600));

const probe = async (label) => {
  const data = await page.evaluate(() => {
    const out = { theme: document.documentElement.dataset.theme, frame: null, imgs: [] };
    const frame = document.querySelector(".capture-frame");
    const fr = frame.getBoundingClientRect();
    out.frame = { w: +fr.width.toFixed(1), h: +fr.height.toFixed(1), overflow: getComputedStyle(frame).overflow };
    frame.querySelectorAll("img").forEach((img) => {
      const r = img.getBoundingClientRect();
      out.imgs.push({
        src: img.getAttribute("src").split("/").pop(),
        display: getComputedStyle(img).display,
        position: getComputedStyle(img).position,
        opacity: getComputedStyle(img).opacity,
        rect: { x: +r.x.toFixed(1), y: +r.y.toFixed(1), w: +r.width.toFixed(1), h: +r.height.toFixed(1) },
      });
    });
    return out;
  });
  console.log(label, JSON.stringify(data, null, 1));
};

await probe("LIGHT:");
await page.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "dark" }]);
await new Promise((r) => setTimeout(r, 300));
await probe("DARK:");
await browser.close();
