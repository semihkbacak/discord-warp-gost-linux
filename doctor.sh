#!/usr/bin/env bash
# Managed by discord-warp-gost-linux
set -uo pipefail

ok()   { printf '[ OK ] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }

for cmd in warp-cli flatpak curl systemctl; do
    if command -v "$cmd" >/dev/null 2>&1; then ok "$cmd bulundu"; else warn "$cmd eksik"; fi
done
if [[ -x "$HOME/.local/bin/gost" ]] || command -v gost >/dev/null 2>&1; then
    ok 'GOST bulundu'
else
    warn 'GOST bulunamadı'
fi
if flatpak info com.discordapp.Discord >/dev/null 2>&1; then ok 'Discord Flatpak kurulu'; else warn 'Discord Flatpak yok'; fi

if warp-cli settings 2>/dev/null | grep -Fq 'Mode: WarpProxy on port 40000'; then
    ok 'WARP proxy modu ve port 40000 doğru'
else
    warn 'WARP doğru Local Proxy modunda değil. Otomatik bağlanma güvenlik için engellenir.'
fi
if warp-cli status 2>/dev/null | grep -Fq 'Status update: Connected'; then
    ok 'WARP bağlı'
else
    warn 'WARP bağlı değil'
fi
if systemctl --user is-active --quiet discord-warp-gost-linux.service; then
    ok 'GOST servisi aktif'
else
    warn 'Projenin GOST servisi aktif değil (başka bir çalışan proxy yeniden kullanılabilir)'
fi
if curl --silent --show-error --fail --head --max-time 12 \
    --proxy http://127.0.0.1:40001 'https://discordapp.com/app' >/dev/null 2>&1; then
    ok 'Discord HTTPS testi GOST+WARP üzerinden başarılı'
else
    warn 'Discord HTTPS testi başarısız. Discord açık değilse önce başlatın.'
fi
printf '\nTanılama: journalctl --user -u discord-warp-gost-linux.service -n 50 --no-pager\n'
printf 'Sistem DNS ayarları bu test sırasında değiştirilmez.\n'
