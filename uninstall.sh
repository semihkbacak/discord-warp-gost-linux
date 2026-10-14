#!/usr/bin/env bash
# Managed by discord-warp-gost-linux
set -euo pipefail

[[ "$(id -u)" != 0 ]] || { echo 'sudo kullanmayın.' >&2; exit 1; }
app_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
user_units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

systemctl --user stop discord-warp-gost-linux.service >/dev/null 2>&1 || true
systemctl --user disable discord-warp-gost-linux.service >/dev/null 2>&1 || true

remove_owned() {
    local target="$1" marker="$2"
    if [[ -f "$target" ]] && grep -Fq "$marker" "$target"; then
        rm -- "$target"
        printf '[uninstall] Kaldırıldı: %s\n' "$target"
    fi
}
remove_owned "$HOME/.local/bin/discord-warp-gost-linux" 'Managed by discord-warp-gost-linux'
remove_owned "$HOME/.local/bin/discord-warp-gost-run" 'Managed by discord-warp-gost-linux'
remove_owned "$user_units/discord-warp-gost-linux.service" 'Managed by discord-warp-gost-linux'
remove_owned "$app_dir/discord-warp-gost.desktop" 'X-Discord-Warp-Gost=true'

desktop_dir=''
if command -v xdg-user-dir >/dev/null 2>&1; then
    desktop_dir="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
fi
[[ -n "$desktop_dir" ]] || desktop_dir="$HOME/Desktop"
remove_owned "$desktop_dir/Discord (WARP).desktop" 'X-Discord-Warp-Gost=true'
systemctl --user daemon-reload
printf '\n[uninstall] Tamamlandı. Discord, WARP, GOST ve sistem DNS ayarlarına dokunulmadı.\n'
printf '[uninstall] İsterseniz WARP proxy bağlantısını ayrıca kapatın: warp-cli disconnect\n'
