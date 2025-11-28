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
    "enable_openai_key": true,
    "enable_openrouter_key": true,
    "enable_anthropic_key": true,
    "enable_normal_prompts": true,
    "openai_model": "${TRIPLO_OPENAI_MODEL:-gpt-4o-mini}",
    "temperature": ${TRIPLO_TEMPERATURE:-0.5},
    "presence_penalty": 0,
    "custom_trigger": "",
    "shift_backspace": true,
    "custom_hotkey": "Ctrl+Space",
    "indicator": "idle",
    "run_at_startup": true,
    "inline_scrape": true,
    "confirm_delete": true,
    "aware_mode": true,
    "sound": true,
    "voice": true,
    "voice_tts_speed": 1,
    "voice_tts_autoplay": true,
    "voice_tts_voice": "echo",
    "voice_tts_model": "tts-1",
    "voice_stt_lang": "en",
    "window_width": "md",
    "page_height": "md",
    "main_height": "md",
    "pinned": true,
    "copy_results": true,
    "enabled": true,
    "auto_scroll": true,
    "color_scheme": "${TRIPLO_COLOR_SCHEME:-auto}",
    "confirm_automations": true,
    "yt_lang": "en",
    "prompt_lang": "",
    "language": "${TRIPLO_LANGUAGE:-en}"
  }
}
EOF

echo "Config file generated at /root/.config/Triplo AI/config.json"
