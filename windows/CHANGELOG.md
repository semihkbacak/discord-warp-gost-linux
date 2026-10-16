# Changelog

## v1.0.0 — 2026-10-16

- Windows Vista Aero temalı Türkçe kurulum yöneticisi, gerçek klavye erişimli düğmeler ve canlı durum/günlük.
- RC4 PowerShell 5.1 tırnak ayrıştırma hatası RC5'te düzeltildi; hata günlüğü oluşturuluyor.
- GOST SHA-256 doğrulamalı kurulum, WARP Local Proxy hazırlığı, Discord bağlantı testi ve kendi dosyalarını kaldırma.
- Gerçek Windows kullanıcısı RC5'te açılış/bağlantı deneyiminin çalıştığını bildirdi. Temiz VM, yeniden başlatma, Defender/SmartScreen ve WebRTC özellik testleri tüm sistemlerde doğrulanmış değildir.

## v1.0.0-rc5 (2026-10-16)

- **Fix Windows PowerShell 5.1 parser error** in `Setup-GUI.ps1` line 330: typographic U+2019 apostrophe inside a single-quoted literal was interpreted as a quote delimiter. Use an ASCII apostrophe inside a double-quoted string instead.
- Add regression check for typographic quotation marks in all PowerShell source files.
- Preserve the Turkish Aero skin, native clickable buttons, and unchanged WARP/GOST networking scripts.
- Capture stdout/stderr for actionable installer error reports.
- Windows interactive test still required.

## v1.0.0-rc4 — Türkçe Aero ve düğme tıklama düzeltmesi (stable adayı)

- Bütün görünen ana arayüz bölümleri, işlem düğmeleri, durum etiketleri ve sonuç mesajları Türkçe.
- Koordinata bağlı resim tıklama yerine her işlem için erişilebilir yerel WinForms kontrolü (10 adet).
- Fareyle tıklama, klavye Tab/Enter/Space, odak ve üzerine gelme vurgusu.
- 100% / 125% arayüz ölçeklemesi için kontroller yeniden hizalanır.
- GOST/WARP bağlantı betiklerinde işlevsel değişiklik yoktur.
- Gerçek Windows 11 kullanıcı testi yapılmadan stable olarak yayımlanmaz.

## v1.0.0-rc3 — Vista Aero reference-matched skin (not stable)

- Replaced generic WinForms gradients with a bundled UI skin based on the previously approved Vista Aero concept artwork.
- Header/world artwork, buttons, status icons, titlebar and footer now match the target image rather than approximating it.
- Dynamic true status and live operation log paint over neutralized placeholders; no sample log is shown as factual.
- Functional click zones, window drag/minimize/close, keyboard shortcuts, log scroll/copy.
- Existing GOST/WARP scripts unchanged except RC3 application version in Windows uninstall entry.
- Candidate not marked stable until real Windows GUI and Defender/end-to-end tests.

# Changelog

Changes follow a pragmatic semantic-versioning scheme. `v1.0.0-rc2` **is not a stable release**.

## [1.0.0-rc2] — 2026-10-16

### Changed
- Completely redesigned Windows installer as **Vista Aero Edition** (glossy blue header, gradient glass-inspired panels, status cards, themed buttons and dark log).
- Maintained all working WARP Local Proxy 40000 → GOST HTTP 40001 → Discord launch behavior from v0.3.4; no network command rewrites.
- More legible Turkish connection and install statuses.

### Added
- Windows native GUI initialization smoke test via `DWG_UI_SMOKE=1` in CI.
- Candidate-to-stable release criteria, documentation, Windows VM test checklist, bilingual GitHub description, video script, and Linux follow-up checklist.

### Pending before stable
- Fresh Windows 11 installer/uninstaller/reboot testing; record Defender/SmartScreen verdict.
- Discord voice/video/screenshare verification or explicit limitation.
- GitHub Actions build/status and independent artifact SHA-256 confirmation.

## [0.3.4-beta] — 2026-10-16
- Layout-only spacing changes and button labels; networking unchanged.

## [0.3.3-beta] — 2026-10-16
- Native console-free launcher; Discord launch prompts; automated WARP preparation/HTTPS proxy test. User confirmed HTTPS proxy and Discord launch on Windows.

## [0.3.2-beta] — 2026-10-16
- Initial opt-in WinGet WARP provisioning and safer fail-closed mode verification.

## [0.3.1-beta] — 2026-10-16
- Resolved Unicode/short 8.3 Windows profile path issues; improved logging.

## [0.3.0-beta] — 2026-10-16
- First Windows installer prototype; GOST SHA-256 pin and dedicated Discord launcher.

### v1.0.0-rc2 — Aero visual regression fix
- Clear rounded panel and button corners to avoid black artifacts.
- Feather hard-edged glossy highlights.
- Put the component heading and footer controls inside their panels to avoid painting over them.
- Remove conflicting form minimum size; add visual parent/bounds smoke checks.
- No changes to WARP/GOST/Discord networking or install/remove logic.
