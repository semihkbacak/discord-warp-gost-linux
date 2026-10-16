# Discord WARP + GOST — Windows Vista Aero Edition

**v1.0.0 | Windows 10/11 x64 | Türkçe arayüz**

Windows'ta Discord'u yalnızca yerel WARP + GOST proxy üzerinden başlatmak için topluluk tarafından geliştirilmiş kurulum aracı. **Windows genel DNS, proxy, varsayılan ağ geçidi ve güvenlik duvarı kurallarını bu aracın kendisi değiştirmez.** Cloudflare WARP kurulumunun kendi sistem servisleri olabilir. Discord, Cloudflare veya GOST ile resmî ilişkisi yoktur.

## İndir

- **Windows `.exe` dosyası:** [GitHub Releases](https://github.com/semihkbacak/discord-warp-gost-linux/releases)
- **Linux `.deb` dosyası:** [Linux Releases](https://github.com/semihkbacak/discord-warp-gost-linux/releases) (Linux 0.2.1 için ayrı yayın planlanmıştır)

### Öne çıkan özellikler

- Windows Vista Aero esintili **Türkçe** grafik arayüz ve çalışan gerçek Windows düğmeleri.
- Resmî GOST v3.3.0 paketini **sabit SHA-256 kontrolü** ile indirip kullanıcı hesabına kurar.
- Onay verilirse Cloudflare WARP'ı Local Proxy modunda `127.0.0.1:40000` üzerinde hazırlar; başka modda etkin WARP bağlantısını sessizce değiştirmez.
- GOST `127.0.0.1:40001` üzerinden Discord HTTPS/TCP trafiğini WARP proxy'ye aktarır; diğer uygulamalar bu proxy'ye otomatik yönlendirilmez.
- Bağlantı testi, kur/onar, kaldırma ve **Discord (WARP)** başlatıcısı.

## Kurulum

1. GitHub Releases sayfasından `Discord-WARP-GOST-Setup-v1.0.0.exe` indir; yayınlanan `SHA256SUMS.txt` ile bütünlüğünü karşılaştır.
2. Windows 10/11 x64'te yükleyiciyi aç. Güvenlik uyarısı varsa **Defender'ı devre dışı bırakma**; önce tespit adını incele.
3. `Kur / Onar` ile kur, gerekirse WARP ayarları için onay ver.
4. `Bağlantı Testi` ile WARP 40000, GOST 40001 ve HTTPS erişimini doğrula.
5. `Discord'u Aç` veya masaüstündeki ayrı `Discord (WARP)` kısayolunu kullan.

## Nasıl çalışır?

```
Discord.exe (--proxy-server=http://127.0.0.1:40001)
    ↓
GOST yerel HTTP proxy (127.0.0.1:40001; DNS over HTTPS)
    ↓
Cloudflare WARP SOCKS5 Local Proxy (127.0.0.1:40000)
    ↓
Discord HTTPS/TCP sunucuları

Diğer uygulamalar → normal ağ bağlantısı
```

**Sınırlamalar:** HTTPS testi Discord'un sesli görüşme, görüntü, ekran paylaşımı ve WebRTC/UDP trafiğinin tamamının yönlendirildiğini garanti etmez. Windows SmartScreen, imzasız yeni `.exe` dosyasını uyarabilir. Bazı WARP sürümlerinde bağlantı yöntemi değişebilir. Kullanıcı testleri belirli bir Windows ortamında yapıldı; temiz VM, kaldırma, Defender ve yeniden başlatma doğrulamaları ayrı kayıt altındadır.

## Tanılama

PowerShell'de öncesi/sonrası karşılaştırması için **yalnızca okuma yapan** komutlar:

```powershell
Get-DnsClientServerAddress | Select-Object InterfaceAlias,ServerAddresses
Get-NetIPConfiguration | Select-Object InterfaceAlias,IPv4DefaultGateway
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable,ProxyServer -ErrorAction SilentlyContinue
Get-NetTCPConnection -LocalPort 40000,40001 -State Listen -ErrorAction SilentlyContinue
```

## Kaynak kod

Bu depodaki Windows dosyaları `windows/` dizinindedir. `go build -trimpath -ldflags='-H windowsgui -s -w' -o Discord-WARP-GOST-Setup-v1.0.0.exe .` komutuyla Windows x64 üzerinde derlenir. `.github/workflows/windows-aero.yml` Windows CI ve derleme artefaktını sağlar.

[Changelog](CHANGELOG.md) · [Yayın notları](docs/RELEASE_NOTES_v1.0.0.md) · [Video planı](docs/VIDEO_PLAN.md) · [Linux kalan işler](docs/LINUX_FINAL_TOUCHES.md) · [Kaynak lisansı](LICENSE)
