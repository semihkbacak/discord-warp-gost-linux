# Linux follow-up — v0.2.1 / Ubuntu verification

Windows work must not overwrite the working Linux user service or GitHub main branch.

- [ ] Push tested Linux v0.2.1 uninstall completion UI fixes to `main` (preserve the existing `packages/README.md` and `docs/VM_VIDEO_TEST.md`).
- [ ] Upload matching `discord-warp-gost-installer_0.2.1_all.deb` to `v0.2.1-beta` Release. GitHub source tree contains build scripts; .deb binaries belong in Releases.
- [ ] Create clean Ubuntu 24.04 VM, 4 CPU, 4–6 GiB RAM, 40 GiB disk; obtain package from GitHub.
- [ ] Record install → Discord start → restart → start → uninstall; test completion-screen Close button.
- [ ] Compare `resolvectl status`, `ip route` and user-scoped proxy before/after.
- [ ] OBS demo, hide account info, link to README, record UDP voice/screen share as separate unsupported/verified status.
- [ ] Only then evaluate Linux stable labeling.
