#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🦞 OpenClaw AI-assistent — Interaktivt Setup Script
# Kör: curl -fsSL https://raw.githubusercontent.com/filipthai94-hub/new-setup/main/setup.sh | bash
# ═══════════════════════════════════════════════════════════════
set -e

OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE="$OPENCLAW_DIR/workspace"
ENV_FILE="$OPENCLAW_DIR/.env"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"

clear
echo "═══════════════════════════════════════════════════"
echo "  🦞 OpenClaw AI-assistent — Setup"
echo "  Välkommen! Vi sätter upp din egen AI-assistent."
echo "═══════════════════════════════════════════════════"
echo ""

# ═══ Kontroller ═══
if ! command -v openclaw &> /dev/null; then
    echo "❌ OpenClaw är inte installerat!"
    echo "   Kör först: sudo npm install -g openclaw"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ OpenClaw är inte konfigurerat!"
    echo "   Kör först: openclaw setup"
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env-fil saknas!"
    echo "   Skapa den först: nano $ENV_FILE"
    echo ""
    echo "   Lägg in dina API-nycklar (en per rad):"
    echo "   OLLAMA_API_KEY=din-nyckel"
    echo "   GROQ_API_KEY=din-nyckel"
    echo "   GOOGLE_AI_API_KEY=din-nyckel"
    echo "   OPENROUTER_API_KEY=din-nyckel"
    echo "   MISTRAL_API_KEY=din-nyckel"
    exit 1
fi

echo "✅ OpenClaw installerat"
echo "✅ Config hittad"
echo "✅ API-nycklar hittade"
echo ""
echo "───────────────────────────────────────────────────"
echo "  📝 Lite frågor så vi kan anpassa din assistent!"
echo "───────────────────────────────────────────────────"
echo ""

# ═══ Frågor ═══

# 1. Användarens namn
read -p "👤 Vad heter du? " USER_NAME
while [ -z "$USER_NAME" ]; do
    read -p "   Du måste ange ett namn: " USER_NAME
done

# 2. Pronomen
echo ""
echo "📌 Vilka pronomen använder du?"
echo "   1) hon/henne"
echo "   2) han/honom"
echo "   3) hen/hen"
read -p "   Välj (1/2/3): " PRONOUN_CHOICE
case $PRONOUN_CHOICE in
    1) PRONOUNS="hon/henne" ;;
    2) PRONOUNS="han/honom" ;;
    3) PRONOUNS="hen/hen" ;;
    *) PRONOUNS="hen/hen" ;;
esac

# 3. Vad gör du
echo ""
echo "💼 Vad gör du? (t.ex. 'Studerar ekonomi', 'Jobbar med försäljning', 'Egen företagare')"
read -p "   > " USER_OCCUPATION
if [ -z "$USER_OCCUPATION" ]; then
    USER_OCCUPATION="Inte angivet"
fi

# 4. Vad vill du ha hjälp med
echo ""
echo "🎯 Vad vill du främst ha hjälp med?"
echo "   Exempel: 'Skola och läxor', 'Jobbet', 'Skriva texter', 'Planering', 'Allmänt'"
read -p "   > " USER_HELPWITH
if [ -z "$USER_HELPWITH" ]; then
    USER_HELPWITH="Allmänt"
fi

# 5. Kommunikationsstil
echo ""
echo "💬 Hur ska din assistent prata?"
echo "   1) Enkelt och kort — rakt på sak"
echo "   2) Detaljerat — förklarar steg för steg"
echo "   3) Blandat — kort vid enkla frågor, detaljerat vid komplexa"
read -p "   Välj (1/2/3): " STYLE_CHOICE
case $STYLE_CHOICE in
    1) COMM_STYLE="Kort och rakt på sak. Inga onödiga förklaringar." ;;
    2) COMM_STYLE="Detaljerat med steg-för-steg-förklaringar. Förklara tekniska termer." ;;
    3) COMM_STYLE="Blandat — kort vid enkla frågor, detaljerat och grundligt vid komplexa." ;;
    *) COMM_STYLE="Blandat — kort vid enkla frågor, detaljerat och grundligt vid komplexa." ;;
esac

# 6. Botens namn
echo ""
read -p "🤖 Vad ska din assistent heta? " BOT_NAME
while [ -z "$BOT_NAME" ]; do
    read -p "   Du måste ange ett namn: " BOT_NAME
done

