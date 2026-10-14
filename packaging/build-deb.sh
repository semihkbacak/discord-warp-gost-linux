#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$root/dist}"
mkdir -p "$out"
out="$(realpath "$out")"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
pkg='discord-warp-gost-installer'
version='0.2.0'
mkdir -p "$stage/DEBIAN" "$stage/usr/share/discord-warp-gost-linux" \
    "$stage/usr/lib/discord-warp-gost" "$stage/usr/bin" \
    "$stage/usr/share/applications" "$stage/usr/share/doc/$pkg"
cat > "$stage/DEBIAN/control" <<EOF
Package: $pkg
Version: $version
Architecture: all
Maintainer: Discord WARP GOST Linux Community <maintainers@users.noreply.github.com>
Depends: python3 (>= 3.10), python3-tk, flatpak, curl, ca-certificates, pkexec, xdg-user-dirs, systemd
Section: net
Priority: optional
Description: GUI setup wizard for Discord-only Cloudflare WARP and GOST on Ubuntu
 Installs a per-user Discord proxy launcher with GOST DNS-over-HTTPS
 resolution and Cloudflare WARP local proxy mode. Does not edit host DNS.
EOF
# This is a normal application package. Do not run untrusted installers in postinst.
cp -a "$root/bin" "$root/systemd" "$root/gui" "$stage/usr/share/discord-warp-gost-linux/"
cp "$root/install.sh" "$root/uninstall.sh" "$root/doctor.sh" "$stage/usr/share/discord-warp-gost-linux/"
cp "$root/README.md" "$stage/usr/share/doc/$pkg/README.md"
cp "$root/LICENSE" "$stage/usr/share/doc/$pkg/copyright"
install -m755 "$root/gui/privileged-install" "$stage/usr/lib/discord-warp-gost/privileged-install"
cat > "$stage/usr/bin/discord-warp-setup" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/python3 /usr/share/discord-warp-gost-linux/gui/installer.py "$@"
EOF
chmod 755 "$stage/usr/bin/discord-warp-setup"
cat > "$stage/usr/share/applications/discord-warp-setup.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Discord WARP Setup
Name[tr]=Discord WARP Kurulum Sihirbazı
Comment=Install, repair or remove Discord-only WARP proxy
Exec=discord-warp-setup
Icon=network-workgroup
Terminal=false
Categories=Network;Utility;
EOF
find "$stage/usr/share/discord-warp-gost-linux" -type d -name __pycache__ -prune -exec rm -rf {} +
find "$stage" -type f -name '*.pyc' -delete
chmod 755 "$stage/usr/share/discord-warp-gost-linux/bin/"* \
          "$stage/usr/share/discord-warp-gost-linux/"*.sh
chmod 644 "$stage/usr/share/discord-warp-gost-linux/systemd/"*
chmod 755 "$stage/usr/share/discord-warp-gost-linux/gui/privileged-install"
dpkg-deb --build --root-owner-group "$stage" "$out/${pkg}_${version}_all.deb" >/dev/null
printf '%s\n' "$out/${pkg}_${version}_all.deb"
