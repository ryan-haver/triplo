#!/usr/bin/env python3
"""CLI helper for encrypted Web UI auth configuration."""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any

from auth_storage import load_auth_config, save_auth_config


def _dump_command(pretty: bool, allow_missing: bool) -> int:
    try:
        data = load_auth_config()
    except FileNotFoundError:
        if allow_missing:
            return 0
        print("Auth config not found", file=sys.stderr)
        return 1
    except Exception as exc:  # pylint: disable=broad-except
        print(f"Failed to load auth config: {exc}", file=sys.stderr)
        return 1

    indent = 2 if pretty else None
    print(json.dumps(data, indent=indent))
    return 0


def _write_json_command(raw_json: str | None) -> int:
    payload = raw_json if raw_json is not None else sys.stdin.read()
    if not payload.strip():
        print("No JSON payload provided", file=sys.stderr)
        return 1
    try:
        data: Any = json.loads(payload)
    except json.JSONDecodeError as exc:
        print(f"Invalid JSON payload: {exc}", file=sys.stderr)
        return 1
    try:
        save_auth_config(data)
    except Exception as exc:  # pylint: disable=broad-except
        print(f"Failed to save auth config: {exc}", file=sys.stderr)
        return 1
    return 0


def _set_command(args: argparse.Namespace) -> int:
    novnc_sync = args.novnc_sync.lower() == "true"
    payload = {
        "webui": {
            "username": args.webui_user,
            "password": args.webui_pass,
        },
        "novnc": {
            "use_webui_credentials": novnc_sync,
            "username": args.novnc_user,
            "password": args.novnc_pass,
        },
    }
    try:
        save_auth_config(payload)
    except Exception as exc:  # pylint: disable=broad-except
        print(f"Failed to save auth config: {exc}", file=sys.stderr)
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Manage encrypted auth configuration")
    subparsers = parser.add_subparsers(dest="command", required=True)

    dump_parser = subparsers.add_parser("dump", help="Print decrypted auth JSON")
    dump_parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output")
    dump_parser.add_argument(
        "--allow-missing",
        action="store_true",
        help="Exit successfully when the config file has not been created yet",
    )

    write_parser = subparsers.add_parser("write-json", help="Encrypt JSON read from stdin or --data")
    write_parser.add_argument("--data", help="Inline JSON payload; defaults to stdin")

    set_parser = subparsers.add_parser("set", help="Write credentials provided via CLI arguments")
    set_parser.add_argument("--webui-user", required=True)
    set_parser.add_argument("--webui-pass", required=True)
    set_parser.add_argument("--novnc-user", required=True)
    set_parser.add_argument("--novnc-pass", required=True)
    set_parser.add_argument(
        "--novnc-sync",
        choices=("true", "false"),
        default="true",
        help="Whether noVNC reuses Web UI credentials",
    )

    args = parser.parse_args()

    if args.command == "dump":
        return _dump_command(pretty=args.pretty, allow_missing=args.allow_missing)
    if args.command == "write-json":
        return _write_json_command(args.data)
    if args.command == "set":
        return _set_command(args)

    parser.error("Unknown command")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
