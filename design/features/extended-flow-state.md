Markdown
# Genişletilmiş Akış ve State Davranışları

Bu feature mevcut Pulse tasarım sistemini değiştirmeden şu davranışları tamamlar:

- Ana akışta sonsuz kaydırma
- Gönderi detayında yanıtların listelenmesi
- Kendi takipçiler listesinden kullanıcı kaldırma
- Kendi profilinden kalıcı hesap silme

Renk, tipografi, spacing ve state token'ları `design/DESIGN.core.md` kaynağından kullanılır.

UI katmanı canonical `docs/api-contract.md` dışında endpoint, cursor, pagination parametresi veya mutation payload'ı üretmez.

## User flows

- Ana Akış → ilk sayfa → aşağı kaydır → sonraki sayfa → gönderileri listenin sonuna ekle.
- Son sayfa → yeni network isteği gönderme.
- Pull-to-refresh → pagination state'ini sıfırla → ilk sayfayı yeniden yükle.
- Load-more hatası → mevcut gönderileri koru → “Tekrar Dene”.
- Gönderi → Gönderi Detayı → ana gönderi + yanıtlar.
- Yanıt yok → “Henüz yanıt yok” → “Yanıtla”.
- Kendi Takipçilerim → kullanıcı aksiyonu → “Takipçilerimden Çıkar” → onay → canonical mutation.
- Kendi Profilim → hesap/güvenlik → “Hesabımı Sil” → destructive onay → canonical mutation → başarılıysa session temizle → Oturum Aç.
- Başka kullanıcı profilinde hesap silme veya takipçiden çıkarma owner aksiyonu gösterilmez.

## Components

### Sonsuz kaydırmalı ana akış

**Token:** `{components.post-card}`, `{components.state-panel}`

**Widget hierarchy:**

```text
RefreshIndicator
└── CustomScrollView
    ├── SliverList
    │   └── PostCard[]
    └── SliverToBoxAdapter
        └── footer
            ├── loadingMore
            │   └── CircularProgressIndicator
            ├── loadMoreError
            │   └── Column
            │       ├── Text("Daha fazla gönderi yüklenemedi.")
            │       └── TextButton("Tekrar Dene")
            └── endReached
                └── SizedBox
```

fluttertemplates kaynağı: Core / Lists — https://fluttertemplates.dev/widgets

Kurallar:

İlk loading ile load-more loading ayrı state'lerdir.

Load-more sırasında mevcut gönderiler görünür kalır.

Aynı cursor/sayfa için paralel istek başlatılmaz.

post.id bazında duplicate satır gösterilmez.

Son sayfadan sonra yeni istek yapılmaz.

Pull-to-refresh eski pagination state'ini kullanmaz.

Pagination şekli yalnız docs/api-contract.md ile belirlenir.

Kontratta olmayan cursor, offset, page veya limit parametresi üretilmez.

Load-more error state

Token: {components.state-panel}, {colors.error}

Widget hierarchy:

```
SliverToBoxAdapter
└── Column
    ├── Text("Daha fazla gönderi yüklenemedi.")
    └── TextButton("Tekrar Dene")
```

fluttertemplates kaynağı: States & Errors / Error State — https://fluttertemplates.dev/widgets/states

Kurallar:

Tam ekran “Akış yüklenemedi” state'ine dönüşmez.

Daha önce yüklenen gönderiler silinmez.

“Tekrar Dene” yalnız başarısız sonraki yüklemeyi tekrarlar.

401 merkezi login akışına gider.

Gönderi detayı ve yanıt listesi

Token: {components.post-card}, {components.composer}, {components.state-panel}

Widget hierarchy:

```
Scaffold
├── AppBar(title: "Gönderi")
└── SafeArea
    └── CustomScrollView
        ├── SliverToBoxAdapter
        │   └── PostCard(parentPost)
        ├── SliverToBoxAdapter
        │   └── reply composer | "Yanıtla"
        └── repliesState
            ├── loading → skeleton rows
            ├── empty → EmptyState
            ├── error → ErrorState
            └── loaded
                └── SliverList
                    └── PostCard(reply)[]
```

fluttertemplates kaynağı: Core / Lists — https://fluttertemplates.dev/widgets

Kurallar:

Yanıtlar tek seviyelidir.

Yanıt yokken hata gösterilmez.

Ana gönderi bulunamazsa “Gönderi bulunamadı” gösterilir.

Reply yükleme hatasında ana gönderi görünür kalır.

Aynı reply id iki kez gösterilmez.

Reply read davranışı canonical API kontratından alınır; yeni endpoint uydurulmaz.

Yanıtlar empty state

