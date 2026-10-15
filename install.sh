#!/usr/bin/env bash
# Instala o script em ~/.local/bin e as units do systemd --user (via symlink para o repo).
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
units="$HOME/.config/systemd/user"

mkdir -p "$HOME/.local/bin" "$units"
ln -sfn "$repo/corinthians-wallpaper" "$HOME/.local/bin/corinthians-wallpaper"
for unit in "$repo"/systemd/*; do
    ln -sfn "$unit" "$units/$(basename "$unit")"
done

systemctl --user daemon-reload
systemctl --user enable --now corinthians-wallpaper.timer corinthians-wallpaper-sync.timer
systemctl --user list-timers | grep corinthians
