#!/usr/bin/env bash
set -euo pipefail
umask 077

fail() {
    printf '%s\n' "$1" >&2
    notify-send --urgency=normal '随机壁纸' "$1" || true
    exit 1
}

api_url='https://t.alcy.cc/pc/'
if ! current_wallpaper=$(dms ipc call wallpaper get); then
    fail '无法连接 Dux 壁纸服务。'
fi

case "$current_wallpaper" in
    /*) wallpaper_dir=${current_wallpaper%/*}; wallpaper_dir=${wallpaper_dir:-/} ;;
    ERROR:*) fail "$current_wallpaper" ;;
    *) wallpaper_dir="$HOME/.background" ;;
esac

temp_dir=$(mktemp -d -- "$wallpaper_dir/.alcy.XXXXXXXX") || fail '无法写入 Dux 壁纸目录。'
trap 'rm -f -- "$temp_dir/source" "$temp_dir/wallpaper.png"; rmdir -- "$temp_dir"' EXIT

if ! curl --fail --location --silent --show-error --connect-timeout 10 --max-time 120 \
    --output "$temp_dir/source" "$api_url"; then
    fail '栗次元壁纸下载失败。'
fi

if ! magick "$temp_dir/source[0]" "$temp_dir/wallpaper.png"; then
    fail '栗次元返回的图片无法解码。'
fi

wallpaper_path="$wallpaper_dir/alcy-$(date +%Y%m%d-%H%M%S)-${temp_dir##*.}.png"
mv -- "$temp_dir/wallpaper.png" "$wallpaper_path" || fail '无法保存下载的壁纸。'

if ! result=$(dms ipc call wallpaper set "$wallpaper_path") || [[ $result != SUCCESS:* ]]; then
    fail '壁纸已下载，但 Dux 未能应用。'
fi

printf '%s\n' "$wallpaper_path"