Token: {components.state-panel}

Widget hierarchy:

```
Center
└── Column
    ├── Icon(chat_bubble_outline)
    ├── Text("Henüz yanıt yok")
    ├── Text("İlk yanıtı sen yaz.")
    └── FilledButton.tonal("Yanıtla")
```

fluttertemplates kaynağı: States & Errors / Empty State — https://fluttertemplates.dev/widgets/states

Kurallar:

Boş collection veya kayıt-yok semantiğindeki 404 empty state'tir.

Yanıt olmaması error state değildir.

Empty state CTA body içindedir.

Takipçiyi kaldırma

Token: {components.social-graph-list-item}, {colors.error}

Widget hierarchy:

```
SocialGraphListItem(follower)
└── owner-only overflow
    └── MenuItemButton("Takipçilerimden Çıkar")

showDialog
└── AlertDialog
    ├── title: Text("Takipçi kaldırılsın mı?")
    ├── content: Text("Bu kullanıcı takipçilerinden çıkarılacak.")
    └── actions
        ├── TextButton("İptal")
        └── FilledButton("Kaldır")
```

fluttertemplates kaynağı: Dialogs & Sheets / Alert Dialog — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Aksiyon yalnız current-user'ın kendi Takipçiler ekranında gösterilir.

Başka profilin Takipçiler ekranında gösterilmez.

Follower removal, unfollow ile aynı mutation olarak varsayılmaz.

Endpoint ve payload canonical API kontratından alınır.

Loading sırasında tekrar tetiklenmez.

Başarı: “Takipçi kaldırıldı.”

Hata: “Takipçi kaldırılamadı. Tekrar deneyin.”

Başarı sonrası liste ve takipçi sayacı backend state ile senkronize edilir.

401 merkezi login akışına gider.

403 empty state değildir.

Kalıcı hesap silme

Token: {colors.error}, {components.state-panel}

Widget hierarchy:

```
OwnProfilePage
└── account/security
    └── ListTile("Hesabımı Sil")

showDialog
└── AlertDialog
    ├── title: Text("Hesabın kalıcı olarak silinsin mi?")
    ├── content: Text("Bu işlem geri alınamaz.")
    └── actions
        ├── TextButton("Vazgeç")
        └── FilledButton("Hesabımı Sil")
```

fluttertemplates kaynağı: Dialogs & Sheets / Alert Dialog — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Yalnız kendi profilinde gösterilir.

Destructive aksiyon {colors.error} kullanır.

Confirmation olmadan mutation başlatılmaz.

Endpoint ve payload yalnız canonical API kontratından alınır.

UI hesap silme endpoint'i uydurmaz.

Loading sırasında destructive CTA tekrar tetiklenmez.

Başarısız işlemde session korunur.

Hata: “Hesap silinemedi. Tekrar deneyin.”

Başarılı işlemden sonra JWT/session temizlenir ve Oturum Aç ekranına gidilir.

State matrix

AkışLoadingEmptyErrorSuccess
Feed ilk yüklemeskeleton"Akış henüz boş""Akış yüklenemedi" + "Tekrar Dene"gönderiler
Feed load-morefooter progressuygulanmaz"Daha fazla gönderi yüklenemedi."append
Yanıt listesiskeleton"Henüz yanıt yok"reply retryyanıtlar
Takipçi kaldırmaaction disableduygulanmaz"Takipçi kaldırılamadı. Tekrar deneyin.""Takipçi kaldırıldı."
Hesap silmedestructive CTA disableduygulanmaz"Hesap silinemedi. Tekrar deneyin."session → Login

Do's and Don'ts

Do

İlk loading ile load-more state'ini ayır.

Load-more hatasında mevcut feed'i koru.

Pagination sonuçlarını id bazında tekilleştir.

Refresh'te pagination state'ini sıfırla.

Yanıt boş listesini empty state olarak göster.

Takipçi kaldırmayı yalnız kendi followers ekranında göster.

Hesap silmede destructive confirmation kullan.

404 kayıt-yok durumunu empty state olarak ele al.

401'i merkezi login akışına gönder.

403'ü empty state yapma.

Don'ts

Load-more sırasında tüm feed'i spinner ile değiştirme.

Aynı cursor/sayfa için paralel istek başlatma.

Yanıt yokken hata gösterme.

Canonical kontratta olmayan reply endpoint'i üretme.

Follower removal işlemini unfollow ile aynı varsayma.

Başka profilin followers ekranında owner aksiyonu gösterme.

Hesap silme endpoint'i uydurma.

Confirmation olmadan kalıcı silme başlatma.

Silme başarısızken session temizleme.
