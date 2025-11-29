# Triplo AI Docker - Implementation Comparison

## 📊 Architecture Evolution

### Previous: Separate Containers

```text
┌─────────────────────┐     ┌──────────────────────────┐
│  triplo-headless    │     │     triplo-web           │
│  (Dockerfile.headless)   │     │  (Dockerfile.web)        │
├─────────────────────┤     ├──────────────────────────┤
│ - Xvfb :99          │     │ - Xvfb :1                │
│ - Triplo AI         │     │ - Fluxbox                │
│ - ENV VARS only     │     │ - x11vnc                 │
│                     │     │ - noVNC                  │
│                     │     │ - nginx (port 6080)      │
│                     │     │ - Triplo AI              │
│                     │     │ - ENV VARS only          │
└─────────────────────┘     └──────────────────────────┘
```

### New: Unified Container with Web UI

```text
┌──────────────────────────────────────────────────────┐
│         triplo-unified (Dockerfile.unified)          │
│                  ENABLE_NOVNC=false/true             │
├──────────────────────────────────────────────────────┤
│                                                      │
│  🌐 Web UI (Port 8080) - Always Available           │
│  ├─ Flask REST API                                  │
│  ├─ Beautiful settings interface                    │
│  ├─ Real-time config updates                        │
│  └─ No container restart needed                     │
│                                                      │
│  🖥️ Optional noVNC (Port 6080)                      │
│  ├─ Enabled with ENABLE_NOVNC=true                  │
│  ├─ Full desktop access                             │
│  └─ Fluxbox + x11vnc + noVNC + nginx                │
│                                                      │
│  🚀 Triplo AI Backend                                │
│  ├─ Xvfb virtual display                            │
│  ├─ Dynamically configured                          │
│  └─ Auto-restart on config save                     │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## 🎯 Feature Comparison

| Feature | Old Approach | New Unified Approach |
| ------- | ------------ | ------------------- |
| **Container Images** | 2 separate images | 1 unified image |
| **Configuration Method** | Environment variables only | Web UI + Environment variables |
| **Settings Changes** | Rebuild/restart container | Live update via Web UI |
| **User Interface** | None (headless) or noVNC only | Web UI + optional noVNC |
| **Mode Switching** | Different Dockerfiles | One environment variable |
| **Ease of Use** | Medium (terminal/env files) | Very Easy (web interface) |
| **Disk Space** | ~2x image size | 1x image size |
| **Maintenance** | Manage 2 images | Manage 1 image |
| **Learning Curve** | Moderate | Low |
| **Configuration Visibility** | Hidden in env vars | Visible in Web UI |
| **API Management** | Manual env var editing | Form-based UI |
| **Restart Required** | Yes (for any config change) | No (only Triplo restarts) |

## 🚀 Usage Comparison

### Old: Headless Container

```bash
docker run -d \
  --name triplo-headless \
  -e TRIPLO_LICENSE_KEY="..." \
  -e OPENAI_API_KEY="..." \
  -e TRIPLO_AI_SOURCE="open_ai" \
  -e TRIPLO_OPENAI_MODEL="gpt-4o-mini" \
  -e TRIPLO_TEMPERATURE="0.7" \
  -e TRIPLO_COLOR_SCHEME="dark" \
  -e TRIPLO_AUTO_SCROLL="true" \
  -e TRIPLO_COPY_TO_CLIPBOARD="true" \
  # ... 40+ more env vars ...
  ghcr.io/ryan-haver/triplo-headless:latest
```

**To change settings:** Edit env vars → Restart container

### New: Unified Container (Headless Mode)

```bash
docker run -d \
  --name triplo \
  -p 8080:8080 \
  -e ENABLE_NOVNC=false \
  -e OPENAI_API_KEY="..." \
  ghcr.io/ryan-haver/triplo-unified:latest
```

**To change settings:** Open <http://localhost:8080> → Configure → Save

---

### Old: Web Container with noVNC

```bash
docker run -d \
  --name triplo-web \
  -p 6080:6080 \
  -e TRIPLO_LICENSE_KEY="..." \
  -e OPENAI_API_KEY="..." \
  -e TRIPLO_AI_SOURCE="open_ai" \
  -e DISPLAY_WIDTH="1920" \
  -e DISPLAY_HEIGHT="1080" \
  # ... 40+ more env vars ...
  ghcr.io/ryan-haver/triplo-web:latest
```

**Access:** <http://localhost:6080> (noVNC only)

### New: Unified Container (Web Mode)

```bash
docker run -d \
  --name triplo \
  -p 8080:8080 \
  -p 6080:6080 \
  -e ENABLE_NOVNC=true \
  -e OPENAI_API_KEY="..." \
  ghcr.io/ryan-haver/triplo-unified:latest
