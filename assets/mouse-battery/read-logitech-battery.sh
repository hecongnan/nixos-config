#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
export PATH=/run/current-system/sw/bin
export LC_ALL=C
umask 077

cache_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dms/mouseBattery"
cache_file="$cache_dir/logitech-c547-percentage"

valid_percentage() {
    [[ "${1:-}" =~ ^(0|[1-9][0-9]?|100)$ ]]
}

save_percentage() {
    local temporary
    mkdir -p -- "$cache_dir" || return
    temporary=$(mktemp "$cache_file.XXXXXX") || return
    if ! printf '%s\n' "$1" > "$temporary" || ! mv -T -- "$temporary" "$cache_file"; then
        rm -f -- "$temporary"
    fi
}

if [[ -n ${XDG_RUNTIME_DIR:-} ]]; then
    exec 9>"$XDG_RUNTIME_DIR/dux-logitech-c547-battery.lock"
    flock -w 20 9
fi

solaar="@solaar@"
for sys_node in /sys/bus/hid/devices/*046D:C547*/hidraw/hidraw*; do
    device="/dev/${sys_node##*/}"
    if ! udevadm info -q property -p "$sys_node" 2>/dev/null | grep -Fx 'ID_USB_INTERFACE_NUM=02' >/dev/null; then
        continue
    fi

    cached=""
    if [[ -r "$cache_file" ]] && IFS= read -r cached < "$cache_file" && valid_percentage "$cached"; then
        printf 'cached %s\n' "$cached"
    fi

    if [[ -r "$device" && -w "$device" ]] && output=$(timeout 20 "$solaar" -D "$device" show mouse 2>/dev/null); then
        percentage=$(awk '$1 == "Battery:" && match($2, /^[0-9]+%/) {
            percentage = substr($2, 1, RLENGTH - 1) + 0
            found = 1
        } END { if (found) print percentage }' <<< "$output")
        if valid_percentage "$percentage"; then
            printf 'current %s\n' "$percentage"
            if [[ "$percentage" != "$cached" ]]; then
                save_percentage "$percentage" || true
            fi
            exit 0
        fi
    fi
    printf 'stale\n'
    exit 0
done
printf 'disconnected\n'
