#!/bin/bash

# Generate Triplo AI configuration from environment variables
/usr/local/bin/init-config.sh

# Configure supervisord based on ENABLE_NOVNC
if [ "${ENABLE_NOVNC}" = "true" ]; then
    echo "🖥️  Starting Triplo AI with noVNC enabled"
    export DISPLAY=:1
    
    # Use noVNC-enabled supervisor config
    cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root

[program:xvfb]
command=/usr/bin/Xvfb :1 -screen 0 %(ENV_DISPLAY_WIDTH)sx%(ENV_DISPLAY_HEIGHT)sx24
autostart=true
autorestart=true
priority=100
stdout_logfile=/var/log/supervisor/xvfb.log
stderr_logfile=/var/log/supervisor/xvfb_err.log

[program:fluxbox]
command=/usr/bin/fluxbox -display :1
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

    # Configure nginx for noVNC + Web UI
    cat > /etc/nginx/nginx.conf << 'EOF'
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
        }

        location /websockify {
            proxy_pass http://localhost:6081;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
        }
    }

    server {
        listen 8080;
        server_name _;

        location / {
            proxy_pass http://127.0.0.1:5000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
EOF

else
    echo "🚀 Starting Triplo AI in headless mode"
    export DISPLAY=:99
    
    # Use headless-only supervisor config
    cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root

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
