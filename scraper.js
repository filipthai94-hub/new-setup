const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

// ═══ MODELLER ATT TRACKA ═══
const MODELS = [
  // iPhone 11-serien
  { search: "iPhone 11", variants: ["64 GB", "128 GB", "256 GB"] },
  { search: "iPhone 11 Pro", variants: ["64 GB", "256 GB", "512 GB"] },
  { search: "iPhone 11 Pro Max", variants: ["64 GB", "256 GB", "512 GB"] },
  // iPhone 12-serien
  { search: "iPhone 12 Mini", variants: ["64 GB", "128 GB", "256 GB"] },
  { search: "iPhone 12", variants: ["64 GB", "128 GB", "256 GB"] },
  { search: "iPhone 12 Pro", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 12 Pro Max", variants: ["128 GB", "256 GB", "512 GB"] },
  // iPhone 13-serien
  { search: "iPhone 13 Mini", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 13", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 13 Pro", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 13 Pro Max", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  // iPhone 14-serien
  { search: "iPhone 14", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 14 Plus", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 14 Pro", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 14 Pro Max", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  // iPhone 15-serien
  { search: "iPhone 15", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 15 Plus", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 15 Pro", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 15 Pro Max", variants: ["256 GB", "512 GB", "1 TB"] },
  // iPhone 16-serien
  { search: "iPhone 16", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 16 Plus", variants: ["128 GB", "256 GB", "512 GB"] },
  { search: "iPhone 16 Pro", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  { search: "iPhone 16 Pro Max", variants: ["256 GB", "512 GB", "1 TB"] },
  // Samsung S22-serien
  { search: "Galaxy S22", variants: ["128 GB", "256 GB"] },
  { search: "Galaxy S22+", variants: ["128 GB", "256 GB"] },
  { search: "Galaxy S22 Ultra", variants: ["128 GB", "256 GB", "512 GB", "1 TB"] },
  // Samsung S23-serien
  { search: "Galaxy S23", variants: ["128 GB", "256 GB"] },
  { search: "Galaxy S23+", variants: ["256 GB", "512 GB"] },
  { search: "Galaxy S23 Ultra", variants: ["256 GB", "512 GB", "1 TB"] },
  // Samsung S24-serien
  { search: "Galaxy S24", variants: ["128 GB", "256 GB"] },
  { search: "Galaxy S24+", variants: ["256 GB", "512 GB"] },
  { search: "Galaxy S24 Ultra", variants: ["256 GB", "512 GB", "1 TB"] },
  // Samsung S25-serien
  { search: "Galaxy S25", variants: ["128 GB", "256 GB"] },
  { search: "Galaxy S25+", variants: ["256 GB", "512 GB"] },
  { search: "Galaxy S25 Ultra", variants: ["256 GB", "512 GB", "1 TB"] },
];

const URL = 'https://phonehero.se/salj-din-gamla-mobil-till-oss';
const DATA_DIR = __dirname;
const PRICES_FILE = path.join(DATA_DIR, 'prices.json');
const HISTORY_DIR = path.join(DATA_DIR, 'history');

async function delay(ms) { return new Promise(r => setTimeout(r, ms)); }

async function getPrice(page, modelSearch, variant) {
  try {
    await page.goto(URL, { waitUntil: 'networkidle2', timeout: 30000 });
    await delay(1000);

    // Steg 1: Sök modellen
    const searchBox = await page.waitForSelector('input[type="search"], input[placeholder*="modell"]', { timeout: 5000 });
    await searchBox.click({ clickCount: 3 });
    await searchBox.type(modelSearch, { delay: 80 });
    await delay(1500);

    // Steg 2: Klicka på rätt sökresultat
    const results = await page.$$('li h5, [class*="result"] h5');
    let clicked = false;
    for (const result of results) {
      const text = await result.evaluate(el => el.textContent.trim());
      // Matcha exakt: "Apple iPhone 15" för sökning "iPhone 15"
      if (text.includes(modelSearch)) {
        await result.click();
        clicked = true;
        break;
      }
    }
    if (!clicked) {
      console.log(`  ⚠️ Modell "${modelSearch}" hittades inte i sökresultat`);
      return null;
    }
    await delay(2000);

    // Steg 3: Välj lagring (GB)
    const radios = await page.$$('input[type="radio"]');
    let storageSelected = false;
    for (const radio of radios) {
      const label = await radio.evaluate(el => {
        const parent = el.closest('label') || el.parentElement;
        return parent ? parent.textContent.trim() : '';
      });
      if (label === variant) {
        await radio.click();
        storageSelected = true;
        break;
      }
    }
    if (!storageSelected) {
      console.log(`  ⚠️ Lagring "${variant}" finns inte för ${modelSearch}`);
      return null;
    }
    await delay(500);

    // Steg 4: Välj bästa skick (nyskick/inga fel/bra batteri)
    // Välj FÖRSTA "Nyskick" (skärm)
    const allRadios = await page.$$('input[type="radio"]');
    const selections = [
      // Vi behöver välja: första färgen (redan vald), lagring (vald ovan),
      // skärm: Nyskick, sidor: Nyskick, fel: Nej, böjd: Nej, batteri: Minst 85%
    ];

    // Klicka alla "Nyskick" och "Nej" och "Minst 85%"
    for (const radio of allRadios) {
      const labelText = await radio.evaluate(el => {
        const parent = el.closest('label') || el.parentElement;
        return parent ? parent.textContent.trim() : '';
      });
      const radioName = await radio.evaluate(el => el.name);

      // Skärm och sidor: Nyskick
      if (labelText === 'Nyskick') {
        const isChecked = await radio.evaluate(el => el.checked);
        if (!isChecked) await radio.click();
      }
      // Fel och böjd: Nej
      if (labelText === 'Nej') {
        const isChecked = await radio.evaluate(el => el.checked);
        if (!isChecked) await radio.click();
      }
      // Batteri: Minst 85%
      if (labelText === 'Minst 85%' || labelText.includes('85%')) {
        const isChecked = await radio.evaluate(el => el.checked);
        if (!isChecked) await radio.click();
      }
    }
    await delay(2000);

    // Steg 5: Läs priset
    // Priset visas som: <h2>Vi betalar</h2><h2>X XXX kr</h2>
    const priceEl = await page.$('h2 + h2');
    if (!priceEl) {
      // Alternativ: sök efter text som matchar prisformat
      const allH2 = await page.$$('h2');
      for (const h2 of allH2) {
        const text = await h2.evaluate(el => el.textContent.trim());
        if (text.match(/^\d[\d\s]*kr$/)) {
          const price = parseInt(text.replace(/\s/g, '').replace('kr', ''));
          return price;
        }
      }
      console.log(`  ⚠️ Kunde inte hitta priset för ${modelSearch} ${variant}`);
      return null;
    }
    const priceText = await priceEl.evaluate(el => el.textContent.trim());
    const price = parseInt(priceText.replace(/\s/g, '').replace('kr', ''));
    return price;

  } catch (err) {
    console.log(`  ❌ Fel vid ${modelSearch} ${variant}: ${err.message}`);
    return null;
  }
}

async function main() {
  console.log('🍔 PhoneHero Prisbevakning — Startar...');
  console.log(`📅 ${new Date().toISOString()}\n`);

  // Hitta Chromium
  const chromiumPath = require('child_process')
    .execSync('which chromium-browser || which chromium || echo ""')
    .toString().trim();

  if (!chromiumPath) {
    console.error('❌ Chromium hittades inte! Installera: sudo apt install chromium-browser');
    process.exit(1);
  }

  const browser = await puppeteer.launch({
    executablePath: chromiumPath,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 900 });

  // Ladda tidigare priser
  let oldPrices = {};
  if (fs.existsSync(PRICES_FILE)) {
    oldPrices = JSON.parse(fs.readFileSync(PRICES_FILE, 'utf8'));
  }

  const newPrices = {};
  const changes = [];
  let total = 0;
  let found = 0;

  for (const model of MODELS) {
    console.log(`📱 ${model.search}...`);
    for (const variant of model.variants) {
      total++;
      const price = await getPrice(page, model.search, variant);
      const key = `${model.search} ${variant}`;

      if (price !== null) {
        found++;
        newPrices[key] = price;
        console.log(`  ✅ ${variant}: ${price} kr`);

        // Jämför med gamla priset
        if (oldPrices[key] !== undefined && oldPrices[key] !== price) {
          const diff = price - oldPrices[key];
          changes.push({
            model: key,
            oldPrice: oldPrices[key],
            newPrice: price,
            diff: diff
          });
        } else if (oldPrices[key] === undefined) {
          changes.push({
            model: key,
            oldPrice: null,
            newPrice: price,
            diff: null
          });
        }
      }
    }
  }

  await browser.close();

  // Spara nya priser
  fs.writeFileSync(PRICES_FILE, JSON.stringify(newPrices, null, 2));

  // Spara historik
  if (!fs.existsSync(HISTORY_DIR)) fs.mkdirSync(HISTORY_DIR, { recursive: true });
  const today = new Date().toISOString().split('T')[0];
  const historyFile = path.join(HISTORY_DIR, `${today}.json`);
  fs.writeFileSync(historyFile, JSON.stringify({
    timestamp: new Date().toISOString(),
    prices: newPrices,
    changes: changes
  }, null, 2));

  // Skriv sammanfattning
  console.log(`\n═══════════════════════════════════`);
  console.log(`✅ Klart: ${found}/${total} priser hämtade`);
  console.log(`📊 Ändringar: ${changes.filter(c => c.diff !== null).length}`);
  console.log(`🆕 Nya: ${changes.filter(c => c.diff === null).length}`);

  // Skriv ändringar till stdout (Alex läser detta)
  if (changes.filter(c => c.diff !== null).length > 0) {
    console.log('\n📋 PRISÄNDRINGAR:');
    console.log(JSON.stringify(changes.filter(c => c.diff !== null)));
  }

  console.log('\n🍔 Klar!');
}

main().catch(err => {
  console.error('❌ Fatal:', err.message);
  process.exit(1);
});
