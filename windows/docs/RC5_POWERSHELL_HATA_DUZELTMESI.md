# RC5 - PowerShell 5.1 açılış hatası düzeltmesi

Kullanıcının Windows tanılama raporu: `Setup-GUI.ps1:330 char:76`, uygulama `exit status 1` ile kapanıyordu.

**Kök neden:** `Discord’u` içindeki Unicode U+2019 kıvrımlı kesme işareti, PowerShell tarafından tek tırnak ayırıcı olarak yorumlanıyordu. Böylece 330. satırdaki tek tırnaklı dize erken kapanıyor ve dosya ayrıştırılamıyordu.

**Düzeltme:** `Kurulum tamamlandı. Discord'u açarak doğrulayın.` metni çift tırnaklı bir PowerShell dizesine taşındı; .ps1 dosyalarında kıvrımlı tırnak kullanımını yakalayan regresyon kontrolü eklendi.

**Ek tanılama:** Başlatıcı gerçek PowerShell hata çıktısını `%TEMP%\discord-warp-setup-error.txt` konumuna kaydeder. Önceki rapor açılıştan önce silinir; yeni rapor `showError` tarafından ezilmez.

**Çalıştırılan statik testler:** `python tests/check_source.py`, `check_reference_skin.py`, `check_aero_layout.py`, `check_powershell_typographic_quotes.py`, Windows x64 Go derlemesi.

**Windows ortamında çalıştırılacak kontrol:**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\parse_powershell_51.ps1
$env:DWG_UI_SMOKE='1'
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\assets\Setup-GUI.ps1
```

Bu kontroller gerçek Windows'ta yapılmadıkça **RC5 stable olarak yayımlanamaz**. Sistem DNS, Windows genel proxy ve güvenlik duvarı ayarları değiştirilmez.
