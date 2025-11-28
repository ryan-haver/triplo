#!/usr/bin/env python3
"""
Triplo AI Web Configuration Interface
Provides a web UI to configure Triplo settings and manage the application
"""

from flask import Flask, render_template, jsonify, request, Response
import json
import os
import subprocess
import signal
import secrets
import string
from pathlib import Path
from typing import Dict, Tuple, Optional
from urllib import request as urlrequest, error as urlerror

from auth_storage import load_auth_config as encrypted_load_auth, save_auth_config as encrypted_save_auth

app = Flask(__name__)

CONFIG_PATH = Path.home() / ".config" / "Triplo AI" / "config.json"
PLATFORM_SETTINGS_PATH = Path(os.environ.get("PLATFORM_SETTINGS_FILE", Path.home() / ".config" / "Triplo AI" / "platform-settings.json"))
NOVNC_HTPASSWD_PATH = os.environ.get("NOVNC_HTPASSWD_PATH", "/etc/nginx/.htpasswd-novnc")
NOVNC_AUTH_SNIPPET_PATH = os.environ.get("NOVNC_AUTH_SNIPPET_PATH")
NOVNC_REALM_PREFIX = os.environ.get("NOVNC_AUTH_REALM_PREFIX", "Triplo noVNC")
TRIPLO_PID_FILE = "/var/run/triplo.pid"
NOVNC_PORT = os.environ.get("NOVNC_PORT", "6080")
NOVNC_PUBLIC_URL = os.environ.get("NOVNC_PUBLIC_URL")

DEFAULT_AUTH = {
    "webui": {"username": "triplo", "password": "triplo"},
    "novnc": {
        "use_webui_credentials": True,
        "username": "triplo",
        "password": "triplo"
    }
}


def _normalize_bool(value) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes", "on"}
    return bool(value)


def _load_platform_settings() -> Dict[str, bool]:
    desired = os.environ.get("ENABLE_NOVNC", "false").strip().lower() == "true"
    try:
        if PLATFORM_SETTINGS_PATH.exists():
            with open(PLATFORM_SETTINGS_PATH, "r", encoding="utf-8") as platform_file:
                data = json.load(platform_file)
                desired = bool(data.get("novnc_enabled", desired))
    except (json.JSONDecodeError, OSError):
        desired = os.environ.get("ENABLE_NOVNC", "false").strip().lower() == "true"
    return {"novnc_enabled": desired}


def _save_platform_settings(settings: Dict[str, bool]) -> None:
    PLATFORM_SETTINGS_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(PLATFORM_SETTINGS_PATH, "w", encoding="utf-8") as platform_file:
        json.dump(settings, platform_file, indent=2)
    try:
        os.chmod(PLATFORM_SETTINGS_PATH, 0o600)
    except PermissionError:
        pass


def _generate_llm_key() -> str:
    alphabet = string.ascii_lowercase + string.digits
    parts = []
    for _ in range(4):
        segment = "".join(secrets.choice(alphabet) for _ in range(4))
        parts.append(segment)
    return "-".join(parts)


def _request_json(url: str) -> Dict:
    req = urlrequest.Request(url, headers={"Accept": "application/json"})
    with urlrequest.urlopen(req, timeout=10) as response:
        charset = response.headers.get_content_charset() or "utf-8"
        payload = response.read().decode(charset)
        return json.loads(payload)


def _fetch_local_llm_models(base_url: str) -> list:
    cleaned = (base_url or "").strip()
    if not cleaned:
        raise ValueError("Missing Local LLM provider URL")
    cleaned = cleaned.rstrip("/")
    errors = []
    for suffix in ("/v1/models", "/api/tags"):
        endpoint = f"{cleaned}{suffix}"
        try:
            payload = _request_json(endpoint)
        except (urlerror.URLError, json.JSONDecodeError, ValueError) as exc:
            errors.append(str(exc))
            continue
        models = payload.get("models") or payload.get("data") or payload.get("result") or []
        names = []
        if isinstance(models, list):
            for item in models:
                if isinstance(item, str):
                    names.append(item.strip())
                elif isinstance(item, dict):
                    candidate = item.get("name") or item.get("model") or item.get("id")
                    if candidate:
                        names.append(str(candidate).strip())
        if names:
            seen = []
            for entry in names:
                if entry and entry not in seen:
                    seen.append(entry)
            return seen
    raise RuntimeError("Unable to load Local LLM models from provider: " + "; ".join(errors))


