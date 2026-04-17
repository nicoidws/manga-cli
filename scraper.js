const puppeteer = require("puppeteer");
const fs = require("fs");

(async () => {
  const url = process.argv[2];

  if (!url) {
    console.log("Uso: node scraper.js <URL>");
    process.exit(1);
  }

  const browser = await puppeteer.launch({
    headless: true,
    args: ["--no-sandbox"]
  });

  const page = await browser.newPage();
  const images = new Set();

  // 🔥 Captura TODAS las imágenes reales
  page.on("response", async (res) => {
    const u = res.url();

    if (u.includes("image") || u.match(/\.(jpg|jpeg|png|webp)/)) {
      images.add(u);
      console.log("🖼", u);
    }
  });

  await page.goto(url, { waitUntil: "networkidle2" });

  console.log("🧠 Simulando scroll...");

  // 🔥 Scroll automático
  for (let i = 0; i < 15; i++) {
    await page.evaluate(() => window.scrollBy(0, window.innerHeight));
    await new Promise(r => setTimeout(r, 500));
  }

  console.log("⏳ Esperando carga...");
  await new Promise(r => setTimeout(r, 5000));

  if (images.size === 0) {
    console.log("❌ No images");
    await browser.close();
    process.exit(1);
  }

  if (!fs.existsSync("imgs")) fs.mkdirSync("imgs");

  // ⚡ DESCARGA PARALELA
  const arr = Array.from(images);

  await Promise.all(arr.map(async (img, i) => {
    try {
      const res = await page.goto(img);
      const buffer = await res.buffer();
      fs.writeFileSync(`imgs/${i + 1}.jpg`, buffer);
      console.log("⬇", i + 1);
    } catch {}
  }));

  await browser.close();
})();