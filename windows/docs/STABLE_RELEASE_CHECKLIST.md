# Windows v1.0.0 — yayın doğrulaması ve bilinen kapsam

## Onaylananlar

- [x] RC5 Windows üzerinde kullanıcı tarafından açılabildi ve çalıştığı bildirildi.
- [x] Kaynak testleri, GOST sabit SHA-256 denetimi ve Windows x64 Go derlemesi çalıştırıldı.
- [x] Kurulum yerel WARP/GOST proxy'lerini hedefliyor; genel DNS/proxy/netsh/firewall değiştiren proje komutları bulunmadı (statik kontrol).
- [x] Türkçe Vista Aero arayüzü, PowerShell 5.1'deki kıvrımlı tırnak hatası giderildi.

## Hâlâ bağımsız olarak doğrulanması gerekenler

- [ ] Temiz Windows 11 VM'de uçtan uca kurulum, başlatma, yeniden başlatma ve kaldırma.
- [ ] 100%, 125%, 150% DPI'da arayüz ve klavye erişimi.
- [ ] Defender Koruma Geçmişi/SmartScreen tanılama; hiçbir tehdit tespitini otomatik beyaz listeye alma.
- [ ] Sesli sohbet / ekran paylaşımı / WebRTC-UDP özellikleri.
- [ ] İkinci ağ sağlayıcısı/PC üzerinde genel ağ ayarlarının öncesi/sonrası karşılaştırması.
- [ ] Windows GitHub Actions CI kaynak derleme doğrulaması (ilk push sonrası).

Bu dosya sonuçlar geldikçe güncellenecektir. Yayımlanan ilk Windows sürümü **sınırlamaları açıkça belirtilmiş bir topluluk sürümüdür**; yukarıdaki doğrulamalar yapılmış gibi gösterilemez.
