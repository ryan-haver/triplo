#!/bin/bash

# Generate Triplo AI configuration from environment variables
/usr/local/bin/init-config.sh

# Prepare authentication configuration (persisted under /root/.config/Triplo AI)
AUTH_CONFIG_PATH=${WEBUI_AUTH_FILE:-"/root/.config/Triplo AI/webui-auth.json"}
AUTH_KEY_PATH=${WEBUI_AUTH_KEY_FILE:-"/root/.config/Triplo AI/webui-auth.key"}
NOVNC_HTPASSWD_PATH=${NOVNC_HTPASSWD_PATH:-/etc/nginx/.htpasswd-novnc}
PLATFORM_SETTINGS_PATH=${PLATFORM_SETTINGS_FILE:-"/root/.config/Triplo AI/platform-settings.json"}
RESET_WEB_AUTH=${RESET_WEB_AUTH:-false}
AUTH_TOOL=${WEBUI_AUTH_TOOL:-/opt/webui/auth_cli.py}
DEFAULT_ENABLE_NOVNC=${ENABLE_NOVNC:-false}
DEFAULT_ENABLE_NOVNC=$(echo "$DEFAULT_ENABLE_NOVNC" | tr '[:upper:]' '[:lower:]')
if [ "$DEFAULT_ENABLE_NOVNC" != "true" ]; then
    DEFAULT_ENABLE_NOVNC="false"
fi

mkdir -p "$(dirname "$AUTH_CONFIG_PATH")"
mkdir -p "$(dirname "$AUTH_KEY_PATH")"
mkdir -p "$(dirname "$PLATFORM_SETTINGS_PATH")"

write_platform_settings() {
    local flag="$1"
    if [ "$flag" = "true" ]; then
        printf '{"novnc_enabled": true}\n' > "$PLATFORM_SETTINGS_PATH"
    else
        printf '{"novnc_enabled": false}\n' > "$PLATFORM_SETTINGS_PATH"
    fi
    chmod 600 "$PLATFORM_SETTINGS_PATH"
}

if [ ! -f "$PLATFORM_SETTINGS_PATH" ]; then
    write_platform_settings "$DEFAULT_ENABLE_NOVNC"
fi

PLATFORM_NOVNC=$(jq -r '.novnc_enabled // empty' "$PLATFORM_SETTINGS_PATH" 2>/dev/null)
if [ "$PLATFORM_NOVNC" != "true" ] && [ "$PLATFORM_NOVNC" != "false" ]; then
    PLATFORM_NOVNC="$DEFAULT_ENABLE_NOVNC"
    write_platform_settings "$PLATFORM_NOVNC"
fi

ENABLE_NOVNC="$PLATFORM_NOVNC"
export ENABLE_NOVNC

DEFAULT_WEBUI_USER=${WEBUI_USERNAME:-triplo}
DEFAULT_WEBUI_PASS=${WEBUI_PASSWORD:-triplo}
DEFAULT_NOVNC_USER=${NOVNC_USERNAME:-}
DEFAULT_NOVNC_PASS=${NOVNC_PASSWORD:-}
NOVNC_SYNC_WITH_WEBUI=true

if [ -n "$DEFAULT_NOVNC_USER" ] || [ -n "$DEFAULT_NOVNC_PASS" ]; then
    NOVNC_SYNC_WITH_WEBUI=false
    [ -z "$DEFAULT_NOVNC_USER" ] && DEFAULT_NOVNC_USER=$DEFAULT_WEBUI_USER
    [ -z "$DEFAULT_NOVNC_PASS" ] && DEFAULT_NOVNC_PASS=$DEFAULT_WEBUI_PASS
else
    DEFAULT_NOVNC_USER=$DEFAULT_WEBUI_USER
    DEFAULT_NOVNC_PASS=$DEFAULT_WEBUI_PASS
fi

