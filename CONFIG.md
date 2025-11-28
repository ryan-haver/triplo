# Triplo AI Docker Configuration

## Environment Variables

You can configure Triplo AI using environment variables when running the container:

### Licensing

- `TRIPLO_LICENSE_KEY` - Your Triplo AI license key

### API Keys

```bash
docker run -d \
  -e OPENAI_API_KEY="sk-..." \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  -e OPENROUTER_API_KEY="sk-or-..." \
  -p 6080:6080 \
  ghcr.io/ryan-haver/triplo-web:latest
```

### AI Configuration

- `TRIPLO_AI_SOURCE` - AI provider (default: `open_ai`)
  - Options: `open_ai`, `open_router`, `anthropic`
- `TRIPLO_OPENAI_MODEL` - OpenAI model (default: `gpt-4o-mini`)
- `TRIPLO_TEMPERATURE` - Temperature setting 0-1 (default: `0.5`)
- `TRIPLO_PRESENCE_PENALTY` - Presence penalty (default: `0`)
- `TRIPLO_ENABLE_OPENAI` - Enable OpenAI (default: `true`)
- `TRIPLO_ENABLE_OPENROUTER` - Enable OpenRouter (default: `true`)
- `TRIPLO_ENABLE_ANTHROPIC` - Enable Anthropic (default: `true`)
- `TRIPLO_ENABLE_NORMAL_PROMPTS` - Enable general smart prompts (default: `true`)

### Customization

- `TRIPLO_COLOR_SCHEME` - Color scheme (default: `auto`)
  - Options: `auto`, `light`, `dark`, `system`
- `TRIPLO_LANGUAGE` - Interface language (default: `en`)
- `TRIPLO_YOUTUBE_LANG` - YouTube scrape language (default: `en`)
- `TRIPLO_CUSTOM_HOTKEY` - Custom hotkey (default: `Ctrl+Space`)
- `TRIPLO_CUSTOM_TRIGGER` - Custom 000 trigger text (default: empty)
- `TRIPLO_WINDOW_WIDTH` - Window width (default: `md`)
  - Options: `sm`, `md`, `lg`, `xl`
- `TRIPLO_PAGE_HEIGHT` - Page height (default: `md`)
- `TRIPLO_MAIN_HEIGHT` - Main height (default: `md`)

### Preferences (Boolean Options)

All boolean values: `true` or `false`

**Behavior:**
- `TRIPLO_INLINE_SCRAPING` - Inline scraping (default: `true`)
- `TRIPLO_AUTO_SCROLL` - Auto scroll (default: `true`)
- `TRIPLO_AWARENESS_MODE` - Awareness mode (default: `true`)
- `TRIPLO_CONFIRM_AUTOMATIONS` - Confirm automations (default: `true`)
- `TRIPLO_CONFIRM_DELETE` - Confirm delete (default: `true`)
- `TRIPLO_RUN_AT_STARTUP` - Run at startup (default: `true`)
- `TRIPLO_ENABLED` - Enable Triplo (default: `true`)
- `TRIPLO_PINNED` - Pin window (default: `true`)

**Audio & Voice:**
- `TRIPLO_NOTIFICATION_SOUNDS` - Notification sounds (default: `true`)
- `TRIPLO_VOICE_FEATURES` - Voice features (default: `true`)
- `TRIPLO_VOICE_TTS_SPEED` - TTS speed (default: `1`)
- `TRIPLO_VOICE_TTS_AUTOPLAY` - TTS autoplay (default: `true`)
- `TRIPLO_VOICE_TTS_VOICE` - TTS voice (default: `echo`)
- `TRIPLO_VOICE_TTS_MODEL` - TTS model (default: `tts-1`)
- `TRIPLO_VOICE_STT_LANG` - STT language (default: `en`)

**Clipboard:**
- `TRIPLO_COPY_TO_CLIPBOARD` - Copy responses to clipboard (default: `true`)

**Other:**
- `TRIPLO_SKIP_WELCOME` - Skip welcome screen (default: `true`)
- `TRIPLO_SKIP_TERMS` - Skip terms screen (default: `true`)
- `TRIPLO_SHIFT_BACKSPACE` - Enable Shift+Backspace shortcut (default: `true`)
- `TRIPLO_INDICATOR` - Status indicator (default: `idle`)
  - Options: `idle`, `hide_on_idle`
- `TRIPLO_PROMPT_LANG` - Prompt language override (default: empty)

### Display Configuration (Web Version)

- `DISPLAY_WIDTH` - Virtual display width (default: `1920`)
- `DISPLAY_HEIGHT` - Virtual display height (default: `1080`)

**Note:** Triplo AI will launch in fullscreen mode to match the noVNC viewport.

### License

- `TRIPLO_LICENSE_KEY` - Your Triplo AI license key

## Example: Complete Configuration

```bash
docker run -d \
  --name triplo-web \
  -p 6080:6080 \
  -e OPENAI_API_KEY="sk-proj-..." \
  -e TRIPLO_AI_SOURCE="open_ai" \
  -e TRIPLO_OPENAI_MODEL="gpt-4o" \
  -e TRIPLO_TEMPERATURE="0.7" \
  -e TRIPLO_COLOR_SCHEME="dark" \
  -e TRIPLO_LICENSE_KEY="your-license-key" \
  -e TRIPLO_INLINE_SCRAPING="true" \
  -e TRIPLO_AUTO_SCROLL="true" \
  -e TRIPLO_AWARENESS_MODE="true" \
  -e TRIPLO_NOTIFICATION_SOUNDS="true" \
  -e TRIPLO_COPY_TO_CLIPBOARD="true" \
  -e TRIPLO_CONFIRM_AUTOMATIONS="true" \
  -e DISPLAY_WIDTH="1920" \
  -e DISPLAY_HEIGHT="1080" \
  -v triplo-data:/root/.config/Triplo\ AI \
  ghcr.io/ryan-haver/triplo-web:latest
```

## Docker Compose Example

```yaml
version: '3.8'

services:
  triplo-web:
    image: ghcr.io/ryan-haver/triplo-web:latest
    container_name: triplo-ai-web
    restart: unless-stopped
    ports:
      - "6080:6080"
    environment:
      - OPENAI_API_KEY=sk-proj-...
      - TRIPLO_AI_SOURCE=open_ai
      - TRIPLO_OPENAI_MODEL=gpt-4o-mini
      - TRIPLO_TEMPERATURE=0.5
      - TRIPLO_COLOR_SCHEME=dark
      - TRIPLO_SKIP_WELCOME=true
      - TRIPLO_SKIP_TERMS=true
    volumes:
      - triplo-data:/root/.config/Triplo AI

volumes:
  triplo-data:
```

## Persistent Storage

Mount a volume to persist your settings, chats, and data:

```bash
docker run -d \
  -p 6080:6080 \
  -v triplo-data:/root/.config/Triplo\ AI \
  ghcr.io/ryan-haver/triplo-web:latest
```

## Custom Config File

You can also mount a pre-configured `config.json`:

```bash
docker run -d \
  -p 6080:6080 \
  -v /path/to/your/config.json:/root/.config/Triplo\ AI/config.json \
  ghcr.io/ryan-haver/triplo-web:latest
```