def _load_auth_config() -> Dict:
    """Return persisted auth configuration, falling back to defaults."""
    try:
        data = encrypted_load_auth(DEFAULT_AUTH)
    except Exception:  # pylint: disable=broad-except
        data = json.loads(json.dumps(DEFAULT_AUTH))

    data.setdefault("webui", {})
    data.setdefault("novnc", {})
    data["webui"].setdefault("username", DEFAULT_AUTH["webui"]["username"])
    data["webui"].setdefault("password", DEFAULT_AUTH["webui"]["password"])
    data["novnc"].setdefault("use_webui_credentials", True)
    data["novnc"].setdefault("username", data["webui"]["username"])
    data["novnc"].setdefault("password", data["webui"]["password"])
    return data


def _save_auth_config(config: Dict) -> None:
    encrypted_save_auth(config)


def _get_webui_credentials() -> Tuple[str, str]:
    auth = _load_auth_config()
    return auth["webui"].get("username", ""), auth["webui"].get("password", "")


def _get_novnc_credentials(auth_config: Optional[Dict] = None) -> Tuple[str, str]:
    config = auth_config or _load_auth_config()
    if config["novnc"].get("use_webui_credentials", True):
        return config["webui"].get("username", ""), config["webui"].get("password", "")
    return config["novnc"].get("username", ""), config["novnc"].get("password", "")