write_auth_config() {
    local webui_user="$1"
    local webui_pass="$2"
    local novnc_user="$3"
    local novnc_pass="$4"
    local novnc_sync_flag="$5"
    local novnc_sync_json="false"
    if [ "$novnc_sync_flag" = "true" ]; then
        novnc_sync_json="true"
    fi

    local payload
    payload=$(jq -n \
        --arg webui_user "$webui_user" \
        --arg webui_pass "$webui_pass" \
        --arg novnc_user "$novnc_user" \
        --arg novnc_pass "$novnc_pass" \
        --argjson novnc_sync $novnc_sync_json \
        '{
            webui: { username: $webui_user, password: $webui_pass },
            novnc: {
                use_webui_credentials: $novnc_sync,
                username: $novnc_user,
                password: $novnc_pass
            }
        }')

    printf '%s' "$payload" | python3 "$AUTH_TOOL" write-json >/dev/null
    AUTH_CONFIG_JSON=$(python3 "$AUTH_TOOL" dump 2>/dev/null)
    if [ -z "$AUTH_CONFIG_JSON" ]; then
        AUTH_CONFIG_JSON="$payload"
    fi
}

persist_auth_config() {
    local payload="$1"
    printf '%s' "$payload" | python3 "$AUTH_TOOL" write-json >/dev/null
}

if [ "$RESET_WEB_AUTH" = "true" ] || [ ! -f "$AUTH_CONFIG_PATH" ]; then
    write_auth_config "$DEFAULT_WEBUI_USER" "$DEFAULT_WEBUI_PASS" "$DEFAULT_NOVNC_USER" "$DEFAULT_NOVNC_PASS" "$NOVNC_SYNC_WITH_WEBUI"
fi

# Load persisted credentials (fallback to defaults if parsing fails)
if ! AUTH_CONFIG_JSON=$(python3 "$AUTH_TOOL" dump 2>/dev/null); then
    echo "⚠️  Unable to read $AUTH_CONFIG_PATH — regenerating with defaults"
    write_auth_config "$DEFAULT_WEBUI_USER" "$DEFAULT_WEBUI_PASS" "$DEFAULT_NOVNC_USER" "$DEFAULT_NOVNC_PASS" "$NOVNC_SYNC_WITH_WEBUI"
fi

WEBUI_AUTH_USER=$(echo "$AUTH_CONFIG_JSON" | jq -r '.webui.username // empty')
WEBUI_AUTH_PASS=$(echo "$AUTH_CONFIG_JSON" | jq -r '.webui.password // empty')

NOVNC_USE_WEBUI=$(echo "$AUTH_CONFIG_JSON" | jq -r '.novnc.use_webui_credentials // false')
if [ "$NOVNC_USE_WEBUI" = "true" ]; then
    NOVNC_AUTH_USER=$WEBUI_AUTH_USER
    NOVNC_AUTH_PASS=$WEBUI_AUTH_PASS
else
    NOVNC_AUTH_USER=$(echo "$AUTH_CONFIG_JSON" | jq -r '.novnc.username // empty')
    NOVNC_AUTH_PASS=$(echo "$AUTH_CONFIG_JSON" | jq -r '.novnc.password // empty')
fi

if [ -z "$WEBUI_AUTH_USER" ] || [ -z "$WEBUI_AUTH_PASS" ]; then
    echo "❌ Missing Web UI credentials — resetting to defaults"
    write_auth_config "$DEFAULT_WEBUI_USER" "$DEFAULT_WEBUI_PASS" "$DEFAULT_NOVNC_USER" "$DEFAULT_NOVNC_PASS" "$NOVNC_SYNC_WITH_WEBUI"
    AUTH_CONFIG_JSON=$(python3 "$AUTH_TOOL" dump)
    WEBUI_AUTH_USER=$(echo "$AUTH_CONFIG_JSON" | jq -r '.webui.username // empty')
    WEBUI_AUTH_PASS=$(echo "$AUTH_CONFIG_JSON" | jq -r '.webui.password // empty')
    NOVNC_USE_WEBUI=$(echo "$AUTH_CONFIG_JSON" | jq -r '.novnc.use_webui_credentials // false')
    if [ "$NOVNC_USE_WEBUI" = "true" ]; then
        NOVNC_AUTH_USER=$WEBUI_AUTH_USER
        NOVNC_AUTH_PASS=$WEBUI_AUTH_PASS
    else
        NOVNC_AUTH_USER=$(echo "$AUTH_CONFIG_JSON" | jq -r '.novnc.username // empty')
        NOVNC_AUTH_PASS=$(echo "$AUTH_CONFIG_JSON" | jq -r '.novnc.password // empty')
    fi
