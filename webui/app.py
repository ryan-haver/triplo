#!/usr/bin/env python3
"""
Triplo AI Web Configuration Interface
Provides a web UI to configure Triplo settings and manage the application
"""

from flask import Flask, render_template, jsonify, request
import json
import os
import subprocess
import signal
from pathlib import Path

app = Flask(__name__)

CONFIG_PATH = Path.home() / ".config" / "Triplo AI" / "config.json"
TRIPLO_PID_FILE = "/var/run/triplo.pid"


def read_config():
    """Read current Triplo configuration"""
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH, 'r') as f:
            return json.load(f)
    return {}


def write_config(config_data):
    """Write Triplo configuration and reload app"""
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(CONFIG_PATH, 'w') as f:
        json.dump(config_data, f, indent=2)
    
    # Reload Triplo AI
    restart_triplo()


def restart_triplo():
    """Restart the Triplo AI application"""
    try:
        # Find Triplo process
        result = subprocess.run(
            ["pgrep", "-f", "triplo.ai"],
            capture_output=True,
            text=True
        )
        
        if result.stdout.strip():
            pid = int(result.stdout.strip().split()[0])
            os.kill(pid, signal.SIGTERM)
            
            # Wait a moment for graceful shutdown
            import time
            time.sleep(2)
        
        # Restart via supervisorctl if available
        subprocess.run(["supervisorctl", "restart", "triplo"], check=False)
        
        return True
    except Exception as e:
        print(f"Error restarting Triplo: {e}")
        return False


@app.route('/')
def index():
    """Serve the main configuration UI"""
    return render_template('index.html')


@app.route('/api/config', methods=['GET'])
def get_config():
    """Get current configuration"""
    config = read_config()
    return jsonify(config)


@app.route('/api/config', methods=['POST'])
def update_config():
    """Update configuration"""
    try:
        new_config = request.json
        write_config(new_config)
        return jsonify({
            'success': True,
            'message': 'Configuration updated and Triplo restarted'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500


@app.route('/api/status', methods=['GET'])
def get_status():
    """Get Triplo AI status"""
    try:
        result = subprocess.run(
            ["pgrep", "-f", "triplo.ai"],
            capture_output=True,
            text=True
        )
        running = bool(result.stdout.strip())
        
        return jsonify({
            'running': running,
            'novnc_enabled': os.environ.get('ENABLE_NOVNC', 'false').lower() == 'true'
        })
    except Exception as e:
        return jsonify({
            'running': False,
            'error': str(e)
        })


@app.route('/api/restart', methods=['POST'])
def restart():
    """Manually restart Triplo AI"""
    success = restart_triplo()
    return jsonify({
        'success': success,
        'message': 'Triplo restarted' if success else 'Failed to restart Triplo'
    })


if __name__ == '__main__':
    # Run on port 8080
    app.run(host='0.0.0.0', port=8080, debug=False)
