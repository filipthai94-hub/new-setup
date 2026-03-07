#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🦞 OpenClaw — Config Fix Script (baserat på MiniMilo)
# Fixar .env + openclaw.json för Alex-setup
# ═══════════════════════════════════════════════════════════════
set -e

OPENCLAW_DIR="$HOME/.openclaw"
ENV_FILE="$OPENCLAW_DIR/.env"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"

clear
echo "═══════════════════════════════════════════════════"
echo "  🦞 OpenClaw Config Fix"
echo "  Fixar din .env och openclaw.json"
echo "═══════════════════════════════════════════════════"
echo ""

# ═══ Kontroller ═══
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ openclaw.json hittades inte i $OPENCLAW_DIR"
    exit 1
fi

echo "✅ openclaw.json hittad"
echo ""

# ═══ API-nycklar ═══
echo "───────────────────────────────────────────────────"
echo "  🔑 Vi behöver dina API-nycklar"
echo "  Klistra in varje nyckel när du blir tillfrågad"
echo "───────────────────────────────────────────────────"
echo ""

read -p "🔑 Ollama API Key: " OLLAMA_KEY < /dev/tty
while [ -z "$OLLAMA_KEY" ]; do
    read -p "   Du måste ange Ollama-nyckeln: " OLLAMA_KEY < /dev/tty
done

read -p "🔑 Groq API Key (börjar med gsk_): " GROQ_KEY < /dev/tty
while [ -z "$GROQ_KEY" ]; do
    read -p "   Du måste ange Groq-nyckeln: " GROQ_KEY < /dev/tty
done

read -p "🔑 Google AI API Key (börjar med AIza): " GOOGLE_KEY < /dev/tty
while [ -z "$GOOGLE_KEY" ]; do
    read -p "   Du måste ange Google-nyckeln: " GOOGLE_KEY < /dev/tty
done

read -p "🔑 OpenRouter API Key (börjar med sk-or-v1-): " OPENROUTER_KEY < /dev/tty
while [ -z "$OPENROUTER_KEY" ]; do
    read -p "   Du måste ange OpenRouter-nyckeln: " OPENROUTER_KEY < /dev/tty
done

read -p "🔑 Mistral API Key: " MISTRAL_KEY < /dev/tty
while [ -z "$MISTRAL_KEY" ]; do
    read -p "   Du måste ange Mistral-nyckeln: " MISTRAL_KEY < /dev/tty
done

read -p "🔑 GitHub Token (börjar med ghp_): " GITHUB_KEY < /dev/tty
while [ -z "$GITHUB_KEY" ]; do
    read -p "   Du måste ange GitHub-token: " GITHUB_KEY < /dev/tty
done

# ═══ Guild ID ═══
echo ""
read -p "🔗 Discord Guild ID (server-ID): " GUILD_ID < /dev/tty
while [ -z "$GUILD_ID" ]; do
    read -p "   Du måste ange Guild ID: " GUILD_ID < /dev/tty
done

# ═══ Sammanfattning ═══
echo ""
echo "═══════════════════════════════════════════════════"
echo "  📋 Sammanfattning"
echo "═══════════════════════════════════════════════════"
echo ""
echo "  🔑 Ollama:     ${OLLAMA_KEY:0:8}..."
echo "  🔑 Groq:       ${GROQ_KEY:0:8}..."
echo "  🔑 Google:     ${GOOGLE_KEY:0:8}..."
echo "  🔑 OpenRouter: ${OPENROUTER_KEY:0:12}..."
echo "  🔑 Mistral:    ${MISTRAL_KEY:0:8}..."
echo "  🔑 GitHub:     ${GITHUB_KEY:0:8}..."
echo "  🔗 Guild ID:   $GUILD_ID"
echo ""
echo "⏳ Fixar konfiguration..."

# ═══ 1. Skriv korrekt .env ═══
cat > "$ENV_FILE" << ENVEOF
OLLAMA_API_KEY=$OLLAMA_KEY
GROQ_API_KEY=$GROQ_KEY
GOOGLE_AI_API_KEY=$GOOGLE_KEY
OPENROUTER_API_KEY=$OPENROUTER_KEY
MISTRAL_API_KEY=$MISTRAL_KEY
GITHUB_TOKEN=$GITHUB_KEY
ENVEOF

echo "✅ .env skapad med korrekt format"

# ═══ 2. Fixa openclaw.json (exakt som Milo) ═══
python3 << PYEOF
import json, os