fi

if [ -z "$NOVNC_AUTH_USER" ] || [ -z "$NOVNC_AUTH_PASS" ]; then
    NOVNC_AUTH_USER=$WEBUI_AUTH_USER
    NOVNC_AUTH_PASS=$WEBUI_AUTH_PASS
    AUTH_CONFIG_JSON=$(echo "$AUTH_CONFIG_JSON" | jq --arg user "$NOVNC_AUTH_USER" --arg pass "$NOVNC_AUTH_PASS" '.novnc.username = $user | .novnc.password = $pass | .novnc.use_webui_credentials = true')
    persist_auth_config "$AUTH_CONFIG_JSON"
fi

export WEBUI_AUTH_FILE="$AUTH_CONFIG_PATH"
export WEBUI_AUTH_KEY_FILE="$AUTH_KEY_PATH"
export NOVNC_HTPASSWD_PATH

# Configure supervisord based on ENABLE_NOVNC
if [ "${ENABLE_NOVNC}" = "true" ]; then
    echo "🖥️  Starting Triplo AI with noVNC enabled"
    export DISPLAY=:1
    
    # Use noVNC-enabled supervisor config
    cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
nodaemon=true
user=root

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[program:xvfb]
command=/usr/bin/Xvfb :1 -screen 0 %(ENV_DISPLAY_WIDTH)sx%(ENV_DISPLAY_HEIGHT)sx24
autostart=true
autorestart=true
priority=100
stdout_logfile=/var/log/supervisor/xvfb.log
stderr_logfile=/var/log/supervisor/xvfb_err.log

[program:fluxbox]
command=/usr/bin/startfluxbox
autostart=true
autorestart=true
priority=200
environment=DISPLAY=":1"
stdout_logfile=/var/log/supervisor/fluxbox.log
stderr_logfile=/var/log/supervisor/fluxbox_err.log

[program:x11vnc]
command=/usr/bin/x11vnc -display :1 -forever -shared -rfbport 5901
autostart=true
autorestart=true
priority=300
environment=DISPLAY=":1"
stdout_logfile=/var/log/supervisor/x11vnc.log
stderr_logfile=/var/log/supervisor/x11vnc_err.log

[program:novnc]
command=/opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 6081
autostart=true
autorestart=true
priority=400
stdout_logfile=/var/log/supervisor/novnc.log
stderr_logfile=/var/log/supervisor/novnc_err.log

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autostart=true
autorestart=true
priority=410
stdout_logfile=/var/log/supervisor/nginx.log
stderr_logfile=/var/log/supervisor/nginx_err.log

[program:triplo]
command=/opt/triplo/triplo-ai/triplo.ai --no-sandbox --disable-gpu --start-fullscreen
directory=/opt/triplo/triplo-ai
autostart=true
autorestart=true
priority=500
environment=DISPLAY=":1"
stdout_logfile=/var/log/supervisor/triplo.log
stderr_logfile=/var/log/supervisor/triplo_err.log

