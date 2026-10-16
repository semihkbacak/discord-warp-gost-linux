# Windows Aero demonstration and release copy

## Repository description
Discord-only WARP + GOST local proxy launcher for Windows and Linux. No system-wide DNS changes.

## YouTube title (TR)
**Discord Windows 11'de Açılıyor! | Vista Aero Kurulum Sihirbazı — WARP + GOST**

## Thumbnail text
**DISCORD AÇILDI!**

**Vista Aero • Windows 11**

**SİSTEM DNS'İ DEĞİŞMEDİ**

## Recording sequence
1. Clean Windows 11 VM and GitHub source/release, 30 sec.
2. Aero installer UI and checksums, 40 sec.
3. GOST verification and consented WARP setup, 80 sec.
4. Discord (WARP) launch and login without showing credentials, 50 sec.
5. Network settings comparison, 40 sec.
6. Reboot, launch, uninstall and verify no system DNS/proxy changes, 120 sec.
7. State limits: independent, unsigned, UDP voice/screenshare not guaranteed.

OBS recommended: 1080p, 30 fps, hide tokens and usernames.

## Draft v1.0.0 stable release notes — NOT PUBLISHED
- New Windows Vista Aero-inspired setup and status dashboard.
- App-specific Discord HTTPS proxy via GOST 127.0.0.1:40001 and WARP Local Proxy 127.0.0.1:40000.
- Pinned GOST v3.3.0 archive hash verification, opt-in WARP setup, self-uninstall and diagnostics.
- Does not directly change system-wide DNS/proxy/default route/firewall configuration.
- WebRTC/UDP, voice and screen sharing require separate validation; SmartScreen/Defender warnings must not be bypassed.

## Changelog
v0.3.0 Beta: first Windows bootstrap and GOST verification.
v0.3.1: 8.3/Unicode Windows profile path fix.
v0.3.2: WARP preparation attempts.
v0.3.3: no-console launcher, HTTPS checks, real Windows user launch confirmed.
v0.3.4: layout spacing fixes.
v1.0.0-rc1: Vista Aero UI design, expanded CI/docs. **Stable testing pending.**
