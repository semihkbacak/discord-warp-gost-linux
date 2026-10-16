# GUI Installer technical notes

- Native Debian package (`Architecture: all`) adds a standalone Tkinter GUI application.
- Installing a `.deb` through a package manager does **not** run the GUI in Debian `postinst`.
  This avoids launching untrusted graphical programs as root during package installation.
- The GUI runs as the desktop user. It asks for Cloudflare TOS acceptance before
  attempting account registration; it does not prompt for or retain Cloudflare credentials.
- Only when WARP is missing, `pkexec /usr/lib/discord-warp-gost/privileged-install warp`
  prompts for administrator authorization and installs the official signed Cloudflare
  APT package. This step modifies one package source file and its GPG keyring;
  it does not change host DNS settings.
- The program does not call `resolvectl`, edit `/etc/resolv.conf`, modify NetworkManager,
  or configure system-wide proxies. If WARP is already connected in a non-proxy
  mode the GUI refuses to switch it automatically.
- GOST v3.3.0 archives are verified against pinned GitHub SHA256 hashes before
  extracting **only** the `gost` executable into the user home directory.
- The WARP-based HTTP proxy is not a guarantee for all Discord WebRTC/UDP traffic.
- `.deb` uninstallation removes the GUI package; per-user launcher removal is
  performed by the GUI's **Kaldır** button or the `uninstall.sh` script.

Build: `./packaging/build-deb.sh dist/`
Check: `dpkg-deb --info dist/*.deb && bash tests/test.sh`

## v0.2.1 wizard transitions

- Successful uninstall now ends on the same fourth **Completed** step as installation, with a contextual **Close** button.
- Installation completion offers **Launch Discord** or **Close**.
- Failed uninstall retry repeats uninstall, not installation.
- Run `xvfb-run -a python3 tests/test_gui.py` for headless transition tests.
