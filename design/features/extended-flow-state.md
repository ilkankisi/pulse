Feature: Genişletilmiş akış ve state davranışları

Scope

Bu feature ana feature dosyalarını tamamlayan genişletilmiş mobil akış ve state davranışlarını tanımlar.

Kapsam:

Ana akışta artımlı/infinite scroll.

Gönderi detayında yanıt listesinin yüklenmesi ve yenilenmesi.

Takipçi kaldırma akışı.

Hesap silme akışı.

Loading, empty, error ve mutation state'lerinin birbirinden ayrılması.

401, 403, 404, 409, 429 ve network/5xx durumlarının başarılı empty state olarak yorumlanmaması.

Tüm endpoint, request alanı, enum, pagination ve hata semantiği canonical docs/api-contract.md sözleşmesinden map edilir.

UI canonical contract'ta bulunmayan endpoint, query parametresi, cursor/page alanı, role, permission veya mutation üretmez.

Components

Infinite feed listesi

Widget hierarchy:

FeedList
└── RefreshIndicator
    └── ListView | CustomScrollView
        ├── PostCard[]
        └── pagination footer
            ├── loading indicator
            ├── retry action
            └── end-of-list state

Kurallar:

İlk yükleme ve sonraki sayfa yükleme farklı state'lerdir.

İlk yükleme başarısızsa feed error state gösterilir.

Sonraki sayfa yüklemesi başarısızsa mevcut başarılı içerik ekranda korunur.

Pagination sırasında mevcut post listesi temizlenmez.

Aynı continuation/cursor/page isteği eşzamanlı olarak tekrar tetiklenmez.

Yeni sayfa canonical response sırasını korur.

UI kendi pagination parametresini veya page size değerini üretmez.

Refresh canonical ilk-page davranışını yeniden başlatır.

Reply listesi

Widget hierarchy:

PostDetailReplies
└── Column
    ├── reply count
    └── replies state
        ├── loading
        ├── empty
        ├── error
        └── ListView | SliverList
            └── ReplyCard[]

Kurallar:

Reply count canonical post/detail response'tan gelir.

Reply listesi canonical sıralamayı kullanır.

Canonical contract eski → yeni sıralamayı tanımlıyorsa UI aynı sırayı korur.

Parent gönderinin sahibi tarafından yazılan reply, mevcut tasarım sistemi içinde ikincil “Gönderi sahibi” etiketiyle vurgulanabilir.

Bu etiket role veya permission değildir.

Reply count kalıcı olarak local liste uzunluğundan türetilmez.

Yeni reply başarıyla oluşturulduktan sonra backend response ve gerekli refetch/invalidation doğruluk kaynağıdır.

Takipçi kaldırma aksiyonu

Widget hierarchy:

FollowerListItem
└── Row
    ├── avatar + identity
    └── current user's own followers list ise
        └── TextButton("Takipçiyi Kaldır")

Kurallar:

Aksiyon yalnız canonical contract takipçi kaldırmayı destekliyorsa gösterilir.

Başka kullanıcının followers ekranında gösterilmez.

Confirmation gerekiyorsa mutation öncesi gösterilir.

Mutation sırasında yalnız ilgili satır disabled/loading olur.

Başarı sonrası canonical followers state yenilenir.

UI kaldırılan takipçiyi block edilmiş kabul etmez.

Hesap silme

Widget hierarchy:

DeleteAccountSection
└── Column
    ├── warning text
    └── FilledButton | TextButton("Hesabımı Sil")
        └── confirmation flow

Kurallar:

Hesap silme yalnız canonical account deletion contract'ı mevcutsa gösterilir.

Destructive aksiyon açık biçimde işaretlenir.

Confirmation olmadan mutation başlatılmaz.

Canonical contract yeniden kimlik doğrulama, password veya başka doğrulama alanı gerektiriyorsa yalnız belirtilen alanlar gösterilir.

UI kendi doğrulama alanını, grace period süresini veya silme endpoint'ini üretmez.

Başarı sonrası local authenticated session merkezi auth akışıyla kapatılır.

Screen states

Infinite feed

Loading:

İlk yüklemede feed loading pattern'i gösterilir.

Sahte post içeriği canonical veri gibi render edilmez.

Success:

Canonical response postları mevcut PostCard bileşeniyle gösterilir.

Sonraki sayfa yüklenirken mevcut içerik korunur.

Empty:

Yalnız başarılı canonical ilk-page response gerçekten içerik içermiyorsa gösterilir.

Network/5xx empty state değildir.

Pagination error:

Mevcut başarılı liste korunur.

Footer seviyesinde retry aksiyonu gösterilir.

CTA: “Tekrar Dene”.

Refresh error:

Önceden yüklenmiş doğrulanmış içerik varsa korunur.

Gönderi detayı yanıtları

Loading:

Parent gönderi mevcutsa görünür kalır.

Replies alanında loading state gösterilir.

Empty:

Yalnız başarılı canonical reply collection boş olduğunda gösterilir.

Ağ hatası empty state değildir.

Error:

CTA: “Tekrar Dene”.

401 merkezi login akışına gider.

403 empty state değildir.

404 parent post veya canonical resource bulunamadı state'idir.

Yeni reply mutation hatasında yazılmış içerik temizlenmez.

Takipçi kaldırma

Loading:

Yalnız seçili satır aksiyonu disabled/loading olur.

Success:

Backend sonucu veya canonical refetch liste doğruluk kaynağıdır.

Error:

Mevcut doğrulanmış follower satırı korunur.

401 merkezi login akışına gider.

403 yetki state'idir.

404 stale resource olarak ele alınır ve gerekirse liste yenilenir.

Network/5xx başarılı kaldırma gibi gösterilmez.

Hesap silme

Initial:

Destructive açıklama ve CTA gösterilir.

Confirmation:

Kullanıcıya geri dönüşü olmayan sonuç açık biçimde anlatılır.

Loading:

Silme CTA'sı tekrar tetiklenemez.

Form gerekiyorsa değerleri görünür kalır.

Success:

Canonical başarı sonrası authenticated kullanıcı state'i temizlenir ve auth başlangıç akışına geçilir.

Error:

Validation veya authentication hatası ilgili alanda gösterilir.

403 başarılı silme değildir.

409 varsa canonical conflict mesajı gösterilir.

429 retry/rate-limit state'idir; form temizlenmez.

Network/5xx form state'ini temizlemez.

Navigation

Ana Akış → post satırı → Gönderi Detayı.

Ana Akış içinde scroll sonuna yaklaşma → canonical pagination davranışı.

Gönderi Detayı → reply listesi aynı route içinde devam eder.

Kendi Profilim → Takipçi sayacı → Takipçiler.

Kendi Takipçilerim → canonical contract destekliyorsa “Takipçiyi Kaldır”; route değişmeden liste güncellenir.

Ayarlar / Hesap → Hesabı Sil.

Hesap silme başarıyla tamamlanırsa merkezi authentication başlangıç akışına gidilir.

401 tüm korumalı genişletilmiş akışlardan merkezi login akışına gider.

UI canonical contract'ta bulunmayan navigation destination veya role-gated route üretmez.