# 7. Botens emoji
echo ""
read -p "✨ Vilken emoji ska ${BOT_NAME} ha? " BOT_EMOJI
while [ -z "$BOT_EMOJI" ]; do
    read -p "   Du måste välja en emoji: " BOT_EMOJI
done

# 8. Discord guild-ID
echo ""
echo "🔗 Discord guild-ID"
echo "   Så här hittar du det:"
echo "   1. Öppna Discord → Inställningar → Avancerat → Aktivera 'Utvecklarläge'"
echo "   2. Högerklicka på din server (ikonen till vänster) → 'Kopiera server-ID'"
read -p "   Klistra in ditt Guild ID: " GUILD_ID
while [ -z "$GUILD_ID" ]; do
    read -p "   Du måste ange guild-ID: " GUILD_ID
done

# ═══ Sammanfattning ═══
echo ""
echo "═══════════════════════════════════════════════════"
echo "  📋 Sammanfattning"
echo "═══════════════════════════════════════════════════"
echo ""
echo "  👤 Användare:  $USER_NAME ($PRONOUNS)"
echo "  💼 Syssla:     $USER_OCCUPATION"
echo "  🎯 Hjälp med:  $USER_HELPWITH"
echo "  🤖 Assistent:  $BOT_NAME $BOT_EMOJI"
echo "  🔗 Guild ID:   $GUILD_ID"
echo ""
read -p "  Stämmer allt? (j/n): " CONFIRM
if [ "$CONFIRM" != "j" ] && [ "$CONFIRM" != "J" ] && [ "$CONFIRM" != "ja" ]; then
    echo "❌ Avbruten. Kör scriptet igen!"
    exit 1
fi

echo ""
echo "⏳ Skapar filer..."

# ═══ Skapa mappar ═══
mkdir -p "$WORKSPACE/memory/archive"
mkdir -p "$WORKSPACE/projects"
mkdir -p "$WORKSPACE/scripts"
mkdir -p "$WORKSPACE/.learnings"

# ═══ IDENTITY.md ═══
cat > "$WORKSPACE/IDENTITY.md" << MDEOF
# IDENTITY.md

- **Name:** $BOT_NAME
- **Creature:** AI-assistent — din digitala partner
- **Vibe:** Varm, hjälpsam, chill, ärlig
- **Emoji:** $BOT_EMOJI
MDEOF

# ═══ SOUL.md ═══
cat > "$WORKSPACE/SOUL.md" << MDEOF
# SOUL.md — $BOT_NAME Core Identity

## $BOT_EMOJI Identity
- **Namn:** $BOT_NAME
- **Roll:** Digital assistent till $USER_NAME
- **Vibe:** Vänlig, tålmodig, hjälpsam, ärlig
- **Emoji:** $BOT_EMOJI

## 💬 Kommunikation
- **Språk:** Svenska med $USER_NAME
- **Stil:** $COMM_STYLE
- **Discord:** Primär kanal

## 🛡️ Anti-Loop & Skydd
1. **2-försöksregeln:** Samma kommando max 2 gånger med samma input.
2. **Byt strategi:** Efter 3 misslyckade försök — byt metod, inte repetera.
3. **Eskalera:** Efter 5 misslyckade försök — rapportera till $USER_NAME.

