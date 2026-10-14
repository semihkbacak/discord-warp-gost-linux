# Discord WARP + GOST for Linux

Per-application Discord launch helper built on the **Cloudflare WARP local proxy** and **GOST v3**. It is not a stand-alone DPI bypass engine, and it does not change system DNS, NetworkManager, `/etc/resolv.conf`, or firewall settings.

## Network path

```text
Discord Flatpak -> HTTP 127.0.0.1:40001 (GOST; DoH resolver)
                -> SOCKS5 127.0.0.1:40000 (WARP Local Proxy)
                -> Discord HTTPS
Other applications -> their regular connection (unless configured independently)
```

This is a community project, unaffiliated with Discord, Cloudflare, or GOST. It primarily proxies TCP/HTTPS; WebRTC and UDP voice/video behavior is **not guaranteed** across systems. The initial setup was observed working on one Ubuntu desktop, but this repository has not been tested across Linux distributions.

## Requirements

- Flatpak and `com.discordapp.Discord`: `flatpak install flathub com.discordapp.Discord`
- Official Cloudflare WARP Linux CLI: [installation documentation](https://developers.cloudflare.com/warp-client/get-started/linux/)
- GOST v3 binary: [verified upstream releases](https://github.com/go-gost/gost/releases) (place executable at `~/.local/bin/gost` or on PATH)
- `curl`, `systemd --user`

Configure WARP's **proxy** mode before installing:

```bash
warp-cli registration new   # only for first-time registration
warp-cli mode proxy
warp-cli proxy port 40000
warp-cli settings           # verify: WarpProxy on port 40000
```

Do not use full-device `warp`/`warp+doh` modes for this project. The launcher checks the mode and refuses to run in other modes.

## Install and run

Download or clone this repository, then from its root:

```bash
./install.sh
~/.local/bin/discord-warp-gost-linux
```

No `sudo` needed. Installation registers a user-level GOST systemd service and a separate **Discord (WARP)** menu entry / desktop shortcut (where a Desktop directory exists), without overwriting the official Flatpak desktop file. The launcher checks WARP mode, connects WARP if needed, starts GOST, tests HTTPS over the full proxy path, and launches Discord with a proxy flag.

## Diagnose

```bash
./doctor.sh
warp-cli status
warp-cli settings
systemctl --user status discord-warp-gost-linux.service
journalctl --user -u discord-warp-gost-linux.service -n 50 --no-pager
```

To test the chain after starting it:

```bash
curl -I --max-time 20 -x http://127.0.0.1:40001 https://discordapp.com/app
```

HTTP 301 is expected for the redirect to `discord.com`.

## Uninstall

```bash
./uninstall.sh
```

Removes only project-owned user scripts, service and shortcuts. Leaves Discord, WARP, GOST, system DNS, NetworkManager and firewall settings unchanged. To stop WARP separately: `warp-cli disconnect`.

## Limitations and security

- Loopback-only proxy listeners, not reachable from LAN by default.
- With the CLI install path, upstream binaries are installed manually; with the GUI wizard, GOST v3.3.0 is downloaded from official GitHub releases and its SHA-256 is verified against a pinned digest.
- No account keys, registration data, browser profiles or DNS configuration files belong in this repository.
- WARP traffic follows Cloudflare's data practices and terms.
- WebRTC/UDP voice/video may bypass or fail with an HTTP proxy, even when Discord login and messages work.
- Check local laws, policies and service terms where applicable.

Full architecture: [ARCHITECTURE.md](ARCHITECTURE.md). License: [MIT](../LICENSE), for original project files only.

## Native Ubuntu GUI installer (`.deb`)

The `discord-warp-gost-installer_0.2.0_all.deb` package provides a Windows-style
step-by-step graphical setup wizard. Double-click the `.deb` and install it through
Ubuntu App Center or GDebi, then launch **Discord WARP Setup** from the application
menu. The wizard checks dependencies, obtains your explicit acceptance of Cloudflare
terms, downloads and SHA-256 verifies GOST, installs Discord Flatpak if missing,
and creates a separate **Discord (WARP)** launcher.

Administrative authorization is requested only when the official Cloudflare WARP
APT package needs to be installed; this also adds the signed Cloudflare APT source.
It never modifies the system DNS configuration. The wizard refuses to switch modes
if WARP is already connected in a non-proxy mode. A repair/diagnostic and uninstall
path is included. Removing the user launcher deliberately leaves third-party WARP,
GOST and Discord packages intact. For source builds use `./packaging/build-deb.sh`.

The manual shell installation documented above continues to work without the GUI.
