# Triplo AI Unified Docker Container

**One container, two modes:** Headless automation OR full web interface with noVNC + configuration UI.

## 🎯 Features

- **🖥️ Dual Mode Operation**
  - **Headless Mode**: Lightweight, API/automation-focused
  - **Web Mode**: Full noVNC remote desktop + configuration UI

- **🎛️ Web Configuration UI**
  - Beautiful, modern interface for all Triplo settings
  - Real-time configuration updates
  - No need to rebuild containers or edit env files
  - Restart Triplo directly from the UI

- **🚀 Easy Deployment**
  - Single unified Docker image
  - Switch modes via `ENABLE_NOVNC` environment variable
  - All settings (including Remote Desktop enable/disable) configurable through the Web UI
  - Persistent configuration with Docker volumes

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Unified Container                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Port 8080: Web Configuration UI                   │
│  ├─ Manage all Triplo settings                     │
│  ├─ Real-time updates                              │
│  └─ Restart Triplo without container restart       │
│                                                     │
│  Port 6080: noVNC (when ENABLE_NOVNC=true)         │
│  ├─ Remote desktop access                          │
│  ├─ Fullscreen Triplo interface                    │
│  └─ Direct app interaction                         │
│                                                     │
│  Backend: Triplo AI + Supervisord                  │
│  ├─ Xvfb (virtual display)                         │
│  ├─ Triplo AI application                          │
│  └─ Optional: Fluxbox + x11vnc + noVNC             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Headless Mode (Web UI Only)

```bash
docker run -d \
  --name triplo \
  -p 8080:8080 \
  -e ENABLE_NOVNC=false \
  -e OPENAI_API_KEY="sk-proj-..." \
  -v triplo-data:/root/.config/Triplo\ AI \
  ghcr.io/ryan-haver/triplo-unified:latest
```

**Access:** http://localhost:8080

### Web Mode (noVNC + Web UI)

```bash
docker run -d \
  --name triplo \
  -p 8080:8080 \
  -p 6080:6080 \
  -e ENABLE_NOVNC=true \
  -e OPENAI_API_KEY="sk-proj-..." \
  -v triplo-data:/root/.config/Triplo\ AI \
  ghcr.io/ryan-haver/triplo-unified:latest
```

**Access:**
- Configuration UI: http://localhost:8080
- noVNC Interface: http://localhost:6080

## 🎛️ Using the Web Configuration UI

1. **Open the UI**: Navigate to `http://localhost:8080`

2. **Configure Settings**: Use the tabbed interface:
   - **API & Models**: AI provider, API keys, model selection
   - **Preferences**: Features, keyboard shortcuts, behaviors
   - **Voice & Audio**: TTS/STT configuration
   - **Display & UI**: Appearance, window size, languages
   - **Ollama**: Local LLM integration
  - **Access**: noVNC status, Remote Desktop toggle persistence, authentication controls, and restart actions

3. **Save Changes**: Click "Save Configuration"
   - Configuration is written to `config.json`
   - Triplo AI automatically restarts
   - Changes persist across container restarts

4. **Manual Restart**: Use "Restart Triplo AI" button in Access tab

## 🐳 Docker Compose

### Both Modes (Recommended)

```yaml
version: '3.8'

services:
  # Headless instance
  triplo-headless:
    image: ghcr.io/ryan-haver/triplo-unified:latest
    container_name: triplo-headless
    environment:
      - ENABLE_NOVNC=false
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    ports:
      - "8080:8080"
    volumes:
      - triplo-headless-data:/root/.config/Triplo AI
    restart: unless-stopped

  # Web instance with noVNC
  triplo-web:
    image: ghcr.io/ryan-haver/triplo-unified:latest
    container_name: triplo-web
    environment:
      - ENABLE_NOVNC=true
      - DISPLAY_WIDTH=1920
      - DISPLAY_HEIGHT=1080
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    ports:
      - "8081:8080"  # Web UI
      - "6080:6080"  # noVNC
    volumes:
      - triplo-web-data:/root/.config/Triplo AI
    restart: unless-stopped

volumes:
  triplo-headless-data:
  triplo-web-data:
```