def _update_novnc_htpasswd(username: str, password: str) -> None:
    """Refresh the nginx htpasswd file used for noVNC."""
    if not username or not password:
        return
    try:
        subprocess.run(
            ["htpasswd", "-bc", NOVNC_HTPASSWD_PATH, username, password],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        print(f"Failed to update noVNC htpasswd: {exc}")


def _auth_required_response():
    """Return 401 response to trigger browser basic auth prompt"""
    return Response(
        "Authentication required",
        401,
        {"WWW-Authenticate": 'Basic realm="Triplo Web UI"'}
    )


def _infer_request_scheme(req) -> str:
    forwarded = req.headers.get("X-Forwarded-Proto")
    if forwarded:
        return forwarded.split(',')[0].strip()
    return req.scheme or "http"


def _infer_request_host(req) -> str:
    forwarded_host = req.headers.get("X-Forwarded-Host")
    host = forwarded_host or req.host or "localhost"
    if host.startswith('['):
        end = host.find(']')
        if end != -1:
            return host[:end + 1]
        return host
    if ':' in host:
        return host.split(':', 1)[0]
    return host


def _build_novnc_urls(req) -> Tuple[Optional[str], Optional[str]]:
    base = (NOVNC_PUBLIC_URL or "").strip()
    if base:
        base_url = base if base.endswith('/') else f"{base}/"
    else:
        scheme = _infer_request_scheme(req)
        host = _infer_request_host(req)
        port = (NOVNC_PORT or "6080").strip() or "6080"
        base_url = f"{scheme}://{host}:{port}/"
    logout_url = base_url.rstrip('/') + '/logout'
    return base_url, logout_url


def _rotate_novnc_realm() -> Optional[str]:
    """Update the nginx snippet used for the noVNC auth realm to force a fresh login."""
    if not NOVNC_AUTH_SNIPPET_PATH:
        return None
    token = secrets.token_hex(3)
    new_realm = f"{NOVNC_REALM_PREFIX} ({token})"
    snippet_body = f'auth_basic "{new_realm}";\nauth_basic_user_file {NOVNC_HTPASSWD_PATH};\n'
    try:
        snippet_path = Path(NOVNC_AUTH_SNIPPET_PATH)
        snippet_path.parent.mkdir(parents=True, exist_ok=True)
        snippet_path.write_text(snippet_body, encoding="utf-8")
        subprocess.run([
            "nginx", "-s", "reload"
        ], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return new_realm
    except OSError as exc:  # pylint: disable=broad-except
        print(f"Failed to rotate noVNC realm: {exc}")
        return None


def _restart_novnc_services() -> bool:
    """Restart supervisor-managed services backing the remote desktop."""
    restarted = False
    for program in ("novnc", "x11vnc"):
        try:
            result = subprocess.run(
                ["supervisorctl", "restart", program],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            restarted = restarted or result.returncode == 0
        except FileNotFoundError:
            break
    return restarted


@app.before_request
def require_basic_auth():
    """Enforce HTTP Basic Auth when credentials are configured"""
    if request.path == '/logout':
        return None
    username, password = _get_webui_credentials()
    if username and password:
        auth = request.authorization
        if not auth or auth.username != username or auth.password != password:
            return _auth_required_response()


def read_config():
    """Read current Triplo configuration"""
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH, 'r') as f:
            return json.load(f)
    return {}


def write_config(config_data, restart: bool = True):
    """Write Triplo configuration and optionally reload the app"""
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(CONFIG_PATH, 'w') as f:
        json.dump(config_data, f, indent=2)

    if restart:
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
        platform = _load_platform_settings()
        novnc_active = os.environ.get('ENABLE_NOVNC', 'false').lower() == 'true'
        novnc_configured = platform.get('novnc_enabled', novnc_active)
        novnc_url = None
        novnc_logout = None
        if novnc_active or novnc_configured:
            novnc_url, novnc_logout = _build_novnc_urls(request)
        
        return jsonify({
            'running': running,
            'novnc_enabled': novnc_active,
            'novnc': {
                'active': novnc_active,
                'configured': novnc_configured,
                'requires_restart': novnc_active != novnc_configured,
                'url': novnc_url,
                'logout_url': novnc_logout
            }
        })
    except Exception as e:
        return jsonify({
            'running': False,
            'error': str(e)
        })


@app.route('/api/platform/novnc', methods=['POST'])
def update_novnc_setting():
    """Persist the desired noVNC enablement state"""
    try:
        payload = request.json or {}
        if 'enabled' not in payload:
            return jsonify({'success': False, 'message': 'enabled flag is required'}), 400
        desired = _normalize_bool(payload.get('enabled'))
        platform = _load_platform_settings()
        platform['novnc_enabled'] = desired
        _save_platform_settings(platform)

        active = os.environ.get('ENABLE_NOVNC', 'false').lower() == 'true'
        return jsonify({
            'success': True,
            'configured': desired,
            'active': active,
            'requires_restart': desired != active,
            'message': 'Setting saved. Restart the container to apply the change.' if desired != active else 'Setting applied.'
        })
    except Exception as exc:
        return jsonify({'success': False, 'message': str(exc)}), 500


@app.route('/api/local-llm/key', methods=['POST'])
def regenerate_llm_key():
    """Generate a new Local LLM encryption key."""
    try:
        payload = request.json or {}
        persist = _normalize_bool(payload.get('persist', False))
        new_key = _generate_llm_key()

        if persist:
            config = read_config() or {}
            config.setdefault('settings', {})['llm_key'] = new_key
            write_config(config, restart=False)

        return jsonify({'success': True, 'key': new_key, 'persisted': persist})
    except Exception as exc:
        return jsonify({'success': False, 'message': str(exc)}), 500


@app.route('/api/local-llm/models', methods=['POST'])
def fetch_local_llm_models():
    """Fetch available models from the configured Local LLM/Ollama endpoint."""
    try:
        payload = request.json or {}
        url = (payload.get('url') or '').strip()
        if not url:
            return jsonify({'success': False, 'message': 'Local LLM provider URL is required'}), 400
        models = _fetch_local_llm_models(url)
        persist = _normalize_bool(payload.get('persist', False))
        if persist:
            config = read_config() or {}
            config.setdefault('settings', {})['ollama_models'] = models
            write_config(config, restart=False)
        return jsonify({'success': True, 'models': models, 'persisted': persist})
    except Exception as exc:
        return jsonify({'success': False, 'message': str(exc)}), 400


@app.route('/api/auth', methods=['GET'])
def get_auth():
    """Return web UI / noVNC authentication settings (without passwords)."""
    config = _load_auth_config()
    return jsonify({
        'webui': {
            'username': config['webui'].get('username', '')
        },
        'novnc': {
            'use_webui_credentials': config['novnc'].get('use_webui_credentials', True),
            'username': config['novnc'].get('username', '')
        }
    })


@app.route('/api/auth', methods=['POST'])
def update_auth():
    """Update authentication configuration for Web UI and noVNC."""
    try:
        payload = request.json or {}
        current = _load_auth_config()

        webui_payload = payload.get('webui', {})
        novnc_payload = payload.get('novnc', {})

        webui_username = (webui_payload.get('username') or current['webui'].get('username', '')).strip()
        if not webui_username:
            return jsonify({'success': False, 'message': 'Web UI username is required'}), 400

        webui_password = webui_payload.get('password')
        if webui_password:
            webui_password = webui_password.strip()
        else:
            webui_password = current['webui'].get('password', '')

        if not webui_password:
            return jsonify({'success': False, 'message': 'Web UI password is required'}), 400

        novnc_use_webui = novnc_payload.get('use_webui_credentials')
        if novnc_use_webui is None:
            novnc_use_webui = current['novnc'].get('use_webui_credentials', True)
        novnc_use_webui = bool(novnc_use_webui)

        custom_novnc_username = (current['novnc'].get('username') or webui_username).strip()
        custom_novnc_password = current['novnc'].get('password') or webui_password

        if 'username' in novnc_payload and novnc_payload.get('username') is not None:
            candidate = novnc_payload.get('username', '').strip()
            if candidate:
                custom_novnc_username = candidate

        if 'password' in novnc_payload and novnc_payload.get('password'):
            custom_novnc_password = novnc_payload['password']

        if novnc_use_webui:
            effective_novnc_username = webui_username
            effective_novnc_password = webui_password
        else:
            novnc_username = (novnc_payload.get('username') or custom_novnc_username).strip()
            novnc_password = novnc_payload.get('password') or custom_novnc_password
            if not novnc_username:
                return jsonify({'success': False, 'message': 'noVNC username is required'}), 400
            if not novnc_password:
                return jsonify({'success': False, 'message': 'noVNC password is required'}), 400
            custom_novnc_username = novnc_username
            custom_novnc_password = novnc_password
            effective_novnc_username = novnc_username
            effective_novnc_password = novnc_password

        updated_config = {
            'webui': {
                'username': webui_username,
                'password': webui_password
            },
            'novnc': {
                'use_webui_credentials': novnc_use_webui,
                'username': custom_novnc_username,
                'password': custom_novnc_password
            }
        }

        _save_auth_config(updated_config)
        _update_novnc_htpasswd(effective_novnc_username, effective_novnc_password)

        return jsonify({'success': True, 'message': 'Authentication settings updated'})
    except Exception as exc:
        return jsonify({'success': False, 'message': str(exc)}), 500


@app.route('/api/restart', methods=['POST'])
def restart():
    """Manually restart Triplo AI"""
    success = restart_triplo()
    return jsonify({
        'success': success,
        'message': 'Triplo restarted' if success else 'Failed to restart Triplo'
    })


@app.route('/api/novnc/logout', methods=['POST'])
def logout_novnc():
    """Invalidate browser sessions for noVNC without disturbing the Web UI."""
    if not os.environ.get('ENABLE_NOVNC', 'false').lower() == 'true':
        return jsonify({'success': False, 'message': 'Remote desktop is not enabled in this container.'}), 400

    realm = _rotate_novnc_realm()
    services_restarted = _restart_novnc_services()
    message = 'Remote desktop sessions closed. Refresh the noVNC tab to sign in again.'
    if not realm:
        message = 'Remote desktop services restarted. Reload noVNC to sign in again.'

    return jsonify({
        'success': True,
        'message': message,
        'realm_rotated': bool(realm),
        'services_restarted': services_restarted
    })


LOGOUT_HTML = """<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n    <meta charset=\"utf-8\">\n    <title>Logged out</title>\n    <meta http-equiv=\"refresh\" content=\"0;url=/\">\n</head>\n<body style=\"font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;\">\n    <p>You have been signed out. Redirecting to the login screen...</p>\n    <script>setTimeout(function(){ window.location.replace('/'); }, 50);</script>\n</body>\n</html>"""


@app.route('/logout', methods=['GET'])
def logout():
    """Force a fresh HTTP basic auth challenge for the Web UI and redirect home."""
    response = Response(
        LOGOUT_HTML,
        401,
        {
            "WWW-Authenticate": 'Basic realm="Triplo Web UI"',
            "Cache-Control": 'no-store, no-cache, must-revalidate',
            "Pragma": 'no-cache'
        }
    )
    response.headers['Content-Type'] = 'text/html; charset=utf-8'
    return response


if __name__ == '__main__':
    # Run on port 8080
    app.run(host='0.0.0.0', port=8080, debug=False)
