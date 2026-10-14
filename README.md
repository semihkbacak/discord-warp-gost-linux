# Discord WARP + GOST (Linux)

**Discord'a özel yerel proxy başlatıcısı — sistem genelindeki DNS ayarlarına dokunmadan.**

> 🇹🇷 Türkçe kurulum rehberi aşağıdadır. [English guide](docs/README.en.md).
>
> Community project. Not affiliated with Discord, Cloudflare, or the GOST maintainers.

## Ne yapar?

```text
Discord Flatpak  ──HTTP proxy──>  GOST 127.0.0.1:40001
                                     │
                              Şifreli DNS (DoH)
                                     │
                             SOCKS5 127.0.0.1:40000
                                     │
                              Cloudflare WARP
                                     │
                               Discord HTTPS

Chrome / Steam / diğer uygulamalar ──> normal internet bağlantısı
```

- Yalnızca **Discord (WARP)** başlatıcısı GOST HTTP proxy'yi kullanır.
- GOST hedef alan adlarını şifreli DNS (DoH) ile çözer ve bağlantıyı yerel WARP SOCKS5 proxy'ye aktarır.
- `systemd --user` servisi Discord başlatılırken GOST'u gerektiğinde açar.
- **`resolvectl`, `/etc/resolv.conf`, NetworkManager, root firewall ayarları değiştirilmez.**
- WARP'ın `WarpProxy on port 40000` modunda olduğunu denetler ve diğer WARP modlarında çalışmayı reddeder.
- Orijinal Discord Flatpak kısayolu korunur; ayrı **Discord (WARP)** kısayolu oluşturulur.

**Sınır:** Bu yöntem öncelikle Discord'un HTTPS/TCP trafiğini proxy'ler. Discord'un WebRTC/UDP ses, görüntü ve ekran paylaşımı bağlantılarının tümünün proxy'den geçtiği iddia edilmez. İlk geliştirici sisteminde Discord açıldı; özelliklerin diğer ağlarda çalışması ayrıca test edilmelidir. WARP bir VPN/tünel servisidir; buradaki yapı onun *Local Proxy* modunu kullanır. Bu bir bağımsız DPI motoru değildir.

## Gereksinimler

