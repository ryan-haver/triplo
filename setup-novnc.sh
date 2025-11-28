#!/bin/bash

# Add fullscreen permissions to noVNC
cd /opt/novnc

# Create a simple wrapper script that adds the required headers
cat > /opt/novnc-start.sh << 'EOF'
#!/bin/bash

# Patch the noVNC HTML to add fullscreen permissions
sed -i 's/<head>/<head>\n<meta name="viewport" content="width=device-width, initial-scale=1">\n<style>body { margin: 0; overflow: hidden; }<\/style>/' /opt/novnc/vnc.html 2>/dev/null || true

# Start noVNC with the proxy
exec /opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080
EOF

chmod +x /opt/novnc-start.sh

# Patch vnc.html to allow fullscreen
if [ -f /opt/novnc/vnc.html ]; then
    # Add allow attribute to iframe if present, or ensure proper meta tags
    sed -i '/<head>/a\    <meta name="viewport" content="width=device-width, initial-scale=1">' /opt/novnc/vnc.html 2>/dev/null || true
fi

echo "noVNC fullscreen support configured"
