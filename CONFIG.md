# Triplo AI Docker Configuration

## Environment Variables

You can configure Triplo AI using environment variables when running the container:

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
- `TRIPLO_TEMPERATURE` - Temperature setting (default: `0.5`)

### UI Configuration

- `TRIPLO_COLOR_SCHEME` - Color scheme (default: `auto`)
  - Options: `auto`, `light`, `dark`
- `TRIPLO_LANGUAGE` - Interface language (default: `en`)
- `TRIPLO_SKIP_WELCOME` - Skip welcome screen (default: `true`)
- `TRIPLO_SKIP_TERMS` - Skip terms screen (default: `true`)

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
