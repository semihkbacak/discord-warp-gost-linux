#!/usr/bin/env bash
# Unit tests intentionally fake warp-cli / systemctl / flatpak / curl.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export MOCK_LOG="$tmp/calls.log" MOCK_WARP_MODE='proxy'
mkdir -p "$HOME/.local/bin" "$tmp/mocks" "$HOME/Desktop"
: > "$MOCK_LOG"

cat > "$tmp/mocks/warp-cli" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
    settings)
        if [[ "${MOCK_WARP_MODE:-proxy}" == proxy ]]; then
            echo '(user set) Mode: WarpProxy on port 40000'
        else
            echo '(user set) Mode: WarpWithDns'
        fi
        ;;
    status) echo 'Status update: Connected' ;;
    connect) echo 'warp-connect' >> "$MOCK_LOG" ;;
    *) exit 1 ;;
esac
SH
cat > "$tmp/mocks/flatpak" <<'SH'
#!/usr/bin/env bash
echo "flatpak $*" >> "$MOCK_LOG"
case "${1:-}" in
    info|run) exit 0 ;;
    *) exit 1 ;;
esac
SH
cat > "$tmp/mocks/systemctl" <<'SH'
#!/usr/bin/env bash
echo "systemctl $*" >> "$MOCK_LOG"
exit 0
SH
cat > "$tmp/mocks/curl" <<'SH'
#!/usr/bin/env bash
echo "curl $*" >> "$MOCK_LOG"
exit 0
SH
cat > "$tmp/mocks/gio" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat > "$tmp/mocks/xdg-user-dir" <<'SH'
#!/usr/bin/env bash
echo "$HOME/Desktop"
SH
cat > "$tmp/mocks/id" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == '-u' ]]; then echo 1000; else /usr/bin/id "$@"; fi
SH
cat > "$HOME/.local/bin/gost" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$tmp/mocks/"* "$HOME/.local/bin/gost"
export PATH="$tmp/mocks:$PATH"

"$root/install.sh"
test -x "$HOME/.local/bin/discord-warp-gost-linux"
test -f "$HOME/.config/systemd/user/discord-warp-gost-linux.service"
test -f "$HOME/.local/share/applications/discord-warp-gost.desktop"
grep -Fq 'Exec="' "$HOME/.local/share/applications/discord-warp-gost.desktop"

# Healthy mode: expected only the Discord flatpak process receives proxy flag.
: > "$MOCK_LOG"
"$HOME/.local/bin/discord-warp-gost-linux" >/dev/null
grep -Fq 'flatpak run com.discordapp.Discord --proxy-server=http://127.0.0.1:40001' "$MOCK_LOG"
if grep -Fq 'systemctl --user start discord-warp-gost-linux.service' "$MOCK_LOG"; then
  echo 'Unexpected new GOST service start when an existing proxy works' >&2
  exit 1
fi
if grep -Fq 'warp-connect' "$MOCK_LOG"; then
    echo 'Connected mode unexpectedly called warp-cli connect' >&2
    exit 1
fi

# Wrong WARP mode must NOT connect or run Discord.
: > "$MOCK_LOG"
export MOCK_WARP_MODE='warp'
if "$HOME/.local/bin/discord-warp-gost-linux" >/dev/null 2>&1; then
    echo 'Non-proxy WARP mode should be rejected' >&2
    exit 1
fi
if grep -Eq 'flatpak run|warp-connect' "$MOCK_LOG"; then
    echo 'Non-proxy WARP mode was not rejected safely' >&2
    exit 1
fi

"$root/uninstall.sh"
test ! -e "$HOME/.local/bin/discord-warp-gost-linux"
test ! -e "$HOME/.local/share/applications/discord-warp-gost.desktop"
test -x "$HOME/.local/bin/gost"  # Upstream executable untouched.

echo 'PASS: install, launcher, wrong-mode safety, uninstall'
