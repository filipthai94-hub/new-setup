#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🍔 PhoneHero Prisbevakning — Setup för Alex
# Installerar Chromium + Puppeteer + Scraper-script
# ═══════════════════════════════════════════════════════════════
set -e

W="$HOME/.openclaw/workspace"
PROJECT="$W/projects/phonehero-scraping"

echo "═══════════════════════════════════════════════════"
echo "  🍔 PhoneHero Prisbevakning — Setup"
echo "═══════════════════════════════════════════════════"
echo ""

# ═══ 1. Installera Chromium ═══
echo "⏳ Kontrollerar Chromium..."
if command -v chromium-browser &>/dev/null || command -v chromium &>/dev/null; then
  echo "✅ Chromium redan installerat"
else
  echo "⏳ Installerar Chromium..."
  sudo apt update -qq && sudo apt install -y -qq chromium-browser 2>/dev/null || sudo apt install -y -qq chromium
  echo "✅ Chromium installerat"
fi

CHROMIUM_PATH=$(which chromium-browser 2>/dev/null || which chromium 2>/dev/null)
echo "   Path: $CHROMIUM_PATH"

# ═══ 2. Skapa projektmapp ═══
echo ""
echo "⏳ Skapar projektmapp..."
mkdir -p "$PROJECT/history"

# ═══ 3. Installera Puppeteer ═══
echo "⏳ Installerar Puppeteer..."
cd "$PROJECT"
if [ ! -f package.json ]; then
  npm init -y --silent 2>/dev/null
fi
npm install --save puppeteer-core 2>/dev/null
echo "✅ Puppeteer installerat"

# ═══ 4. Ladda ner scraper-script ═══
echo ""
echo "⏳ Laddar ner scraper-script..."
curl -fsSL "https://raw.githubusercontent.com/filipthai94-hub/new-setup/main/scraper.js" -o "$PROJECT/scraper.js"
echo "✅ Scraper nedladdad"

# ═══ 5. Ladda ner master-prompt ═══
echo "⏳ Laddar ner master-prompt..."
curl -fsSL "https://raw.githubusercontent.com/filipthai94-hub/new-setup/main/PHONEHERO-PROMPT.md" -o "$PROJECT/README.md"
echo "✅ Master-prompt sparad som README.md"

# ═══ 6. Uppdatera HEARTBEAT.md ═══
echo ""
echo "⏳ Uppdaterar HEARTBEAT.md..."
HEARTBEAT="$W/HEARTBEAT.md"
if ! grep -q "PhoneHero" "$HEARTBEAT" 2>/dev/null; then
  cat >> "$HEARTBEAT" << 'HEOF'

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
[Modell]: [gammalt pris] → [nytt pris] ([+/- skillnad])

### Discord-format vid flera ändringar:
📱 **PhoneHero prisändringar!**
| Modell | Förut | Nu | Ändring |
|--------|-------|----|---------|
(tabell med alla ändringar)

### Om scriptet felar
Logga felet i dagsfilen, pinga INTE Yen, försök igen vid nästa körning.
HEOF
  echo "✅ HEARTBEAT.md uppdaterad"
else
  echo "✅ HEARTBEAT.md redan har PhoneHero-entry"
fi

# ═══ 7. Uppdatera TOOLS.md ═══
echo "⏳ Uppdaterar TOOLS.md..."
TOOLS="$W/TOOLS.md"
if ! grep -q "PhoneHero" "$TOOLS" 2>/dev/null; then
  cat >> "$TOOLS" << 'TEOF'

---

## 📱 PhoneHero Prisbevakning

- **Projektmapp:** `projects/phonehero-scraping/`
- **Scraper:** `node projects/phonehero-scraping/scraper.js`
- **Data:** `projects/phonehero-scraping/prices.json`
- **Historik:** `projects/phonehero-scraping/history/YYYY-MM-DD.json`
- **Schema:** 08:00 + 18:00 Stockholm (via HEARTBEAT.md)
- **Master-prompt:** `projects/phonehero-scraping/README.md`

### Kommandon
- Manuell körning: `cd ~/.openclaw/workspace/projects/phonehero-scraping && node scraper.js`
- Om Yen säger "kolla phonehero" → kör scriptet och rapportera

### Regler
- Pinga ALDRIG Yen om inga ändringar
- Redigera ALDRIG scraper.js utan Yens OK
- Max 1 historikfil per dag
TEOF
  echo "✅ TOOLS.md uppdaterad"
else
  echo "✅ TOOLS.md redan har PhoneHero-entry"
fi

# ═══ 8. Första körning (baseline) ═══
echo ""
echo "⏳ Kör första scrape (skapar baseline)..."
echo "   OBS: Detta tar 5-15 minuter (90+ modeller)"
echo ""
cd "$PROJECT"
timeout 900 node scraper.js || echo "⚠️ Scraper avbröts eller hade fel — kolla output ovan"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  🍔 PhoneHero Prisbevakning — Installerad!"
echo ""
echo "  📁 Projekt: $PROJECT"
echo "  📊 Priser:  $PROJECT/prices.json"
echo "  📜 Historik: $PROJECT/history/"
echo "  ⏰ Schema:  08:00 + 18:00 Stockholm (heartbeat)"
echo ""
echo "  Testa manuellt: cd $PROJECT && node scraper.js"
echo "═══════════════════════════════════════════════════"