- Linux masaüstü (Ubuntu + GNOME/Wayland ve x86_64 üzerinde denenmiş akış)
- `flatpak`, Discord'un `com.discordapp.Discord` paketi
- Cloudflare WARP Linux CLI (`warp-cli`)
- [GOST v3](https://github.com/go-gost/gost/releases) (`gost` çalıştırılabilir dosyası)
- `curl`, `systemd --user`

### Bağımlılıkların hazırlanması

**Discord Flatpak:**

```bash
flatpak install flathub com.discordapp.Discord
```

**Cloudflare WARP:** [Resmî Linux kurulum rehberi](https://developers.cloudflare.com/warp-client/get-started/linux/) üzerinden uygun paketi kurun. Ardından yalnızca *Local Proxy* modunu kullanın:

```bash
warp-cli registration new   # yalnızca ilk kayıtta
warp-cli mode proxy
warp-cli proxy port 40000
warp-cli settings           # Mode: WarpProxy on port 40000 beklenir
```

**DİKKAT:** `warp-cli mode warp` veya `warp+doh` kullanmayın; bunlar bu projenin Discord'a özel bağlantı hedefiyle uyuşmaz. Uygulama başka moda geçerse başlatıcı bağlantı açmayı reddeder.

**GOST:** [Resmî GitHub Releases](https://github.com/go-gost/gost/releases) sayfasından Linux mimarinize uygun GOST **v3** arşivini seçin, yayınlanan `checksums.txt` ile SHA-256 değerini doğrulayın. Arşivdeki `gost` ikilisini `~/.local/bin/gost` konumuna kurun (`chmod +x ~/.local/bin/gost`). Proje WARP/GOST ikililerini indirmez, değiştirmez veya yeniden dağıtmaz.

## Kurulum

Projeyi ZIP'ten çıkartın veya GitHub'a yayımlandıktan sonra `git clone` ile edinin. Proje dizininde:

```bash
chmod +x install.sh uninstall.sh doctor.sh
./install.sh
```

**sudo kullanmayın.** Kurulum kullanıcı dizinlerine dosya yazar, GOST'u kullanıcı servisi olarak tanımlar ve **Discord (WARP)** kısayolu oluşturur. Var olan orijinal `com.discordapp.Discord.desktop` dosyasının üzerine yazmaz.

Başlatmak için uygulama menüsünden **Discord (WARP)** seçin veya masaüstünüzde oluşturulan **Discord (WARP)** simgesini çift tıklayın. Terminalden:

```bash
~/.local/bin/discord-warp-gost-linux
```

Başlatıcı bağlantı gerektiğinde `warp-cli connect` çalıştırır **ancak önce yalnızca WarpProxy modunu doğrular**. Ardından GOST'u açar, Discord'a HTTPS erişimini test eder ve Discord Flatpak'ı proxy parametresiyle başlatır.

## Kontrol / hata ayıklama

```bash
./doctor.sh
warp-cli settings
warp-cli status
systemctl --user status discord-warp-gost-linux.service
journalctl --user -u discord-warp-gost-linux.service -n 50 --no-pager
```

El ile HTTP proxy testi (GOST çalışıyorsa):

```bash
curl -I --max-time 20 -x http://127.0.0.1:40001 https://discordapp.com/app
```

`HTTP 301` normaldir: `discordapp.com` -> `discord.com` yönlendirmesidir.

| Belirti | Kontrol |
| --- | --- |
| `ERR_PROXY_CONNECTION_FAILED` | WARP ve GOST aktif mi? `warp-cli status` / `systemctl --user status ...` |
| `SOCKS5 error 4` | WARP'ın hedef adı çözümleyememesi ihtimali; GOST DoH proxy'sini kullanın |
| Başlatıcı sessizce kapanıyor | `~/.local/bin/discord-warp-gost-linux` komutunu terminalden çalıştırın; `./doctor.sh` |
| WARP yanlış modda | `warp-cli mode proxy` ve `warp-cli proxy port 40000`; önce `warp-cli settings` doğrulayın |
| Sesli kanal bağlanmıyor | WebRTC/UDP trafiği HTTP proxy ile garanti edilmez; ağ bazında ayrıca test gerekir |

## Kaldırma

```bash
./uninstall.sh
```

Sadece bu projenin kullanıcı betiklerini, servisini ve **Discord (WARP)** kısayollarını siler. **Orijinal Discord, GOST ikilisi, WARP paketi ve genel DNS ayarları korunur.** WARP proxy'yi ayrıca kesmek isterseniz:

```bash
warp-cli disconnect
```

## Güvenlik ve gizlilik

- Proxy'ler yalnızca `127.0.0.1` dinler; LAN/İnternet'e açık port oluşturulmaz.
- Başlatıcı şifre, WARP kayıt dosyası, abonelik anahtarı veya trafik günlüğü toplamaz.
- Kullanıcı hangi uygulamayı proxy üzerinden yönlendireceğini belirler; sistem genelinde otomatik yönlendirme yapılmaz.
- Cloudflare'a yönlendirilen bağlantı ve DNS verileri için Cloudflare'ın gizlilik politikası geçerlidir.
- WARP, Discord ve GOST farklı üreticilere aittir; onların lisans ve koşullarına uyulmalıdır.
- Bazı ülke/ağlarda erişim kısıtlamaları bulunabilir; yürürlükteki kuralları kontrol edin.

## Geliştirme

```bash
bash -n install.sh uninstall.sh doctor.sh bin/* tests/test.sh
bash tests/test.sh
```

CI, betiklerin sözdizimi ve temel davranışlarını gerçek WARP bağlantısı açmadan sınar. Ağ testleri kullanıcı sisteminde yapılmalıdır.

Detaylı mimari: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · [English](docs/README.en.md)

## Lisans

MIT — [LICENSE](LICENSE). Bu lisans yalnızca bu depodaki özgün betikler ve belgeler içindir; Discord, WARP ve GOST ikililerini kapsamaz.

## GitHub'da yayımlama

Depo oluşturma ve GitHub CLI ile gönderme adımları: [docs/PUBLISHING.md](docs/PUBLISHING.md).

## Tek tıkla başlayan grafik kurulum (Ubuntu `.deb`)

Windows kurulum sihirbazına benzer bir arayüz kullanmak için **Releases** bölümündeki
`discord-warp-gost-installer_0.2.0_all.deb` dosyasını indirin ve **çift tıklayın**.
Ubuntu App Center veya GDebi üzerinden **Yükle** seçeneğini kullanın (gerekirse
sistem yöneticisi şifresi istenir). Sonra uygulama menüsündeki **Discord WARP
Kurulum Sihirbazı** uygulamasını açın, Cloudflare koşullarını inceleyip **Yükle**
seçeneğine basın.

Sihirbaz şunları yapar:

1. Gerekli yazılımları kontrol eder. WARP eksikse **yalnızca bu adım** için
   `pkexec` yoluyla yöneticiden izin isteyip resmî Cloudflare APT deposunu ekler.
2. GOST v3.3.0'ı resmî GitHub sürümünden indirir, mimariye göre sabit SHA-256
   değeriyle kontrol eder ve kullanıcının `~/.local/bin` dizinine kurar.
3. Discord Flatpak kurulu değilse Flathub kullanıcı deposundan kurar.
4. Cloudflare şartlarını kullanıcının kabulünün ardından WARP kaydını hazırlar.
   **Başka modda bağlı WARP varsa durur**; önce `WarpProxy:40000` ayarını doğrular.
5. Eski kullanıcı yapısını silmeden ayrı **Discord (WARP)** başlatıcısını ve
   kullanıcı GOST servisini kurar. Çalışan bir `127.0.0.1:40001` proxy varsa
   yeniden kullanır.
6. Kurulum bittiğinde **Discord'u Aç**, **Bağlantı tanılama** veya **Kaldır**
   düğmeleri kullanılabilir.

**Linux farkı:** `.deb` dosyasına çift tıklayınca önce Ubuntu'nun kendi güvenilir
paket yükleme ekranı açılır. Bu ekranın ardından kurulum sihirbazı uygulama
menüsünden başlatılır. Windows `.exe` dosyaları gibi indirilmiş bir dosyanın
hiçbir izne gerek kalmadan sistem paketi kurmasına izin verilmez.

**Geliştiriciler için:** Debian paketini üretmek için `./packaging/build-deb.sh`
çalıştırın. Betik `dpkg-deb` gerektirir. Grafik arayüz doğrudan
`python3 gui/installer.py` ile denenebilir (Tkinter).

**Not:** Aracı kaldırmak, üçüncü taraf Discord, WARP ve GOST paketlerini silmez.
Yeni .deb ile gelen sihirbazı ayrıca Ubuntu'nun uygulama yöneticisinden kaldırabilirsiniz.
