# Vista Aero reference-matched UI — v1.0.0-rc4

The GUI is now visually based on the exact Vista Aero illustration approved in the conversation, instead of an imitation using WinForms gradient panels.

## Implementation

- `assets/aero-skin.png` is a **bundled artwork skin**, 864×642, including window chrome and button artwork.
- The demonstration status labels, footer statement and fake demonstration log lines were cleared from the artwork. Real component detection, operation logs and footer text are painted dynamically by `assets/Setup-GUI.ps1`.
- Each visual button has a real click target; the window can be dragged by its titlebar, minimized, closed and enlarged if space allows.
- Keyboard shortcuts: Alt+I (Install / Repair), Alt+D (Diagnose), Alt+U (Uninstall), Alt+W (Prepare WARP), Alt+O (Open Discord), Ctrl+C (copy full operation log), Escape (Close). Mouse wheel scrolls operation logs.
- The artwork creates an **Aero-inspired appearance**; it does not turn on DWM blur, Windows transparency settings or system-wide theme changes.
- The operation code uses the same working WARP/GOST scripts as the previous beta. The application version in Windows Uninstall metadata is updated.

## Before declaring stable

Real Windows checks are still needed: UI opens at common DPI settings, installer runs and re-launches Discord after reboot, uninstaller cleans up, and Defender Protection History is checked. WebRTC/voice/screen-share are separate unverified features. See `STABLE_RELEASE_CHECKLIST.md`.

The PNG preview is a *design visualization*, not evidence that Windows has rendered this build successfully.
