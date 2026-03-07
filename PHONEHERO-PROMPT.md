# 🍔 Alex Master Prompt — PhoneHero Prisbevakning

## DIN UPPGIFT

Du ska hjälpa Yen att automatiskt bevaka inköpspriser på PhoneHero.se för iPhones och Samsung-modeller. Du ska göra detta 2 gånger per dag (08:00 och 18:00 Stockholm-tid), jämföra mot tidigare priser, och pinga Yen i Discord när priser ändras.

---

## STEG 1: SETUP (gör detta EN gång)

### 1.1 Installera Puppeteer
```bash
cd ~/.openclaw/workspace/projects
mkdir -p phonehero-scraping/history
cd phonehero-scraping
npm init -y
npm install puppeteer-core
```

OBS: Chromium ska redan vara installerat. Kontrollera med:
```bash
which chromium-browser || which chromium
```
Om det saknas: `sudo apt install -y chromium-browser`

### 1.2 Skapa scraper-scriptet

Skapa filen `~/.openclaw/workspace/projects/phonehero-scraping/scraper.js` med EXAKT detta innehåll:

```javascript
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
```

### 1.3 Testa scriptet
```bash
cd ~/.openclaw/workspace/projects/phonehero-scraping
node scraper.js
```

Kontrollera att `prices.json` skapas med priser. Första körningen har inga ändringar (baseline).

---

## STEG 2: AUTOMATISK KÖRNING (Heartbeat)

### 2.1 Uppdatera HEARTBEAT.md

Lägg till detta i `~/.openclaw/workspace/HEARTBEAT.md`:

```markdown
## 📱 PhoneHero Prisbevakning (08:00 + 18:00 Stockholm)

### Tidskontroll
Kör BARA om klockan är 06:00-08:30 UTC ELLER 16:00-18:30 UTC (= 08:00/18:00 Stockholm).
Om datorn var avstängd under dessa tider → kör vid nästa uppstart (EN gång).

### Körning
1. Kör: `cd ~/.openclaw/workspace/projects/phonehero-scraping && node scraper.js`
2. Läs output
3. Om PRISÄNDRINGAR finns → pinga Yen i Discord (se format nedan)
4. Om inga ändringar → logga tyst i dagsfilen, INGEN Discord-ping

### Discord-format vid 1 ändring:
📱 **PhoneHero prisändring!**
iPhone 15 128 GB: 4 200 kr → 4 100 kr (-100 kr)

### Discord-format vid flera ändringar:
📱 **PhoneHero prisändringar!**
| Modell | Förut | Nu | Ändring |
|--------|-------|----|---------|
| iPhone 15 128 GB | 4 200 kr | 4 100 kr | -100 kr |
| Galaxy S24 256 GB | 4 500 kr | 4 600 kr | +100 kr |

### Om scriptet felar
- Logga felet i dagsfilen
- Pinga INTE Yen för tekniska fel
- Försök igen vid nästa schemalagda körning
```

---

## STEG 3: FILSTRUKTUR

```
~/.openclaw/workspace/projects/phonehero-scraping/
├── package.json              ← npm dependencies
├── node_modules/             ← puppeteer-core
├── scraper.js                ← Huvudscriptet (REDIGERA ALDRIG utan Yens OK)
├── prices.json               ← Senaste priser (överskrivsvarje körning)
├── history/
│   ├── 2026-03-07.json       ← Daglig historik
│   └── 2026-03-08.json
└── README.md                 ← Denna fil (kortversion)
```

---

## REGLER (ABSOLUTA)

1. **REDIGERA ALDRIG `scraper.js`** utan att Yen ber om det
2. **Pinga ALDRIG Yen** om inga prisändringar — bara vid faktiska ändringar
3. **Kör ALDRIG scriptet** utanför schemalagda tider (om inte Yen ber om det manuellt)
4. **Spara ALDRIG** prisfiler utanför `projects/phonehero-scraping/`
5. **Radera ALDRIG** historikfiler — de är Yens data
6. **Max 1 historikfil per dag** — om scriptet körs 2x samma dag, lägg till i samma fil
7. Om Yen säger **"kolla phonehero"** → kör scriptet manuellt och rapportera

---

## MANUELL KÖRNING

Om Yen ber dig kolla priser:
```bash
cd ~/.openclaw/workspace/projects/phonehero-scraping && node scraper.js
```

Läs output och rapportera:
- Om ändringar: visa tabellen
- Om inga ändringar: "Inga prisändringar sedan senast! 🍔"
- Om fel: beskriv felet enkelt (ingen teknisk jargong)

---

## MODELLER SOM TRACKAS

### iPhone (11 och nyare)
iPhone 11, 11 Pro, 11 Pro Max, 12 Mini, 12, 12 Pro, 12 Pro Max, 13 Mini, 13, 13 Pro, 13 Pro Max, 14, 14 Plus, 14 Pro, 14 Pro Max, 15, 15 Plus, 15 Pro, 15 Pro Max, 16, 16 Plus, 16 Pro, 16 Pro Max

### Samsung (S22 och nyare)
Galaxy S22, S22+, S22 Ultra, S23, S23+, S23 Ultra, S24, S24+, S24 Ultra, S25, S25+, S25 Ultra

### Prisvillkor
- Färg: valfri (första tillgängliga)
- Skick: **Nyskick** (skärm + sidor)
- Fel: **Nej**
- Böjd/fuktskadad: **Nej**
- Batteri: **Minst 85%**

Detta ger **maxpriset** — det högsta PhoneHero betalar för en telefon i perfekt skick.
