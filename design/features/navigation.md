# Feature: Uygulama navigasyonu

## Scope
Ana akış ve profil destination'ları; sosyal graf global nav değildir.

## Components
### Uygulama navigasyonu

**Token:** `{components.navigation-drawer}`, `{components.bottom-navigation}`

**Widget hierarchy:**

```text
Scaffold
├── drawer: NavigationDrawer
│   ├── header: DrawerHeader
│   │   └── Row
│   │       ├── CircleAvatar
│   │       └── Column (ad, @kullanıcı)
│   ├── destinations[]
│   │   ├── NavigationDrawerDestination ("Ana Akış")
│   │   ├── NavigationDrawerDestination ("Profil")
│   │   └── moderator ise NavigationDrawerDestination ("Moderasyon")
│   └── footer: ListTile (logout, "Çıkış yap")
├── bottomNavigationBar: NavigationBar
│   └── destinations: "Ana Akış", "Profil"
├── floatingActionButton: FloatingActionButton.extended
│   └── icon: edit + label: "Gönder"
└── body: aktif ekran
```

fluttertemplates kaynağı: Navigation Drawer — https://fluttertemplates.dev/widgets/navigation

Kurallar:

Drawer ve kalıcı sidebar aynı destination listesini paylaşır.

Aktif route ikinci kez stack'e eklenmez.

Moderator destination yalnızca yetkili kullanıcıya görünür.

Bottom Navigation iki ana destination içerir: Ana Akış ve Profil.

Takipçiler ve Takip Edilenler global destination değildir.

Takipçiler ve Takip Edilenler yalnız profil sosyal graf sayaçlarından açılır.

401 genel error state olarak render edilmez; merkezi login akışına yönlendirilir.

## Screen states
Oturum kontrolü loading; 401 login akışına gider.

## Navigation
Drawer, bottom nav ve FAB ile ana ekranlar arası geçiş.

### Sosyal Etkileşim Fazı navigation bağlantıları

Yeni sosyal etkileşim ekranları mevcut root navigation üzerine alt akış olarak bağlanır; NavigationBar/NavigationDrawer destination listesi genişletilmez.

| Kaynak ekran | Tetikleyici UI | Hedef | Geri dönüş / sonuç davranışı |
| --- | --- | --- | --- |
| Feed |
SocialActionBar
→ Repost →
Alıntıla
|
QuoteComposer(originalPost)
| Başarılı submit sonrası kaynak Feed'e dönülür ve canonical sonuçla kart yenilenir. İptal/back kaynak Feed'e taslak göndermeden döner. Submit error Composer üzerinde kalır; quote text/media taslağı korunur. |
| Post Detail |
SocialActionBar
→ Repost →
Alıntıla
|
QuoteComposer(originalPost)
| Başarılı submit sonrası kaynak Post Detail bağlamına dönülür ve canonical sonuç yenilenir. İptal/back aynı Post Detail'e döner. Submit error Composer üzerinde kalır ve taslak korunur. |
| Feed |
SocialActionBar
→ Repost toggle | Mevcut Feed kartı | Repost add/remove için ayrı ekran açılmaz. Loading yalnız ilgili action üzerinde kalır; success canonical karta uygulanır; error kaynak Feed'de kalır ve son başarılı state korunur. |
| Post Detail |
SocialActionBar
→ Repost toggle | Mevcut Post Detail | Repost add/remove için yeni route açılmaz. Loading yalnız action seviyesindedir; success mevcut detayı günceller; error aynı Post Detail'de kalır. |
| Notifications | Mention notification item |
PostDetail(post.id)
| Back kullanıcıyı aynı Notifications listesi bağlamına döndürür. Mention notification'ın post hedefi yok ancak actor profili canonical hedef olarak veriliyorsa mevcut
ProfilePage(actor.username)
kullanılır; yeni profil ekranı oluşturulmaz. |
| Notifications | Like veya Reply notification item |
PostDetail(post.id)
| Back Notifications ekranındaki kaynak liste bağlamına döner. |
| Notifications | Follow notification item |
ProfilePage(actor.username)
| Back Notifications ekranındaki kaynak liste bağlamına döner. |
| Feed / Post Detail / diğer
RichPostText
kullanan ekran | Tıklanabilir
@username
|
ProfilePage(username)
| Back kullanıcıyı mention'ın açıldığı kaynak ekran ve stack bağlamına döndürür. |
| Feed / Post Detail / diğer
RichPostText
kullanan ekran | Tıklanabilir
#tag
|
HashtagPostsPage(tag)
| Back hashtag'i açan kaynak ekrana döner. Hashtag Posts yeni root destination veya trends ekranı değildir. |
| Hashtag Posts |
SocialPostCard
|
PostDetail(post.id)
| Back aynı
HashtagPostsPage(tag)
sonuç listesine döner. |
| Profil/Hesap |
Kaydedilenler
action |
BookmarksPage
| Back kaynak Profil/Hesap bağlamına döner. Kaydedilenler root destination değildir. |
| Kaydedilenler |
SocialPostCard
|
PostDetail(post.id)
| Back aynı Kaydedilenler listesine döner. Bookmark remove işlemi yeni route açmaz; success canonical listeyi günceller, error kaynak ekranda kalır. |

Kurallar:

-
QuoteComposer
,
NotificationsPage
,
HashtagPostsPage
ve
BookmarksPage
yalnız route tanımı olarak bırakılmaz; yukarıdaki mevcut UI giriş noktalarından erişilebilir.
- Feed ve Post Detail repost toggle işlemi mevcut ekran üzerinde mutation'dır; duplicate navigation oluşturmaz.
- Quote Composer açılırken original post route bağlamı taşınır; original içerik quote taslağına flatten edilmez.
- Başarılı quote submit kaynak Feed/Post Detail bağlamına döner; hata Composer'ı kapatmaz.
- Back/cancel mevcut navigation stack'i pop eder; kaynak ekran yeniden root stack'e eklenmez.
- Aktif route gereksiz yere ikinci kez push edilmez.
- Ana Akış, Profil, Followers/Following, Safety, Moderation ve mevcut FAB composer navigation davranışları korunur.
- Yeni root destination ve ikinci root navigation oluşturulmaz.
- Bu bağlantılar nedeniyle Sosyal Etkileşim Fazı kapsamında orphan ekran bulunmaz.
