#!/usr/bin/env python3
"""Encrypted storage helpers for Web UI authentication data."""

from __future__ import annotations

import base64
import binascii
import json
import os
import secrets
import hmac
import hashlib
from pathlib import Path
from typing import Any, Dict, Optional

AUTH_CONFIG_PATH = Path(
    os.environ.get("WEBUI_AUTH_FILE", Path.home() / ".config" / "Triplo AI" / "webui-auth.json")
)
AUTH_KEY_PATH = Path(
    os.environ.get("WEBUI_AUTH_KEY_FILE", Path.home() / ".config" / "Triplo AI" / "webui-auth.key")
)
_ENVELOPE_VERSION = 1


def _ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def _load_key() -> bytes:
    _ensure_parent(AUTH_KEY_PATH)
    if not AUTH_KEY_PATH.exists():
        key_bytes = secrets.token_bytes(32)
        AUTH_KEY_PATH.write_bytes(base64.b64encode(key_bytes))
        try:
            os.chmod(AUTH_KEY_PATH, 0o600)
        except PermissionError:
            pass
        return key_bytes

    raw = AUTH_KEY_PATH.read_bytes()
    try:
        key_bytes = base64.b64decode(raw, validate=True)
    except (binascii.Error, ValueError):
        raise ValueError("Invalid auth key file format")
    if len(key_bytes) < 32:
        raise ValueError("Auth key must be at least 32 bytes")
    return key_bytes[:32]


def _derive_stream(key: bytes, nonce: bytes, length: int) -> bytes:
    out = bytearray(length)
    generated = 0
    counter = 0
    while generated < length:
        counter_bytes = counter.to_bytes(8, "big")
        block = hashlib.blake2b(
            nonce + counter_bytes,
            digest_size=64,
            key=key,
        ).digest()
        chunk = min(len(block), length - generated)
        for idx in range(chunk):
            out[generated + idx] = block[idx]
        generated += chunk
        counter += 1
    return bytes(out)


def _encrypt_payload(plaintext: bytes, key: bytes) -> Dict[str, Any]:
    nonce = secrets.token_bytes(16)
    keystream = _derive_stream(key, nonce, len(plaintext))
    ciphertext = bytes(a ^ b for a, b in zip(plaintext, keystream))
    mac = hmac.new(key, nonce + ciphertext, hashlib.sha256).digest()
    return {
        "version": _ENVELOPE_VERSION,
        "nonce": base64.b64encode(nonce).decode("ascii"),
        "ciphertext": base64.b64encode(ciphertext).decode("ascii"),
        "mac": base64.b64encode(mac).decode("ascii"),
    }


def _decrypt_payload(payload: Dict[str, Any], key: bytes) -> bytes:
    if payload.get("version") != _ENVELOPE_VERSION:
        raise ValueError("Unsupported auth payload version")
    try:
        nonce = base64.b64decode(payload["nonce"], validate=True)
        ciphertext = base64.b64decode(payload["ciphertext"], validate=True)
        mac = base64.b64decode(payload["mac"], validate=True)
    except (KeyError, ValueError, binascii.Error) as exc:
        raise ValueError("Malformed encrypted auth payload") from exc

    expected_mac = hmac.new(key, nonce + ciphertext, hashlib.sha256).digest()
    if not hmac.compare_digest(mac, expected_mac):
        raise ValueError("Authentication data integrity check failed")

    keystream = _derive_stream(key, nonce, len(ciphertext))
    plaintext = bytes(a ^ b for a, b in zip(ciphertext, keystream))
    return plaintext


def save_auth_config(config: Dict[str, Any]) -> None:
    """Persist the provided configuration with encryption."""
    key = _load_key()
    _ensure_parent(AUTH_CONFIG_PATH)
    plaintext = json.dumps(config).encode("utf-8")
    envelope = _encrypt_payload(plaintext, key)
    with open(AUTH_CONFIG_PATH, "w", encoding="utf-8") as auth_file:
        json.dump(envelope, auth_file, indent=2)
    try:
        os.chmod(AUTH_CONFIG_PATH, 0o600)
    except PermissionError:
        pass


def _clone(obj: Dict[str, Any]) -> Dict[str, Any]:
    return json.loads(json.dumps(obj))


def load_auth_config(fallback: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Load and return the decrypted authentication configuration."""
    if not AUTH_CONFIG_PATH.exists():
        if fallback is None:
            raise FileNotFoundError(AUTH_CONFIG_PATH)
        data = _clone(fallback)
        save_auth_config(data)
        return data

    try:
        with open(AUTH_CONFIG_PATH, "r", encoding="utf-8") as auth_file:
            payload = json.load(auth_file)
    except json.JSONDecodeError:
        if fallback is None:
            raise
        data = _clone(fallback)
        save_auth_config(data)
        return data

    if isinstance(payload, dict) and "ciphertext" in payload:
        key = _load_key()
        plaintext = _decrypt_payload(payload, key)
        return json.loads(plaintext)

    # Legacy plaintext file – migrate on next save
    if not isinstance(payload, dict):
        raise ValueError("Invalid auth configuration content")
    save_auth_config(payload)
    return payload