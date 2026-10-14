#!/usr/bin/env bash
# Managed by discord-warp-gost-linux
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
app_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
user_units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/discord-warp-gost-linux"

log() { printf '[installer] %s\n' "$*"; }
fail() { printf '[installer] HATA: %s\n' "$*" >&2; exit 1; }

[[ "$(id -u)" != 0 ]] || fail 'Bu kurulumu sudo/root ile çalıştırmayın.'
for dep in warp-cli flatpak curl systemctl; do
    command -v "$dep" >/dev/null 2>&1 || fail "Eksik uygulama: $dep (README.md: prerequisites)"
done
if [[ ! -x "$HOME/.local/bin/gost" ]] && ! command -v gost >/dev/null 2>&1; then
    fail 'GOST bulunamadı. Resmî sürümden gost ikilisini ~/.local/bin/gost konumuna yükleyin.'
fi
flatpak info com.discordapp.Discord >/dev/null 2>&1 || fail 'Discord Flatpak kurulu değil.'

if ! warp-cli settings 2>/dev/null | grep -Fq 'Mode: WarpProxy on port 40000'; then
    fail 'Önce WARP Local Proxy ayarını yapın: warp-cli mode proxy; warp-cli proxy port 40000'
fi

# Check potential desktop-entry conflicts *before* writing installed files.
menu_shortcut="$app_dir/discord-warp-gost.desktop"
if [[ -e "$menu_shortcut" ]] && ! grep -Fq 'X-Discord-Warp-Gost=true' "$menu_shortcut"; then
    fail "$menu_shortcut var ve bu projeye ait değil. Dosya korunuyor."
fi

mkdir -p "$HOME/.local/bin" "$app_dir" "$user_units" "$state_dir"
install -m 755 "$root/bin/discord-warp" "$HOME/.local/bin/discord-warp-gost-linux"
install -m 755 "$root/bin/discord-gost-run" "$HOME/.local/bin/discord-warp-gost-run"
install -m 644 "$root/systemd/discord-gost.service" "$user_units/discord-warp-gost-linux.service"

# A NEW app ID is safer than overwriting the official Flatpak launcher.
cat > "$menu_shortcut" <<DESKTOP
[Desktop Entry]
Type=Application
Version=1.0
Name=Discord (WARP)
Comment=Discord through a local WARP + GOST proxy
Exec="$HOME/.local/bin/discord-warp-gost-linux" %U
Icon=com.discordapp.Discord
Terminal=false
Categories=Network;InstantMessaging;Chat;
StartupWMClass=discord
MimeType=x-scheme-handler/discord;
X-Discord-Warp-Gost=true
DESKTOP
chmod 644 "$menu_shortcut"

# Desktop shortcuts are optional and should never create a new, unused ~/Desktop.
desktop_dir=''
if command -v xdg-user-dir >/dev/null 2>&1; then
    desktop_dir="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
fi
if [[ -z "$desktop_dir" ]]; then desktop_dir="$HOME/Desktop"; fi
if [[ -d "$desktop_dir" ]]; then
    desktop_shortcut="$desktop_dir/Discord (WARP).desktop"
    if [[ ! -e "$desktop_shortcut" ]] || grep -Fq 'X-Discord-Warp-Gost=true' "$desktop_shortcut"; then
        cp "$menu_shortcut" "$desktop_shortcut"
        chmod +x "$desktop_shortcut"
        if command -v gio >/dev/null 2>&1; then
            gio set "$desktop_shortcut" metadata::trusted true 2>/dev/null || true
        fi
        log "Masaüstü kısayolu: $desktop_shortcut"
    else
        log 'Mevcut yabancı masaüstü kısayoluna dokunulmadı.'
    fi
fi

systemctl --user daemon-reload
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$app_dir" >/dev/null 2>&1 || true
fi
log 'Kurulum tamamlandı. Discord (WARP) simgesinden veya ~/.local/bin/discord-warp-gost-linux ile başlatın.'
log 'Genel DNS, /etc/resolv.conf, NetworkManager veya root firewall kuralları değiştirilmedi.'
