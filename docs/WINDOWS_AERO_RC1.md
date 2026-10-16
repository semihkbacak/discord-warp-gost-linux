# Windows Aero Edition — v1.0.0-rc1

**Status: release candidate, NOT stable.** Last observed working real Windows behavior was v0.3.3 (user reported successful Discord launch after WARP 40000 / GOST 40001 / HTTPS checks). The Vista Aero GUI redesign and full VM reboot/uninstall sequence need verification.

## What changed
- Vista Aero-inspired installer UI: glossy blue header, glass-like gradient panels, separate launcher/GOST/WARP/Discord status and improved layout.
- Preserved the previously functional per-app WARP Local Proxy / GOST connection logic.
- Windows PowerShell 5.1 parser and WinForms initialization smoke test prepared for GitHub Actions.
- GOST download continues to use pinned SHA-256, user confirmation for WARP setup and fail-closed active-VPN checks.

The Windows source must be uploaded to `windows/` and its workflow to `.github/workflows/windows-aero.yml` before CI can run. **No stable tag or release should be created yet.**

## Required real Windows checks
1. Open installer on clean Windows 11 VM; verify Vista GUI layout at 100% / 125% scaling.
2. Install verified GOST and consented WARP Local Proxy 40000.
3. Launch Discord beyond Starting; verify HTTPS/text-chat behavior.
4. Reboot Windows and launch via the shortcut.
5. Uninstall; confirm completion UI and preservation of Discord/WARP/other apps.
6. Compare DNS/default gateway/system proxy before and after.
7. Examine Windows Defender Protection History; do not disable Defender to bypass alerts.
8. Report voice, screen-share and UDP/WebRTC results separately (not guaranteed).

## Release candidate artifacts
- `Discord-WARP-GOST-Setup-v1.0.0-rc1.exe`
- `discord-warp-gost-windows-v1.0.0-rc1-source.zip`
- SHA-256 captured at source packaging time.

Once all checks pass, remove RC wording, rebuild `v1.0.0`, and publish an unsigned-stable release with explicit limitations. Any malware detection must be investigated first.

## Linux is not forgotten
Linux v0.2.1 source + matched .deb release, clean Ubuntu 24.04 VM, reboot/uninstall test and video are pending. Keep the existing Linux source in `main` untouched during Windows work.