path = os.path.expanduser('~/.openclaw/openclaw.json')
env_path = os.path.expanduser('~/.openclaw/.env')

# Läs env
env = {}
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if '=' in line and not line.startswith('#'):
            k, v = line.split('=', 1)
            env[k] = v

with open(path) as f:
    cfg = json.load(f)

# === PROVIDERS (exakt som Milo) ===
cfg.setdefault('models', {})['providers'] = {
    "ollama": {
        "baseUrl": "http://127.0.0.1:11434/v1",
        "apiKey": env.get('OLLAMA_API_KEY', ''),
        "api": "ollama",
        "models": [
            {
                "id": "qwen3.5:397b-cloud",
                "name": "Qwen 3.5 397B (Cloud)",
                "reasoning": True,
                "input": ["text", "image"],
                "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
                "contextWindow": 262144,
                "maxTokens": 262144
            }
        ]
    },
    "groq": {
        "apiKey": env.get('GROQ_API_KEY', ''),
        "models": [
            {
                "id": "llama-3.3-70b-versatile",
                "name": "Llama 3.3 70B (Groq)",
                "input": ["text"],
                "cost": {"input": 0, "output": 0},
                "contextWindow": 131072
            }
        ]
    },
    "google": {
        "apiKey": env.get('GOOGLE_AI_API_KEY', ''),
        "models": [
            {
                "id": "gemini-2.5-flash",
                "name": "Gemini 2.5 Flash",
                "input": ["text", "image"],
                "cost": {"input": 0, "output": 0},
                "contextWindow": 1048576
            }
        ]
    },
    "openrouter": {
        "apiKey": env.get('OPENROUTER_API_KEY', ''),
        "models": [
            {
                "id": "openrouter/free",
                "name": "OpenRouter Auto (Free)",
                "input": ["text"],
                "cost": {"input": 0, "output": 0},
                "contextWindow": 200000
            }
        ]
    }
}

# === MODELL-CONFIG (exakt som Milo) ===
cfg.setdefault('agents', {}).setdefault('defaults', {})['model'] = {
    "primary": "ollama/qwen3.5:397b-cloud",
    "fallbacks": [
        "groq/llama-3.3-70b-versatile",
        "google/gemini-2.5-flash",
        "openrouter/openrouter/free"
    ]
}

# === MODELL-REGISTER ===
cfg['agents']['defaults']['models'] = {
    "ollama/qwen3.5:397b-cloud": {},
    "groq/llama-3.3-70b-versatile": {},
    "google/gemini-2.5-flash": {},
    "openrouter/openrouter/free": {}
}

# === EXEC utan godkännande ===
cfg.setdefault('tools', {})['exec'] = {"ask": "off"}

# === DISCORD CONFIG ===
dc = cfg.get('channels', {}).get('discord', {})
dc['streaming'] = 'partial'
dc.pop('respondWithoutMention', None)

# Ta bort ogiltiga nycklar som kan ha lagts till
cfg.pop('providers', None)

# Guild config
guilds = dc.setdefault('guilds', {})
guilds['$GUILD_ID'] = {"requireMention": False}

cfg['channels']['discord'] = dc

with open(path, 'w') as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)

print("✅ openclaw.json uppdaterad (Milo-standard)")

# Validera
print("")
print("📋 Providers:")
for p, pcfg in cfg['models']['providers'].items():
    has_key = bool(pcfg.get('apiKey'))
    models_list = [m['id'] for m in pcfg.get('models', [])]
    print(f"  {p}: {'🔑' if has_key else '❌'} | {', '.join(models_list)}")

m = cfg['agents']['defaults']['model']
print(f"\n🔗 Modell-kedja:")
print(f"  1. {m['primary']} (primär)")
for i, fb in enumerate(m['fallbacks']):
    print(f"  {i+2}. {fb} (fallback)")

print(f"\n🎮 Discord:")
print(f"  Streaming: {dc.get('streaming')}")
print(f"  Exec ask: {cfg['tools']['exec']['ask']}")
for gid, gcfg in dc.get('guilds', {}).items():
    print(f"  Guild {gid}: requireMention={gcfg.get('requireMention')}")
PYEOF

# ═══ 3. Validera config ═══
echo ""
echo "⏳ Validerar config..."
openclaw config validate

# ═══ 4. Starta om gateway ═══
echo ""
echo "⏳ Startar om gateway..."
openclaw gateway restart

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ Allt fixat!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "  Testa nu — skriv till din bot i Discord!"
echo ""