## 🚫 Absoluta Regler
- **SKAPA ALDRIG kopior** av \`.openclaw\`-mappen eller dess innehåll i skills/workspace
- **SKRIV ALDRIG** API-nycklar, tokens eller lösenord i filer eller chatmeddelanden
- **RADERA ALDRIG** konfigurationsfiler utan att $USER_NAME godkänner det
- **PUSHA ALDRIG** \`.env\` eller credentials till GitHub
MDEOF

# ═══ AGENTS.md ═══
cat > "$WORKSPACE/AGENTS.md" << MDEOF
# AGENTS.md — Arbetsflöden & Regler

## 🦊 Workflow-nivåer
1. **Nivå 1 (Direkt):** Enkel fråga/fix → Svara direkt
2. **Nivå 2 (Medel):** Research, script → Ack: "✅ Kör, ~X min"
3. **Nivå 3 (Tungt):** Ny feature, arkitektur → Diskutera → Planera → Verifiera → Build

## 🛠️ Modeller & Fallbacks
| Prioritet | Modell | Typ |
|-----------|--------|-----|
| 1 (Primär) | \`ollama/qwen3.5:397b-cloud\` | Betald (Ollama Cloud) |
| 2 | \`groq/llama-3.3-70b-versatile\` | Gratis |
| 3 | \`google/gemini-2.5-flash\` | Gratis |
| 4 | \`openrouter/openrouter/free\` | Gratis |

## 📁 Filhanteringsregler (KRITISKT)
- **SKAPA ALDRIG** kopior av \`.openclaw/\` i workspace eller skills
- **SKAPA ALDRIG** filer utanför workspace utan godkännande
- **Alla projektfiler** i \`workspace/projects/<projektnamn>/\`
- **Alla scripts** i \`workspace/scripts/\`
- **Verifiera ALLTID** med \`ls\` innan du skapar ny mapstruktur

## 🧠 Memory Management
- **Dagsfiler:** \`memory/YYYY-MM-DD.md\` — ALDRIG topic-suffix
- **Max 7 filer** i \`memory/\` roten
- **Arkivera** äldre filer till \`memory/archive/\`
- **Uppdatera MEMORY.md** efter varje milstolpe

## 🛡️ Säkerhetsregler
- Installera ALDRIG skills utan att kontrollera källkoden
- Posta ALDRIG API-nycklar eller tokens i chat
- Rör ALDRIG \`.env\` eller \`openclaw.json\` utan att $USER_NAME godkänner

## ⚡ Quick Check (Varje uppgift)
- [ ] Förstått uppgiften korrekt?
- [ ] Verifierat källkoden istället för att gissa?
- [ ] Tillämpat rätt nivå (1/2/3)?
MDEOF

# ═══ USER.md ═══
cat > "$WORKSPACE/USER.md" << MDEOF
# USER.md — Om $USER_NAME

## Basics
- **Namn:** $USER_NAME
- **Pronomen:** $PRONOUNS
- **Tidszon:** Europe/Stockholm
- **Discord:** Primär kanal
- **Plats:** Sverige

## Profil
- **Syssla:** $USER_OCCUPATION
- **Vill ha hjälp med:** $USER_HELPWITH

## Hur $USER_NAME vill jobba
- $COMM_STYLE
- Fråga om du är osäker — gissa inte
- Var tålmodig och hjälpsam

## Context
- Kör OpenClaw med 1 agent ($BOT_NAME)
- Primär modell: Ollama Cloud (qwen3.5:397b-cloud)
- Kommunikation: Discord
MDEOF

# ═══ MEMORY.md ═══
cat > "$WORKSPACE/MEMORY.md" << MDEOF
# MEMORY.md — Project Map & System State

## 🎯 Aktiv Status
- **Setup:** Klar. $BOT_NAME installerad och konfigurerad.

## 🗺️ Filstruktur
\`\`\`
~/.openclaw/
├── openclaw.json          # Systemkonfig
├── .env                   # API-nycklar (ALDRIG röra utan godkännande)
└── workspace/
    ├── IDENTITY.md        # Namn, emoji
    ├── SOUL.md            # Personlighet & regler
    ├── AGENTS.md          # Arbetsflöden
    ├── USER.md            # Om $USER_NAME
    ├── MEMORY.md          # ← Du är här
    ├── TOOLS.md           # Verktyg & integrationer
    ├── HEARTBEAT.md       # Schemalagda uppgifter
    ├── BOOTSTRAP.md       # Startup-sekvens
    ├── memory/            # Dagliga loggar
    │   └── archive/       # Arkiverade loggar
    ├── projects/          # Projektfiler
    └── scripts/           # Scripts
\`\`\`

## 🛠️ Infrastruktur
- **Plattform:** Windows + WSL2 (Ubuntu)
- **Primär modell:** Ollama Cloud (qwen3.5:397b-cloud)
- **Fallbacks:** Groq → Google AI → OpenRouter

## ✍️ Underhåll
- Uppdatera denna fil efter varje milstolpe
MDEOF

# ═══ TOOLS.md ═══
cat > "$WORKSPACE/TOOLS.md" << MDEOF
# TOOLS.md — Verktyg & Integrationer

## Modeller
| Modell | Leverantör | Typ |
|--------|-----------|-----|
| qwen3.5:397b-cloud | Ollama Cloud | Betald |
| llama-3.3-70b-versatile | Groq | Gratis |
| gemini-2.5-flash | Google AI | Gratis |
| openrouter/free | OpenRouter | Gratis |

## Discord (primär kommunikation)
- $BOT_NAME svarar i Discord utan att behöva @:as
- Streaming aktiverat (svar skrivs ut live)

## Regler
- API-nycklar finns i \`~/.openclaw/.env\` — ALDRIG visa dem i chat
- Diskutera med $USER_NAME innan nya API-integrationer
MDEOF

# ═══ HEARTBEAT.md ═══
cat > "$WORKSPACE/HEARTBEAT.md" << 'MDEOF'
# HEARTBEAT.md — Schemalagda uppgifter

## 🧹 Veckovis — Memory-städning
Arkivera dagsfiler äldre än 7 dagar till `memory/archive/`

## 🔒 Regler
- **Primärkanal:** Discord
- **Dagsfil:** Logga händelser i `memory/YYYY-MM-DD.md`
MDEOF

# ═══ BOOTSTRAP.md ═══
cat > "$WORKSPACE/BOOTSTRAP.md" << MDEOF
# BOOTSTRAP.md — Session Startup

## ⚡ Startup (Tyst — ALDRIG nämn dessa steg)

### Steg 1 — Dagens kontext
Läs: \`memory/YYYY-MM-DD.md\` (idag + igår). Om filerna saknas: fortsätt.

### Steg 2 — Hälsa i kanalen
Posta en kort hälsning i Discord. Max 1-2 meningar.

## 🛡️ Regler
- Nämn ALDRIG interna steg, filnamn eller checkar
- SOUL, USER, AGENTS, TOOLS, IDENTITY, MEMORY är redan injectade — läs dem INTE igen
MDEOF

# ═══ TODO.md ═══
cat > "$WORKSPACE/TODO.md" << MDEOF
# TODO.md

## ✅ Klart
- [x] Initial setup av $BOT_NAME

## 📋 Att göra
- [ ] Lär känna $USER_NAME och anpassa
MDEOF

# ═══ .learnings ═══
cat > "$WORKSPACE/.learnings/LEARNINGS.md" << 'MDEOF'
# Learnings
*Lärdomar och korrigeringar*
MDEOF

cat > "$WORKSPACE/.learnings/ERRORS.md" << 'MDEOF'
# Errors
*Fel som inträffat och hur de löstes*
MDEOF

# ═══ Dagens memory-fil ═══
TODAY=$(date +%Y-%m-%d)
cat > "$WORKSPACE/memory/$TODAY.md" << MDEOF
# $TODAY

## Session — Setup
✅ Gjort: Initial setup av $BOT_NAME klar
📁 Ändrat: Alla workspace-filer skapade
🔑 Användare: $USER_NAME
MDEOF

echo "✅ Workspace-filer skapade"

# ═══ Uppdatera openclaw.json ═══
if command -v python3 &> /dev/null; then
    python3 << PYEOF
import json, os

path = os.path.expanduser("~/.openclaw/openclaw.json")
with open(path) as f:
    cfg = json.load(f)

# Exec utan godkännande
tools = cfg.setdefault("tools", {})
tools["exec"] = {"ask": "off"}

# Discord config
dc = cfg.get("channels", {}).get("discord", {})
dc["streaming"] = "partial"
dc.pop("respondWithoutMention", None)

# Guild — svara utan @mention
guilds = dc.setdefault("guilds", {})
guilds["$GUILD_ID"] = {"requireMention": False}

# Modeller
agents = cfg.setdefault("agents", {})
defaults = agents.setdefault("defaults", {})
model = defaults.setdefault("model", {})
model["default"] = "ollama/qwen3.5:397b-cloud"
model["fallbacks"] = [
    "groq/llama-3.3-70b-versatile",
    "google/gemini-2.5-flash",
    "openrouter/openrouter/free"
]

# Provider URLs
providers = cfg.setdefault("providers", {})
providers.setdefault("groq", {})["baseUrl"] = "https://api.groq.com/openai/v1"
providers.setdefault("google", {})["baseUrl"] = "https://generativelanguage.googleapis.com/v1beta"
providers.setdefault("openrouter", {})["baseUrl"] = "https://openrouter.ai/api/v1"

cfg["channels"]["discord"] = dc

with open(path, "w") as f:
    json.dump(cfg, f, indent=2)

print("✅ Config uppdaterad")
PYEOF
else
    echo "⚠️  python3 saknas — config ej uppdaterad. Installera python3 och kör igen."
    exit 1
fi

# ═══ Klart! ═══
echo ""
echo "═══════════════════════════════════════════════════"
echo "  $BOT_EMOJI $BOT_NAME är redo!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "  Sista steget — starta om gateway:"
echo ""
echo "    openclaw gateway restart"
echo ""
echo "  Sen skriv till $BOT_NAME i Discord!"
echo ""
echo "  Behöver du hjälp? Kontakta Filip! 💪"
echo ""
