#!/bin/bash
set -euo pipefail

export DISPLAY="${DISPLAY:-:1}"
TARGET_CLASS=${TRIPLO_WM_CLASS:-"triplo ai.Triplo AI"}
POLL_INTERVAL=${TRIPLO_WINDOW_CENTER_POLL:-2}

normalize_int() {
    local value=$1
    if ! [[ $value =~ ^[0-9]+$ ]]; then
        value=2
    fi
    printf '%s' "$value"
}

POLL_INTERVAL=$(normalize_int "$POLL_INTERVAL")

read_screen_size() {
    local dims
    dims=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ {print $2; exit}' | tr -d ' ')
    if [ -n "$dims" ]; then
        SCREEN_WIDTH=${dims%x*}
        SCREEN_HEIGHT=${dims#*x}
    else
        SCREEN_WIDTH=${DISPLAY_WIDTH:-1920}
        SCREEN_HEIGHT=${DISPLAY_HEIGHT:-1080}
    fi
}

find_window_id() {
    wmctrl -lx 2>/dev/null | awk -v target="$TARGET_CLASS" 'BEGIN{IGNORECASE=1} index($0, target) {print $1; exit}'
}

center_window() {
    local win_id=$1
    local geometry
    geometry=$(wmctrl -lG 2>/dev/null | awk -v id="$win_id" '$1==id {print $3" "$4" "$5" "$6; exit}')
    [ -z "$geometry" ] && return 0
    read -r win_x win_y win_w win_h <<<"$geometry"
    read_screen_size

    local target_x target_y
    target_x=$(( (SCREEN_WIDTH - win_w) / 2 ))
    target_y=$(( (SCREEN_HEIGHT - win_h) / 2 ))
    [ $target_x -lt 0 ] && target_x=0
    [ $target_y -lt 0 ] && target_y=0

    wmctrl -i -r "$win_id" -e 0,$target_x,$target_y,-1,-1 2>/dev/null || true
}

last_id=""
while true; do
    win_id=$(find_window_id || true)
    if [ -n "${win_id:-}" ] && [ "$win_id" != "$last_id" ]; then
        center_window "$win_id"
        last_id="$win_id"
    fi
    sleep "$POLL_INTERVAL"
done
