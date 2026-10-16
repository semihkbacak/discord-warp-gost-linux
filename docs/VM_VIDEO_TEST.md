# Clean VM beta test and installation video

This checklist is for a **clean Ubuntu 24.04 LTS guest**. Test v0.2.1 Beta only after publishing that exact source version and its matching `.deb` release.

## Prepare the VM

Use GNOME Boxes with **4 vCPU, 4-6 GiB RAM, and 35-40 GiB virtual disk**, if the host has sufficient resources. Prefer NAT networking. Use an unmodified official Ubuntu desktop ISO.

Keep the host's working Discord configuration untouched. The VM is an independent sandbox, though network access, microphone passthrough and GPU acceleration can differ from real hardware.

1. Install Ubuntu inside the VM and update essential packages.
2. Before installing the app, confirm that Discord, GOST and WARP are not already present.
3. Capture baseline networking output with `resolvectl status`, `ip route`, and `env | grep -i proxy`; do **not** publish private/local network identifiers in the video.
4. Record the VM's starting snapshot/state or recreate the VM before each complete test.

## Record the installation

Use OBS **on the host** and capture the Boxes window. For an upload-friendly video, use 1920x1080, 30 fps, and hide account login, notifications, tokens and personal identifiers.

Suggested scene sequence:

| Time | Scene | Verification |
| --- | --- | --- |
| 00:00-00:20 | Title, project and version | Show the GitHub repository and v0.2.1 Beta Release |
| 00:20-00:45 | Clean Ubuntu VM | Show no Discord/WARP installation |
| 00:45-01:15 | Download the .deb from Releases | Verify downloaded filename/version |
| 01:15-02:15 | Open setup wizard, accept terms, install | Progress, dependency checks, success page |
| 02:15-03:00 | Launch Discord (WARP) | Confirm actual Discord login screen; protect personal data |
| 03:00-03:30 | Browser and DNS isolation | Compare `resolvectl status` and `ip route` before/after |
| 03:30-04:00 | Restart guest and launch using desktop icon | Demonstrate persistence |
| 04:00-04:45 | Uninstall wizard | Confirm 'Kaldırma tamamlandı' and 'Kapat' |
| 04:45-05:00 | Close / credits | Show release link and known limitations |

## Acceptance criteria

- Package installation completes without editing system DNS or default route.
- Setup wizard can install, launch, uninstall and close without getting stuck.
- After a VM reboot, the custom desktop launcher opens Discord.
- Normal websites open outside the proxy.
- The user-scoped proxy only listens on `127.0.0.1` at the configured ports.
- Voice chat / WebRTC / screen-share are **not claimed as guaranteed** based on an HTTPS login test; record these results separately.
- If WARP registration or tunnel fails in a VM network, document the error rather than presenting that run as a successful complete install.

## Windows later

Reproduce the same clean-VM test on Windows 11 once a Windows installer exists. Do not present the Linux `.deb` as a Windows package. The Windows implementation will need its own per-app routing and UDP/WebRTC validation.

After editing the README to link a real published video, upload a short captioned demonstration to your preferred video platform. Do not commit large video binaries into Git source history.