```

**Access:**

- Configuration UI: <http://localhost:8080>
- noVNC: <http://localhost:6080>

## 💡 Configuration Management

### Old Approach: Environment Variables

**Pros:**

- Infrastructure as Code (IaC) friendly
- Version controllable
- Good for CI/CD

**Cons:**

- Must know all 40+ variable names
- Typos lead to broken configs
- No validation until runtime
- Requires container restart for changes
- Not user-friendly
- No visual feedback

**Pros:**

- **User-friendly web interface**
- **Visual feedback and validation**
- **Organized by category (API, Voice, Display, etc.)**
- **Real-time updates without container restart**
- **Still supports env vars for initial setup**
- **Help text and descriptions**
- **Dropdown selections for valid options**
- **Status indicators**
- **One-click Triplo restart**

**Cons:**

- Adds ~50MB to image size (Python + Flask)
- Extra port to expose (8080)

## 🎨 Web UI Features

### Configuration Interface

- **Clean, modern design** with gradient theme
- **Tabbed organization**: API & Models, Preferences, Voice, Display, Ollama, Access
- **Real-time status**: Shows if Triplo is running
- **Live updates**: Changes apply without container restart
- **Help text**: Explanations for complex settings
- **Responsive**: Works on desktop and mobile

### API Endpoints

```text
GET  /api/config     - Retrieve current configuration
POST /api/config     - Update configuration and restart Triplo
GET  /api/status     - Get Triplo and noVNC status
POST /api/restart    - Manually restart Triplo
```

### Settings Categories

1. **API & Models**: Provider selection, API keys, model config
2. **Preferences**: Features, keyboard shortcuts, behaviors
3. **Voice & Audio**: TTS/STT settings, voice configuration
4. **Display & UI**: Color scheme, window dimensions, languages
5. **Ollama**: Local LLM integration setup
6. **Access**: noVNC status, manual Triplo restart

## 📈 Benefits of Unified Approach

### For End Users

1. ✅ **Much easier to configure** - Visual forms vs. 40+ env vars
2. ✅ **Instant feedback** - See changes immediately
3. ✅ **No technical knowledge needed** - Point and click
4. ✅ **Flexible deployment** - One container, two modes

### For Developers

1. ✅ **Easier maintenance** - One image to update
2. ✅ **Simpler CI/CD** - One build pipeline
3. ✅ **Better testing** - Consistent environment

### For DevOps

1. ✅ **Reduced complexity** - One image to manage
2. ✅ **Smaller footprint** - ~50% reduction in image storage
3. ✅ **Dynamic configuration** - No rebuilds needed
4. ✅ **Still IaC compatible** - Initial setup via env vars

## 🔄 Migration Path

### From Old to New

1. **Export existing config** (optional):

```bash
docker cp triplo-headless:/root/.config/Triplo\ AI/config.json ./backup.json
```

1. **Stop old container**:

```bash
docker stop triplo-headless && docker rm triplo-headless
```

1. **Start unified container**:

```bash
docker run -d \
  --name triplo \
  -p 8080:8080 \
  -e ENABLE_NOVNC=false \
  ghcr.io/ryan-haver/triplo-unified:latest
```

1. **Configure via Web UI**:

  Open <http://localhost:8080>, set all preferences, then click Save.

**Time savings:** ~5 minutes vs. 30+ minutes editing env vars

## 🎯 Recommendations

### When to Use Old Approach

- Legacy systems with existing automation
- Pure headless automation (no human interaction)
- Extremely resource-constrained environments

### When to Use New Unified Approach (Recommended)

- ✅ **New deployments** - Start with the best experience
- ✅ **Production systems** - Easier maintenance and updates
- ✅ **Personal use** - Much more convenient
- ✅ **Team environments** - Non-technical users can manage
- ✅ **Development/Testing** - Quick configuration iteration

## 📊 Resource Usage

| Metric | Old Headless | Old Web | New Unified (Headless) | New Unified (Web) |
| ------ | ------------ | ------- | ---------------------- | ------------------ |
| Image Size | ~800MB | ~950MB | ~900MB | ~900MB |
| RAM Usage | ~300MB | ~500MB | ~350MB | ~550MB |
| Ports | 0 | 1 (6080) | 1 (8080) | 2 (8080, 6080) |
| Processes | 2 | 6 | 3 | 7 |
| Config Method | Env vars | Env vars | Web UI + Env | Web UI + Env |

## 🎉 Summary

The **unified container with Web UI** is the recommended approach for new deployments:

- 🚀 **Easier to use** - Web interface beats env vars
- 🔧 **Easier to maintain** - One image, dynamic config
- 💪 **More powerful** - All features accessible
- 🎨 **Better UX** - Modern, visual interface
- 🔄 **More flexible** - Switch modes with one env var

The old separate containers remain available for legacy compatibility, but new users should start with `triplo-unified`.
