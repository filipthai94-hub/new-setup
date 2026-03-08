#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════════
// 🍔 PhoneHero Prisbevakning — Scraper v3 (testad & verifierad)
// Scrapar inköpspriser för iPhone 11+ och Samsung S22+
// Använder radio name-attribut för robusthet
// ═══════════════════════════════════════════════════════════════
const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const URL = 'https://phonehero.se/salj-din-gamla-mobil-till-oss';
const DATA_DIR = __dirname;
const PRICES_FILE = path.join(DATA_DIR, 'prices.json');
const HISTORY_DIR = path.join(DATA_DIR, 'history');

const delay = ms => new Promise(r => setTimeout(r, ms));

// ═══ MODELLER ATT TRACKA ═══
const MODELS = [
  // iPhone 11-serien
  { search: "iPhone 11", match: "Apple iPhone 11", variants: ["64 GB", "128 GB", "256 GB"] },
  { search: "iPhone 11 Pro Max", match: "Apple iPhone 11 Pro Max", variants: ["64 GB", "256 GB", "512 GB"] },
  { search: "iPhone 11 Pro", match: "Apple iPhone 11 Pro", variants: ["64 GB", "256 GB", "512 GB"] },
  // iPhone 12-serien
  { search: "iPhone 12 Mini", match: "Apple iPhone 12 Mini", variants: ["64 GB", "128 GB", "256 GB"] },
  { search: "iPhone 12 Pro Max", match: "Apple iPhone 12 Pro Max", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 12 Pro", match: "Apple iPhone 12 Pro", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 12", match: "Apple iPhone 12", variants: ["64 GB", "128 GB", "256 GB"] },
  // iPhone 13-serien
  { search: "iPhone 13 Mini", match: "Apple iPhone 13 Mini", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 13 Pro Max", match: "Apple iPhone 13 Pro Max", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 13 Pro", match: "Apple iPhone 13 Pro", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 13", match: "Apple iPhone 13", variants: ["128 GB", "256 GB", "512 GB"] },
  // iPhone 14-serien
  { search: "iPhone 14 Plus", match: "Apple iPhone 14 Plus", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 14 Pro Max", match: "Apple iPhone 14 Pro Max", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 14 Pro", match: "Apple iPhone 14 Pro", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 14", match: "Apple iPhone 14", variants: ["128 GB", "256 GB", "512 GB"] },
  // iPhone 15-serien
  { search: "iPhone 15 Plus", match: "Apple iPhone 15 Plus", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 15 Pro Max", match: "Apple iPhone 15 Pro Max", variants: ["256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 15 Pro", match: "Apple iPhone 15 Pro", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 15", match: "Apple iPhone 15", variants: ["128 GB", "256 GB", "512 GB"] },
  // iPhone 16-serien
  { search: "iPhone 16 Plus", match: "Apple iPhone 16 Plus", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 16 Pro Max", match: "Apple iPhone 16 Pro Max", variants: ["256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 16 Pro", match: "Apple iPhone 16 Pro", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 16", match: "Apple iPhone 16", variants: ["128 GB", "256 GB", "512 GB"] },
  // Samsung S22-serien
  { search: "Galaxy S22 Ultra", match: "Samsung Galaxy S22 Ultra", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "Galaxy S22+", match: "Samsung Galaxy S22+", variants: ["128 GB", "256 GB"] },
  { search: "Galaxy S22", match: "Samsung Galaxy S22", variants: ["128 GB", "256 GB"] },
  // Samsung S23-serien
  { search: "Galaxy S23 Ultra", match: "Samsung Galaxy S23 Ultra", variants: ["256 GB", "512 GB", "1 TB"] },
  { search: "Galaxy S23+", match: "Samsung Galaxy S23+", variants: ["256 GB", "512 GB"] },
  { search: "Galaxy S23", match: "Samsung Galaxy S23", variants: ["128 GB", "256 GB"] },
  // Samsung S24-serien
  { search: "Galaxy S24 Ultra", match: "Samsung Galaxy S24 Ultra", variants: ["256 GB", "512 GB", "1 TB"] },
  { search: "Galaxy S24+", match: "Samsung Galaxy S24+", variants: ["256 GB", "512 GB"] },
  { search: "Galaxy S24", match: "Samsung Galaxy S24", variants: ["128 GB", "256 GB"] },
  // Samsung S25-serien
  { search: "Galaxy S25 Ultra", match: "Samsung Galaxy S25 Ultra", variants: ["256 GB", "512 GB", "1 TB"] },
  { search: "Galaxy S25+", match: "Samsung Galaxy S25+", variants: ["256 GB", "512 GB"] },
  { search: "Galaxy S25", match: "Samsung Galaxy S25", variants: ["128 GB", "256 GB"] },
];

// ═══ PRISHÄMTNING ═══

async function getPrice(page, model, variant) {
  try {
    await page.goto(URL, { waitUntil: 'networkidle2', timeout: 30000 });
    await delay(1500);

    // Acceptera cookies
    try {
      const buttons = await page.$$('button');
      for (const btn of buttons) {
        const text = await btn.evaluate(el => el.textContent.trim());
        if (text === 'Acceptera') { await btn.click(); await delay(500); break; }
      }
    } catch(e) {}

    // SÖK modell
    const searchBox = await page.waitForSelector('input[type="search"]', { timeout: 5000 });
    await searchBox.click({ clickCount: 3 });
    await searchBox.type(model.search, { delay: 50 });
    await delay(2000);

    // Klicka EXAKT sökresultat (via match-fält)
    const items = await page.$$('h5');
    let clicked = false;
    for (const item of items) {
      const text = await item.evaluate(el => el.textContent.trim());
      if (text === model.match) {
        await item.click();
        clicked = true;
        break;
      }
    }
    if (!clicked) {
      // Fallback: partial match
      for (const item of items) {
        const text = await item.evaluate(el => el.textContent.trim());
        if (text.includes(model.search) && !text.includes('Plus') && !text.includes('Ultra') && !text.includes('Max') && !text.includes('+')) {
          await item.click();
          clicked = true;
          break;
        }
      }
    }
    if (!clicked) return null;
    await delay(2500);

    // ═══ WIZARD: Välj via radio name-attribut ═══

    // 1. Färg: klicka första colorselect
    try { await page.click('input[name="colorselect"]'); } catch(e) {}
    await delay(400);

    // 2. Lagring: hitta rätt selectedsize
    const storageOk = await page.evaluate((v) => {
      const radios = document.querySelectorAll('input[name="selectedsize"]');
      for (const r of radios) {
        const container = r.closest('div') || r.parentElement;
        if (container?.textContent?.includes(v)) { r.click(); return true; }
      }
      return false;
    }, variant);
    if (!storageOk) return null;
    await delay(400);

    // 3-7. Condition questions: välj FÖRSTA alternativet för varje
    // (Första = bästa skick: Nyskick/Nej/Minst 85%)
    // OBS: PhoneHero har space i name: " question-0"
    for (const name of [' question-0', ' question-1', ' question-2', ' question-3', ' question-4',
                         'question-0', 'question-1', 'question-2', 'question-3', 'question-4']) {
      try {
        const radio = await page.$(`input[name="${name}"]`);
        if (radio) { await radio.click(); await delay(300); }
      } catch(e) {}
    }
    await delay(1500);

    // Klicka Fortsätt
    const btns = await page.$$('button');
    for (const btn of btns) {
      const text = await btn.evaluate(el => el.textContent.trim());
      const visible = await btn.evaluate(el => el.offsetParent !== null);
      if (text === 'Fortsätt' && visible) {
        await btn.click();
        await delay(2500);
        break;
      }
    }

    // ═══ LÄS PRIS: "Vi betalar" + nästa h2 ═══
    await delay(1000);
    const price = await page.evaluate(() => {
      const h2s = Array.from(document.querySelectorAll('h2'));
      for (let i = 0; i < h2s.length; i++) {
        if (h2s[i].textContent.trim() === 'Vi betalar' && h2s[i+1]) {
          const next = h2s[i+1].textContent.trim();
          if (next.match(/\d.*kr/)) return next;
        }
      }
      return null;
    });

    if (price) {
      return parseInt(price.replace(/\s/g, '').replace('kr', ''));
    }
    return null;

  } catch (err) {
    return null;
  }
}

// ═══ HUVUDPROGRAM ═══

async function main() {
  console.log('🍔 PhoneHero Prisbevakning — Startar...');
  console.log(`📅 ${new Date().toISOString()}\n`);

  // Hitta Chromium
  let chromiumPath;
  try { chromiumPath = execSync('which chromium-browser || which chromium || echo ""').toString().trim(); } catch(e) {}
  if (!chromiumPath) { console.error('❌ Chromium hittades inte!'); process.exit(1); }

  let browser;
  let isConnected = false;

  // Försök CDP först
  try {
    const resp = await fetch('http://127.0.0.1:18800/json/version').catch(() => null);
    if (resp) {
      const info = await resp.json();
      browser = await puppeteer.connect({ browserWSEndpoint: info.webSocketDebuggerUrl });
      isConnected = true;
      console.log('🔗 Anslöt till Chromium (CDP port 18800)');
    }
  } catch(e) {}

  // Annars starta ny instans
  if (!browser) {
    browser = await puppeteer.launch({
      executablePath: chromiumPath,
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu']
    });
    console.log('🚀 Startade ny Chromium-instans');
  }

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 900 });

  // Ladda gamla priser
  let oldPrices = {};
  if (fs.existsSync(PRICES_FILE)) {
    try { oldPrices = JSON.parse(fs.readFileSync(PRICES_FILE, 'utf8')); } catch(e) {}
  }

  const newPrices = {};
  const changes = [];
  let total = 0, found = 0, errors = 0;

  for (const model of MODELS) {
    console.log(`\n📱 ${model.search}`);
    for (const variant of model.variants) {
      total++;
      const price = await getPrice(page, model, variant);
      const key = `${model.search} ${variant}`;

      if (price !== null) {
        found++;
        newPrices[key] = price;
        console.log(`  ✅ ${variant}: ${price.toLocaleString('sv-SE')} kr`);

        // Jämför med gammalt pris
        if (oldPrices[key] !== undefined && oldPrices[key] !== price) {
          changes.push({ model: key, oldPrice: oldPrices[key], newPrice: price, diff: price - oldPrices[key] });
        }
      } else {
        errors++;
        console.log(`  ⚠️ ${variant}: ej tillgänglig`);
        if (oldPrices[key]) newPrices[key] = oldPrices[key]; // Behåll gammalt
      }
    }
  }

  await page.close();
  if (isConnected) {
    try { await browser.disconnect(); } catch(e) {}
  } else {
    try { await browser.close(); } catch(e) {}
  }

  // Spara nya priser
  fs.writeFileSync(PRICES_FILE, JSON.stringify(newPrices, null, 2));

  // Spara historik
  if (!fs.existsSync(HISTORY_DIR)) fs.mkdirSync(HISTORY_DIR, { recursive: true });
  const today = new Date().toISOString().split('T')[0];
  const historyFile = path.join(HISTORY_DIR, `${today}.json`);
  fs.writeFileSync(historyFile, JSON.stringify({
    timestamp: new Date().toISOString(),
    total, found, errors,
    prices: newPrices,
    changes
  }, null, 2));

  // Sammanfattning
  console.log('\n═══════════════════════════════════');
  console.log(`✅ ${found}/${total} priser hämtade (${errors} ej tillgängliga)`);
  console.log(`📊 Prisändringar: ${changes.length}`);

  if (changes.length > 0) {
    console.log('\n📋 PRISÄNDRINGAR:');
    for (const c of changes) {
      const arrow = c.diff > 0 ? '↑' : '↓';
      console.log(`  ${c.model}: ${c.oldPrice.toLocaleString('sv-SE')} → ${c.newPrice.toLocaleString('sv-SE')} kr (${arrow}${Math.abs(c.diff)} kr)`);
    }
    console.log('\n__CHANGES_JSON__');
    console.log(JSON.stringify(changes));
  } else {
    console.log('✅ Inga prisändringar sedan senast');
  }

  console.log('\n🍔 Klar!');
}

main().catch(err => {
  console.error('❌ Fatal:', err.message);
  process.exit(1);
});
