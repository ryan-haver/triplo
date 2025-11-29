# Triplo AI Docker - Automated Builds

[![Build and Push Docker Images](https://github.com/ryan-haver/triplo/actions/workflows/docker-build.yml/badge.svg)](https://github.com/ryan-haver/triplo/actions/workflows/docker-build.yml)

Automated Docker builds for Triplo AI with both headless and web-accessible modes.

## Quick Start

### Using Pre-built Images (Recommended)

**Web Mode (Browser Access):**

```bash
docker run -d -p 6080:6080 --name triplo-web \
  -v triplo-data:/root/.config/Triplo\ AI \
  ghcr.io/ryan-haver/triplo-web:latest
```

  Then open <http://localhost:6080> (default credentials: `triplo` / `triplo`). Rotate the credentials via **Access → Authentication** after first login.

**Headless Mode:**

```bash
docker run -d --name triplo-headless ghcr.io/ryan-haver/triplo-headless:latest
```

**Using Docker Compose:**

```bash
curl -O https://raw.githubusercontent.com/ryan-haver/triplo/main/docker-compose.yml
docker-compose up -d
```

## Available Images

Images are automatically built when new releases are published:

- `ghcr.io/ryan-haver/triplo-headless:latest` - Latest headless version
- `ghcr.io/ryan-haver/triplo-web:latest` - Latest web version
- `ghcr.io/ryan-haver/triplo-headless:5.4.0` - Specific version
- `ghcr.io/ryan-haver/triplo-web:5.4.0` - Specific version

## Features

✅ **Automatic Builds** - New images built automatically on each Triplo AI release

✅ **Multi-Version Support** - Tagged with semantic versioning (major, major.minor, full version)

✅ **Web Interface** - Access Triplo AI from any browser via noVNC

✅ **Headless Mode** - Perfect for automation and server deployments

✅ **Persistent Data** - Your settings and data are preserved

## Building Locally

If you prefer to build the images yourself:

```bash
# Clone the repository
git clone https://github.com/ryan-haver/triplo.git
cd triplo

# Build headless
docker build -f Dockerfile.headless -t triplo-headless --build-arg VERSION=v5.4.0 .

# Build web
docker build -f Dockerfile.web -t triplo-web --build-arg VERSION=v5.4.0 .

# Run locally built images
docker-compose -f docker-compose.local.yml up -d
```

## Configuration

### Persistent Data

Data is stored in Docker volumes. To back up:

```bash
docker run --rm -v triplo-data-web:/data -v $(pwd):/backup ubuntu tar czf /backup/triplo-backup.tar.gz /data
```

To restore:

```bash
docker run --rm -v triplo-data-web:/data -v $(pwd):/backup ubuntu tar xzf /backup/triplo-backup.tar.gz -C /
```

The key files that benefit from persistence live under `/root/.config/Triplo AI`:

- `config.json` – Triplo's runtime settings managed via the Web UI
- `webui-auth.json` – HTTP Basic Auth credentials for the Web UI and noVNC (editable from the Access tab or regenerated with `RESET_WEB_AUTH=true`)
- `platform-settings.json` – Platform-level switches (currently the Remote Desktop/noVNC enablement flag) written by the Access tab Remote Desktop toggle

Mount that directory once (for example, `-v triplo-data:/root/.config/Triplo\ AI`) to retain Triplo configuration, authentication, and platform toggle data.

### Custom Ports

```bash
docker run -d -p 8080:6080 --name triplo-web ghcr.io/ryan-haver/triplo-web:latest
```

### Authentication

Both the Web UI and noVNC interfaces ship locked down with default credentials `triplo` / `triplo`. Override them when you start the container:

```bash
docker run -d -p 6080:6080 --name triplo-web \
  -e WEBUI_USERNAME="admin" \
  -e WEBUI_PASSWORD="supersecret" \
  -v triplo-data:/root/.config/Triplo\ AI \
  ghcr.io/ryan-haver/triplo-web:latest
```

noVNC automatically reuses the Web UI credentials, but you can provide dedicated values with `NOVNC_USERNAME` / `NOVNC_PASSWORD` if needed. Credentials are persisted in `/root/.config/Triplo AI/webui-auth.json`, so keep that directory on a volume. Change them later in the Web UI (Access tab) or set `RESET_WEB_AUTH=true` to regenerate from environment variables.

If you expose the container through a reverse proxy (so port 6080 is not directly reachable), provide `NOVNC_PUBLIC_URL` with the externally visible URL. The Access tab uses it to populate the "Open noVNC" link inside the Remote Desktop card, while the logout control now talks to the Web UI backend directly so it works regardless of how you publish the VNC endpoint.

### Memory Allocation

```bash
docker run -d --shm-size=2g -p 6080:6080 --name triplo-web ghcr.io/ryan-haver/triplo-web:latest
```

## Automation

### Automatic Updates

The GitHub Actions workflow automatically:

1. Monitors the upstream Elbruz-Technologies/triplo repository
2. Builds new Docker images when releases are published
3. Publishes to GitHub Container Registry
4. Tags with semantic versioning

### Manual Trigger

You can manually trigger a build for any version:

1. Go to Actions tab in your fork
2. Select "Build and Push Docker Images"
3. Click "Run workflow"
4. Enter the version tag (e.g., `v5.4.0`)

## Managing Containers

```bash
# View logs
docker logs -f triplo-web

# Stop
docker stop triplo-web

# Start
docker start triplo-web

# Restart
docker restart triplo-web

# Remove
docker rm -f triplo-web

# Update to latest
docker pull ghcr.io/ryan-haver/triplo-web:latest
docker stop triplo-web
docker rm triplo-web
docker run -d -p 6080:6080 --name triplo-web ghcr.io/ryan-haver/triplo-web:latest
```

## Troubleshooting

### Image not found

Make sure GitHub Packages are public:

1. Go to your fork's settings
2. Navigate to Packages
3. Make the package public

### Connection refused on port 6080

```bash
# Check if container is running
docker ps

# Check logs
docker logs triplo-web

# Try restarting
docker restart triplo-web
```

### Display issues

```bash
# Restart with fresh display
docker restart triplo-web
```

## Architecture

- **Base**: Ubuntu 22.04
- **Display**: Xvfb (Virtual Framebuffer)
- **VNC**: x11vnc
- **Web Interface**: noVNC
- **Window Manager**: Fluxbox
- **Process Manager**: Supervisord

## Security

- Images run as root (required for Electron apps in Docker)
- noVNC connection is unencrypted (HTTP)
- For production:
  - Use a reverse proxy with HTTPS
  - Add authentication to noVNC
  - Restrict network access

## Version Information

- Latest Release: v5.4.0
- Updated: Auto-synced with upstream releases
- Source: <https://github.com/Elbruz-Technologies/triplo>

## Contributing

Feel free to open issues or submit PRs for improvements to the Docker setup!

## License

Triplo AI is property of Elbruz Technologies. This Docker setup is provided as-is for personal use.

## Links

- [Upstream Repository](https://github.com/Elbruz-Technologies/triplo)
- [Docker Images](https://github.com/ryan-haver/triplo/pkgs/container/triplo-web)
- [Triplo AI Official Site](https://triplo.ai)
