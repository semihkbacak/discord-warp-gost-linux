# Vista Aero RC4 — Türkçe metinler ve buton yerleşimi

**Hedef:** Windows 10/11 x64 üzerinde, önceki RC3 görsel temasını koruyup İngilizce arayüzü Türkçeleştirmek ve eksik çalışan düğmelerin olaylarını doğrudan Windows Forms kontrollerine bağlamak.

**Kapsam:** Görsel arayüz, düğme etkileşimi, odak/klavye davranışı ve Türkçe kullanıcı mesajları. WARP/GOST ağ mantığı, Discord, Windows genel DNS/proxy/firewall/rota ayarları değiştirilmez. **Stable değildir.**

## Türkçe metin listesi

| Arayüz alanı | RC4 Türkçe metin | İşlev |
| --- | --- | --- |
| Uygulama adı | Discord WARP + GOST | Marka / pencere adı |
| Başlık açıklaması | Discord bağlantısı WARP + GOST üzerinden sağlanır. Sistem DNS ayarları değişmez. | Sınırların açıklanması |
| Üst durum alanı | Bileşen Durumu | Durum göstergesi |
| Bileşen 1 | Başlatıcı | Hazır / Kurulu değil |
| Bileşen 2 | GOST | Kurulu / Kurulu değil |
| Bileşen 3 | WARP | Algılandı / Kurulu değil |
| Bileşen 4 | Discord | Algılandı / Bulunamadı |
| Ana işlem 1 | Kur / Onar | Eksik GOST ve başlatıcı dosyalarını onarır; WARP ayarı için kullanıcı onayı ister |
| Ana işlem 2 | Bağlantı Testi | DNS/WARP/GOST/HTTPS bağlantısını denetler; genel ağ ayarlarını değiştirmez |
| Ana işlem 3 | Kaldır | Yalnızca bu uygulamanın dosya ve kısayollarını kaldırır |
| Ana işlem 4 | WARP Hazırla | Kullanıcı onayıyla WARP'ın Local Proxy modunu hazırlamayı dener |
| Ana işlem 5 | Discord'u İndir | https://discord.com/download adresini açar |
| Günlük | İşlem Günlüğü | Gerçek işlem günlüğü; örnek başarı mesajı içermez |
| Alt sol durum | Yalnızca Discord kullanır. Sistem DNS ayarları değişmez. | Kullanıcı bilgilendirmesi |
| Alt işlem 1 | Discord'u Aç | Discord'u yerel WARP + GOST bağlantısından başlatır |
| Alt işlem 2 | Kapat | Devam eden işlem yoksa sihirbazı kapatır |
| Başarılı kurulum | Kurulum tamamlandı. Discord’u açarak doğrulayın. | Son adım |
| Başarılı kaldırma | Kaldırma tamamlandı. Sihirbazı kapatabilirsiniz. | Son adım |
| Başarısız işlem | İşlem başarısız. Ayrıntıları günlükte inceleyin. | Hata görünürlüğü |

## Düğme yerleşim planı

Referans, resim temasının **864×642 px** koordinat uzayıdır. Form 100% ve 125% büyüklüğe geldiğinde kontrol bölgeleri pencere boyutuna göre ölçeklenir. Aşağıdaki dört sayı sırasıyla `x, y, genişlik, yükseklik`tir.

| Düğme | Konum | Komut | Klavye |
| --- | --- | --- | --- |
| Kur / Onar | 12, 275, 165, 74 | `Install.ps1` | Tab + Enter/Boşluk |
| Bağlantı Testi | 180, 275, 166, 74 | `Diagnose.ps1` | Tab + Enter/Boşluk |
| Kaldır | 350, 275, 165, 74 | `Remove.ps1` | Tab + Enter/Boşluk |
| WARP Hazırla | 519, 275, 167, 74 | `Setup-Warp.ps1` | Tab + Enter/Boşluk |
| Discord'u İndir | 690, 275, 165, 74 | Resmî Discord sitesi | Tab + Enter/Boşluk |
| Discord'u Aç | 513, 578, 189, 49 | `Launch-Discord.ps1` | Tab + Enter/Boşluk |
| Kapat | 719, 578, 134, 49 | Sihirbazı kapat | Tab + Enter/Boşluk |
| Pencere küçült | 738, 0, 40, 35 | Küçült | Tab + Enter/Boşluk |
| Pencere boyutu | 777, 0, 31, 35 | 100% / 125% büyüklük | Tab + Enter/Boşluk |
| Pencere kapat | 808, 0, 55, 35 | Pencereyi kapat | Tab + Enter/Boşluk |

**Tasarım akışı:** Üst cam başlık → dört bileşenli durum paneli → beş işlem düğmesi → işlem günlüğü → alt durum mesajı ve eylem düğmeleri.

### RC3 sorununun teknik düzeltmesi

RC3 sürümünde pencerenin kendi `MouseClick` olayı ve koordinat testi kullanılıyordu. RC4'te her işlem için `AeroHotspot : Control` adlı gerçek bir WinForms kontrolü var. Düğmelerin `Click` olayları doğrudan `Perform-Action` işlevine bağlıdır. Kaydırılabilir günlük, form üzerine bırakılan fare tekeriyle kaydırılır.

### Stable öncesi gerçek Windows kabul testi

- [ ] Tüm beş üst düğme **fareyle** ayrı ayrı çalışıyor.
- [ ] Tüm beş üst düğme **Tab / Enter / Boşluk** ile çalışıyor.
- [ ] 100% ve 125% ekran ölçeklemesinde hitbox konumu doğru.
- [ ] Her iki pencere kapat düğmesi de işlem sırasında yanlışlıkla çıkmıyor.
- [ ] Kur / Onar, WARP onayı ve GOST SHA-256 doğrulaması başarılı.
- [ ] WARP `40000` ve GOST `40001` bağlantısı doğrulanıyor, Discord Starting ekranını geçiyor.
- [ ] Windows yeniden başlatıldıktan sonra Discord (WARP) kısayolu çalışıyor.
- [ ] Kaldırma son ekranı açılıyor; orijinal Discord ve WARP yerinde kalıyor.
- [ ] Sistem DNS / proxy / varsayılan rota değişmiyor.
- [ ] Defender'ın Koruma Geçmişi kontrol edildi; koruma kapatılmadı.

Bu testler tamamlanmadan `v1.0.0 Stable` yayımlanmayacak.
