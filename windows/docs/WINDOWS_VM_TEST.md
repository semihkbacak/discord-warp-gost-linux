# Windows 11 clean VM test checklist

Build ID: **v0.3.1-beta, unsigned; v0.3.0 was host-tested with a path error and a Defender warning**.

1. VM: Windows 11 64-bit, at least 4 vCPU, 6 GiB RAM, 60 GiB disk, NAT networking. Take a snapshot before install.
2. Record *before*: `Get-DnsClientServerAddress`, `Get-NetRoute -DestinationPrefix '0.0.0.0/0'`, `netsh winhttp show proxy`, `Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' | Select-Object ProxyEnable,ProxyServer`.
3. Run the .exe with a normal Windows account. **Kur / Onar** should get `gost.exe` with SHA256 validation and make shortcuts; missing WARP and Discord should be warnings, not fake success.
4. Install WARP and Discord from official websites. In WARP, configure local proxy at 40000. Verify `warp-cli settings` explicitly shows `WarpProxy on port 40000` (the exact output may vary by release). Never enable full-tunnel WARP for this test.
5. Close Discord completely from system tray and run **Discord (WARP)**. Confirm port 40001 is listening, HTTPS proxy test succeeds, and Discord login loads. Record exactly which features work.
6. In browser/Steam/Netflix/Prime Video verify they don't use Discord's local proxy. Compare the above before/after network snapshots; note any differences due to installing official WARP itself.
7. Reboot guest; launch Discord (WARP). Confirm button and desktop shortcut still work.
8. Click **Kaldir** in wizard: verify completion screen **Kaldirma tamamlandi** with **Kapat**; shortcuts and own GOST removed but WARP/Discord remain.
9. Test manual cancel + retries after disconnecting WARP, a busy port 40001, failed GOST download. Do not hide these from beta logs.
10. Capture short OBS video (1080p30) from the host; ensure no login tokens, personal info or messages appear.

No change to system-wide DNS or global proxy is permitted by this app; WARP's own installer and GUI are separate third-party actions.

Known UDP/WebRTC limitation: text and login success do **not** prove voice or screen-share.
