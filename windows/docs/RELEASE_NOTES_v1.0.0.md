# Discord WARP + GOST v1.0.0 — Windows Vista Aero Edition

Windows 10/11 x64 için Türkçe, Vista Aero temalı Discord bağlantı yöneticisinin ilk Windows sürümü.

### Yenilikler

- Discord'a özel WARP Local Proxy (`127.0.0.1:40000`) ve GOST HTTP/DoH proxy (`127.0.0.1:40001`) zinciri.
- Gerçek Windows Forms düğmeleri, Türkçe durum mesajları, günlük, kurulum/onarım/kaldırma ve bağlantı testi.
- GOST v3.3.0 resmî indirme paketi, SHA-256 denetimi; açık WARP onayı ve başka modda etkin VPN bağlantısına müdahale etmeme.
- Windows genel DNS/proxy/default route/firewall ayarlarına proje tarafından doğrudan müdahale edilmez; diğer uygulamalar normal ağ üzerinden bağlanır.

### Önemli sınırlamalar

- **Üçüncü taraflarla resmî bağlantısı olmayan, imzasız topluluk aracı.** Windows SmartScreen/Defender algılarını kontrol edin; güvenlik korumasını devre dışı bırakmayın.
- Discord HTTPS erişim testi başarılı olsa dahi sesli sohbet, görüntü ve ekran paylaşımı (UDP/WebRTC) garanti edilmez.
- Kullanıcı RC5'i Windows ortamında açıp çalıştığını bildirdi; temiz Windows sanal makinesinde tam kurulum–yeniden başlatma–kaldırma ve Defender kontrolleri için kayıt bulunmamaktadır.
- WARP kendi servis/bağımlılıklarını yükleyebilir; kurulum sırasında kullanım koşulları ve yetki talepleri gösterebilir.

### Paketler

- `Discord-WARP-GOST-Setup-v1.0.0.exe`
- `discord-warp-gost-windows-v1.0.0-source.zip`
- `SHA256SUMS.txt`

[Kaynak kod](https://github.com/semihkbacak/discord-warp-gost-linux) | [İndir](https://github.com/semihkbacak/discord-warp-gost-linux/releases)