[program:webui]
command=/usr/local/bin/gunicorn -w 2 -b 0.0.0.0:5000 app:app
directory=/opt/webui
autostart=true
autorestart=true
priority=600
stdout_logfile=/var/log/supervisor/webui.log
stderr_logfile=/var/log/supervisor/webui_err.log
EOF

    # Configure nginx for noVNC + Web UI (with optional authentication)
    NOVNC_AUTH_INCLUDE=""
    NOVNC_AUTH_SNIPPET="/etc/nginx/snippets/novnc-auth.conf"
    mkdir -p /etc/nginx/snippets
    if [ -n "$NOVNC_AUTH_USER" ] && [ -n "$NOVNC_AUTH_PASS" ]; then
        htpasswd -bc "$NOVNC_HTPASSWD_PATH" "$NOVNC_AUTH_USER" "$NOVNC_AUTH_PASS" > /dev/null 2>&1
        cat > "$NOVNC_AUTH_SNIPPET" << EOF
auth_basic "Triplo noVNC";
auth_basic_user_file $NOVNC_HTPASSWD_PATH;
EOF
        printf -v NOVNC_AUTH_INCLUDE '        include %s;\n' "$NOVNC_AUTH_SNIPPET"
        echo "🔐 Enabled basic auth for noVNC"
        export NOVNC_AUTH_SNIPPET_PATH="$NOVNC_AUTH_SNIPPET"
    else
        export NOVNC_AUTH_SNIPPET_PATH=""
    fi

    DOLLAR='$'
    cat > /etc/nginx/nginx.conf << EOF
user root;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 6080;
        server_name _;

        # Permissions Policy for fullscreen API
        add_header Permissions-Policy "fullscreen=(self)" always;
        add_header Feature-Policy "fullscreen *" always;

        location / {
            root /opt/novnc;
            index index.html;
${NOVNC_AUTH_INCLUDE}        }

        location = /logout {
            default_type text/html;
            add_header Cache-Control "no-store" always;
            add_header WWW-Authenticate "Basic realm=\"Triplo noVNC\"" always;
            return 401 '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Logged out</title><meta http-equiv="refresh" content="0;url=/"></head><body style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif; margin: 2rem;"><p>You have been signed out of the remote desktop. Redirecting...</p><script>setTimeout(function(){ window.location.replace("/"); }, 50);</script></body></html>';
        }

        location /websockify {
            proxy_pass http://localhost:6081;
            proxy_http_version 1.1;
            proxy_set_header Upgrade ${DOLLAR}http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host ${DOLLAR}host;
        }
    }

    server {
        listen 8080;
        server_name _;

        location / {
            proxy_pass http://127.0.0.1:5000;
            proxy_set_header Host ${DOLLAR}host;
            proxy_set_header X-Real-IP ${DOLLAR}remote_addr;
            proxy_set_header X-Forwarded-For ${DOLLAR}proxy_add_x_forwarded_for;
        }
    }
}
EOF

else
    echo "🚀 Starting Triplo AI in headless mode"
    export DISPLAY=:99
    
    # Use headless-only supervisor config
    cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
nodaemon=true
user=root

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[program:xvfb]
command=/usr/bin/Xvfb :99 -screen 0 1920x1080x24
autostart=true
autorestart=true
priority=100
stdout_logfile=/var/log/supervisor/xvfb.log
stderr_logfile=/var/log/supervisor/xvfb_err.log

[program:triplo]
command=/opt/triplo/triplo-ai/triplo.ai --no-sandbox --disable-gpu
directory=/opt/triplo/triplo-ai
autostart=true
autorestart=true
priority=200
environment=DISPLAY=":99"
stdout_logfile=/var/log/supervisor/triplo.log
stderr_logfile=/var/log/supervisor/triplo_err.log

[program:webui]
command=/usr/local/bin/gunicorn -w 2 -b 0.0.0.0:8080 app:app
directory=/opt/webui
autostart=true
autorestart=true
priority=300
stdout_logfile=/var/log/supervisor/webui.log
stderr_logfile=/var/log/supervisor/webui_err.log
EOF
fi

# Set default display dimensions if not provided
export DISPLAY_WIDTH=${DISPLAY_WIDTH:-1920}
export DISPLAY_HEIGHT=${DISPLAY_HEIGHT:-1080}

# Execute the main command
exec "$@"
