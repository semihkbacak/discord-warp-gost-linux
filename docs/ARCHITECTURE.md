# Architecture and design constraints

## Scope

This project automates an **already-working local proxy path** for the *Discord Flatpak desktop client*. It intentionally avoids transparent system-wide routing, DNS overrides, `/etc/hosts` hacks and DPI packet manipulation.

```text
user opens Discord (WARP)
       │
       ▼
~/.local/bin/discord-warp-gost-linux
       ├─ warp-cli settings must report "WarpProxy on port 40000"
       ├─ warp-cli connect (only if not already connected)
       ├─ systemctl --user start discord-warp-gost-linux.service
       │         │
       │         └─ discord-gost-run -> GOST :40001
       │                  ├─ HTTPS DNS resolver: 1.0.0.1/dns-query
       │                  └─ upstream: socks5://127.0.0.1:40000
       ├─ curl HTTPS probe via GOST :40001
       └─ flatpak run com.discordapp.Discord --proxy-server=http://127.0.0.1:40001
```

### Why GOST between Discord and WARP?

In the original troubleshooting session, `socks5h://127.0.0.1:40000` returned a SOCKS5 error for Discord names, while a pinned-IP connection succeeded. GOST's service-level resolver is configured to fetch DNS over HTTPS *without changing the host DNS configuration*, then forward target connections via WARP. This was sufficient for the originating user's desktop app to load. It is a diagnosis of that specific environment, not a universal explanation of all blocks or a guarantee for other ISPs.

### Isolation boundary

- **Application selection:** `--proxy-server=` applies to Discord's Chromium/Electron web networking. It is not kernel-enforced process isolation.
- **DNS:** GOST supplies the resolver for requests it handles. Other processes retain their own DNS settings. Not every native Discord subcomponent is guaranteed to honor Electron's proxy flag.
- **UDP:** SOCKS5/WARP local proxy and HTTP CONNECT do not guarantee Discord's WebRTC/UDP voice/media handling. Test independently and avoid overstating support.
- **Startup:** service not enabled at login. The launcher requests the service on demand; this service may continue running after Discord exits. To stop: `systemctl --user stop discord-warp-gost-linux.service`.
- **Fail-closed:** a WARP mode change to any non-`WarpProxy` state prevents launcher-initiated `warp-cli connect`. Already-running WARP networking is outside this project's control.
- **Existing system:** scripts never run `sudo`, modify `/etc/resolv.conf`, change `resolvectl`, alter NetworkManager or firewall rules.

### Upstream documentation

- [Cloudflare WARP modes](https://developers.cloudflare.com/warp-client/warp-modes/)
- [Cloudflare WARP Linux](https://developers.cloudflare.com/warp-client/get-started/linux/)
- [GOST v3 DNS resolver](https://v3.gost.run/en/concepts/resolver/)
- [GOST v3 proxy chaining](https://v3.gost.run/en/getting-started/quick-start/)
- [Flatpak Discord wrapper](https://github.com/flathub/com.discordapp.Discord)