## ⚙️ Initial Environment Variables

While the Web UI allows you to configure most settings, some initial setup can be done via environment variables:

### Core Configuration
- `ENABLE_NOVNC` - Enable noVNC remote desktop (`true`/`false`, default: `false`)
- `DISPLAY_WIDTH` - Virtual display width (default: `1920`)
- `DISPLAY_HEIGHT` - Virtual display height (default: `1080`)

### Quick Setup (Optional)
- `OPENAI_API_KEY` - Your OpenAI API key
- `OPENROUTER_API_KEY` - Your OpenRouter API key
- `ANTHROPIC_API_KEY` - Your Anthropic API key
- `TRIPLO_LICENSE_KEY` - Your Triplo license key
- `TRIPLO_AI_SOURCE` - AI provider (`open_ai`, `openrouter`, `anthropic`, `ollama`)

**Note:** All of these can be configured through the Web UI after container start. Environment variables are only for initial setup convenience.

## 🔄 Configuration Management

### How It Works

1. **Container Start**:

    - `init-config.sh` generates initial `config.json` from env vars (if provided)
    - Web UI server starts on port 8080
    - Triplo AI starts with configuration
    - Remote Desktop preference is loaded from `/root/.config/Triplo AI/platform-settings.json` (falling back to the `ENABLE_NOVNC` env var the first time)

1. **Web UI Updates**:

    - User modifies settings in Web UI
    - Click "Save" → writes to `config.json`
    - Access tab actions also write to supporting files (authentication → `/root/.config/Triplo AI/webui-auth.json`, Remote Desktop toggle → `/root/.config/Triplo AI/platform-settings.json`). Authentication data is encrypted at rest; the companion key lives alongside the config volume (see below).
    - Backend automatically restarts Triplo AI
    - New settings take effect immediately

1. **Persistence**:

    - Configuration stored in `/root/.config/Triplo AI/config.json`
    - Web/noVNC credentials stored in `/root/.config/Triplo AI/webui-auth.json`
    - Encryption key for those credentials stored in `/root/.config/Triplo AI/webui-auth.key`; keep it with your volume backups because both files are required to decrypt
    - Remote Desktop toggle stored in `/root/.config/Triplo AI/platform-settings.json`
    - Mounted as Docker volume → survives container restarts
    - No need to set env vars again

### Encrypted Credentials

- The first container start generates `/root/.config/Triplo AI/webui-auth.key`, a 32-byte secret used to encrypt `/root/.config/Triplo AI/webui-auth.json`.
- Deleting either file breaks the pairing; remove both (or set `RESET_WEB_AUTH=true`) if you want the container to regenerate fresh credentials from env vars.
- Back up the key file with the rest of the config volume—losing it means you cannot recover the stored passwords, while leaking it lets anyone decrypt them.

### Remote Desktop Shortcuts

- The Access tab's Remote Desktop card exposes quick "Open noVNC" and "Log out of noVNC" controls so you can launch or revoke browser sessions without memorizing the port. The logout button now talks to the Web UI backend, which rotates the noVNC auth realm and restarts the VNC stack so browsers lose their cached session without interrupting the Web UI tab.
- When Triplo sits behind a reverse proxy, set `NOVNC_PUBLIC_URL` to the externally reachable noVNC URL so the "Open" link uses the right host/port. The logout workflow no longer depends on this value.

### Configuration Priority

1. **Web UI** (highest priority) - Settings saved through Web UI
2. **config.json** - Existing configuration file
3. **Environment variables** (lowest priority) - Initial setup only

## 📊 Comparison: Old vs New Approach

| Feature | Old (Separate Containers) | New (Unified + Web UI) |
|---------|--------------------------|------------------------|
| Container Images | 2 separate images | 1 unified image |
| Configuration | Environment variables | Web UI + env vars |
| Settings Changes | Rebuild/restart container | Live update via Web UI |
| Mode Switching | Different Dockerfile | One env var |
| Ease of Use | Medium | Very Easy |
| Disk Space | ~2x image size | 1x image size |

