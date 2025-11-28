#!/bin/bash

# Create config directory if it doesn't exist
mkdir -p "/root/.config/Triplo AI"

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
    "language": "${TRIPLO_LANGUAGE:-en}"
  }
}
EOF

echo "Config file generated at /root/.config/Triplo AI/config.json"
