#!/bin/bash

# Create config directory if it doesn't exist
mkdir -p "/root/.config/Triplo AI"

generate_llm_key() {
  local chars="abcdefghijklmnopqrstuvwxyz0123456789"
  local segment
  local parts=()
  for _ in 1 2 3 4; do
    segment=$(tr -dc "$chars" </dev/urandom | head -c4)
    if [ -z "$segment" ]; then
      segment=$(printf "%04x" $((RANDOM * RANDOM)) | cut -c1-4)
    fi
    parts+=("$segment")
  done
  (IFS=-; echo "${parts[*]}")
}

if [ -z "$TRIPLO_LLM_KEY" ]; then
  TRIPLO_LLM_KEY=$(generate_llm_key)
fi

# Parse OLLAMA_MODELS env var (comma-separated) into JSON array
OLLAMA_MODELS_JSON="[]"
if [ -n "$TRIPLO_OLLAMA_MODELS" ]; then
  # Convert comma-separated list to JSON array
  OLLAMA_MODELS_JSON=$(echo "$TRIPLO_OLLAMA_MODELS" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')
fi

# Parse TRIPLO_CUSTOM_SP_HOTKEYS env var (comma-separated) into JSON array
CUSTOM_SP_HOTKEYS_JSON="[]"
if [ -n "$TRIPLO_CUSTOM_SP_HOTKEYS" ]; then
  CUSTOM_SP_HOTKEYS_JSON=$(echo "$TRIPLO_CUSTOM_SP_HOTKEYS" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')
fi

# Generate config.json with environment variable substitution
cat > "/root/.config/Triplo AI/config.json" << EOF
{
  "version": "5.4.0",
  "locale": "en-US@posix",
  "indicatorPosition": {
    "x": 2,
    "y": 2
  },
  "seenWelcome": ${TRIPLO_SKIP_WELCOME:-true},
  "seenTerms": ${TRIPLO_SKIP_TERMS:-true},
  "settings": {
    "license_key": "${TRIPLO_LICENSE_KEY:-}",
    "ai_source": "${TRIPLO_AI_SOURCE:-open_ai}",
    "openai_key": "${OPENAI_API_KEY:-}",
    "openrouter_key": "${OPENROUTER_API_KEY:-}",
    "anthropic_key": "${ANTHROPIC_API_KEY:-}",
    "enable_openai_key": ${TRIPLO_ENABLE_OPENAI:-true},
    "enable_openrouter_key": ${TRIPLO_ENABLE_OPENROUTER:-true},
    "enable_anthropic_key": ${TRIPLO_ENABLE_ANTHROPIC:-true},
    "enable_normal_prompts": ${TRIPLO_ENABLE_NORMAL_PROMPTS:-true},
    "openai_model": "${TRIPLO_OPENAI_MODEL:-gpt-4o-mini}",
    "temperature": ${TRIPLO_TEMPERATURE:-0.5},
    "presence_penalty": ${TRIPLO_PRESENCE_PENALTY:-0},
    "custom_trigger": "${TRIPLO_CUSTOM_TRIGGER:-}",
    "shift_backspace": ${TRIPLO_SHIFT_BACKSPACE:-true},
    "custom_hotkey": "${TRIPLO_CUSTOM_HOTKEY:-Ctrl+Space}",
    "indicator": "${TRIPLO_INDICATOR:-idle}",
    "run_at_startup": ${TRIPLO_RUN_AT_STARTUP:-true},
    "inline_scrape": ${TRIPLO_INLINE_SCRAPING:-true},
    "confirm_delete": ${TRIPLO_CONFIRM_DELETE:-true},
    "aware_mode": ${TRIPLO_AWARENESS_MODE:-true},
    "sound": ${TRIPLO_NOTIFICATION_SOUNDS:-true},
    "voice": ${TRIPLO_VOICE_FEATURES:-true},
    "voice_tts_speed": ${TRIPLO_VOICE_TTS_SPEED:-1},
    "voice_tts_autoplay": ${TRIPLO_VOICE_TTS_AUTOPLAY:-true},
    "voice_tts_voice": "${TRIPLO_VOICE_TTS_VOICE:-echo}",
    "voice_tts_model": "${TRIPLO_VOICE_TTS_MODEL:-tts-1}",
    "voice_stt_lang": "${TRIPLO_VOICE_STT_LANG:-en}",
    "window_width": "${TRIPLO_WINDOW_WIDTH:-md}",
    "page_height": "${TRIPLO_PAGE_HEIGHT:-md}",
    "main_height": "${TRIPLO_MAIN_HEIGHT:-md}",
    "pinned": ${TRIPLO_PINNED:-true},
    "copy_results": ${TRIPLO_COPY_TO_CLIPBOARD:-true},
    "enabled": ${TRIPLO_ENABLED:-true},
    "auto_scroll": ${TRIPLO_AUTO_SCROLL:-true},
    "color_scheme": "${TRIPLO_COLOR_SCHEME:-auto}",
    "confirm_automations": ${TRIPLO_CONFIRM_AUTOMATIONS:-true},
    "yt_lang": "${TRIPLO_YOUTUBE_LANG:-en}",
    "prompt_lang": "${TRIPLO_PROMPT_LANG:-}",
    "language": "${TRIPLO_LANGUAGE:-en}",
    "enable_ollama": ${TRIPLO_ENABLE_OLLAMA:-false},
    "sync_local_llm": ${TRIPLO_SYNC_LOCAL_LLM:-false},
    "llm_key": "${TRIPLO_LLM_KEY}",
    "ollama_url": "${TRIPLO_OLLAMA_URL:-http://localhost:11434}",
    "ollama_models": ${OLLAMA_MODELS_JSON},
    "custom_sp_hotkeys": ${CUSTOM_SP_HOTKEYS_JSON}
  }
}
EOF

echo "Config file generated at /root/.config/Triplo AI/config.json"
