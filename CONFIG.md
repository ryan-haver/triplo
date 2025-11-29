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

### Display & Remote Desktop Configuration (Web Version)

- `DISPLAY_WIDTH` - Virtual display width (default: `1920`)
- `DISPLAY_HEIGHT` - Virtual display height (default: `1080`)
- `ENABLE_NOVNC` - Start the container with the remote desktop stack (Fluxbox + x11vnc + noVNC). Defaults to `false` for headless deployments.
- `NOVNC_PUBLIC_URL` - Optional absolute URL (e.g., `https://remote.example.com/novnc`) that the Access tab uses for the "Open noVNC" link when you front the container with a reverse proxy. Defaults to `http://<current-host>:6080/`. The logout button is handled by the Web UI backend and does not rely on this value.

**Note:** Triplo AI will launch in fullscreen mode to match the noVNC viewport. Toggling the Remote Desktop switch inside the Web UI Access tab writes the desired state to `/root/.config/Triplo AI/platform-settings.json`; restart the container to apply whatever value you most recently saved through the UI.

### Authentication

- `WEBUI_USERNAME` / `WEBUI_PASSWORD` - HTTP Basic Auth credentials required to access the Web UI. Defaults to `triplo` / `triplo`. These values are written to `/root/.config/Triplo AI/webui-auth.json` on first run (or whenever `RESET_WEB_AUTH=true`) and can later be managed from the Web UI **Access → Authentication** panel. Stored credentials are encrypted at rest using a companion key file located at `/root/.config/Triplo AI/webui-auth.key`.
- `NOVNC_USERNAME` / `NOVNC_PASSWORD` - HTTP Basic Auth credentials for the noVNC interface. Defaults to `triplo` / `triplo` and inherits the Web UI credentials automatically when not explicitly provided. Runtime changes made through the Access tab are stored in the same `webui-auth.json` file so they persist across restarts.
- `RESET_WEB_AUTH` - Set to `true` to regenerate `webui-auth.json` from the current environment variables on startup. This will overwrite any credentials previously saved through the Web UI. Default: `false`.

### Ollama Integration

- `TRIPLO_ENABLE_OLLAMA` - Enable Ollama local LLM support (default: `false`)
- `TRIPLO_LLM_KEY` - LLM service API key
- `TRIPLO_OLLAMA_URL` - Ollama server URL (default: `http://localhost:11434`)
- `TRIPLO_OLLAMA_MODELS` - Comma-separated list of Ollama models (e.g., `llama3.1:latest,qwen3-coder:latest,deepseek-r1:latest`)

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

The `/root/.config/Triplo AI` directory now contains:

- `config.json` - All Triplo preferences managed by the Web UI.
- `webui-auth.json` - Stored Web UI/noVNC credentials (kept in sync with the Access tab and regenerated only when `RESET_WEB_AUTH=true`).
- `platform-settings.json` - Platform-level toggles that are not part of Triplo's native config, such as whether noVNC should start next boot. The Access tab writes here when you flip the Remote Desktop switch.
- `webui-auth.key` - Automatically generated key material used to encrypt/decrypt `webui-auth.json`. Treat this like a secret; anyone with the key file and the encrypted blob can recover the credentials.

Mounting this directory to a single Docker volume keeps both the Triplo application state, authentication settings, and platform toggles persistent.

## Custom Config File

You can also mount a pre-configured `config.json`:

```bash
docker run -d \
  -p 6080:6080 \
  -v /path/to/your/config.json:/root/.config/Triplo\ AI/config.json \
  ghcr.io/ryan-haver/triplo-web:latest
```