## 🎨 Web UI Screenshots

### Configuration Interface

- Clean, modern design
- Tabbed organization
- Real-time status indicators
- Responsive layout

### Features

- ✅ All 40+ Triplo settings accessible
- ✅ Grouped by category (API, Preferences, Voice, Display, Ollama)
- ✅ Live status monitoring
- ✅ One-click Triplo restart
- ✅ noVNC integration indicator

## 🔧 Development

### Build Locally

```bash
# Build the unified image
docker build -f Dockerfile.unified -t triplo-unified:local .

# Run in headless mode
docker run -d -p 8080:8080 \
  -e ENABLE_NOVNC=false \
  triplo-unified:local

# Run in web mode
docker run -d -p 8080:8080 -p 6080:6080 \
  -e ENABLE_NOVNC=true \
  triplo-unified:local
```

### Docker Compose (Local Build)

```bash
# Start both modes
docker-compose -f docker-compose.unified.local.yml up -d

# Stop
docker-compose -f docker-compose.unified.local.yml down
```

## 🐛 Troubleshooting

### Web UI not accessible

```bash
# Check if container is running
docker ps | grep triplo

# Check Web UI logs
docker logs triplo | grep webui

# Check port mapping
docker port triplo
```

### Configuration not saving

```bash
# Check volume mount
docker inspect triplo | grep Mounts -A 10

# Check config file permissions
docker exec triplo ls -la /root/.config/Triplo\ AI/
```

### Triplo not restarting after config save

```bash
# Check Triplo process
docker exec triplo ps aux | grep triplo.ai

# Manual restart
docker exec triplo supervisorctl restart triplo

# Check logs
docker exec triplo tail -f /var/log/supervisor/triplo.log
```

### noVNC not working (when ENABLE_NOVNC=true)

```bash
# Check all services
docker exec triplo supervisorctl status

# Restart VNC stack
docker exec triplo supervisorctl restart x11vnc novnc nginx
```

## 🎯 Use Cases

### 1. Development/Testing (Web Mode)

- Use noVNC to interact with Triplo visually
- Use Web UI to quickly test different settings
- Iterate on prompts and configurations

### 2. Production/Automation (Headless Mode)

- Lightweight deployment
- API/CLI automation
- Use Web UI for occasional maintenance

### 3. Personal Use (Web Mode)

- Full desktop experience via browser
- Easy configuration management
- No local installation needed

## 📝 Migration from Old Containers

### From `triplo-headless` or `triplo-web`

1. **Export your config** (if you want to keep it):

```bash
docker cp triplo-headless:/root/.config/Triplo\ AI/config.json ./backup-config.json
```
 
1. **Stop old container**:

```bash
docker stop triplo-headless
docker rm triplo-headless
```

1. **Start unified container**:

```bash
docker run -d \
  --name triplo \
  -p 8080:8080 \
  -e ENABLE_NOVNC=false \
  -v triplo-data:/root/.config/Triplo\ AI \
  ghcr.io/ryan-haver/triplo-unified:latest
```

1. **Restore config** (optional):

```bash
docker cp ./backup-config.json triplo:/root/.config/Triplo\ AI/config.json
docker restart triplo
```

1. **Or configure via Web UI**:

    - Open <http://localhost:8080>
    - Set all your preferences
    - Click Save

## 🌟 Benefits

1. **Simplified Management**: One image, one container
2. **User-Friendly**: No more env var editing or container rebuilds
3. **Flexible**: Switch between headless and web modes easily
4. **Powerful**: All configuration options accessible
5. **Modern**: Beautiful web interface for settings management

## 📚 Additional Resources

- [Full Environment Variables Reference](CONFIG.md)
- [GitHub Repository](https://github.com/ryan-haver/triplo)
- [Triplo AI Official Site](https://triplo.ai)

## 🤝 Contributing

Issues and PRs welcome! This is a community-maintained Docker implementation.

## 📄 License

This Docker implementation is provided as-is. Triplo AI is property of Elbruz Technologies.
