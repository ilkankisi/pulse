<!-- GENERATED — do not edit. Edit design/DESIGN.core.md and design/features/*.md -->
---
name: "Pulse"
description: "Açık kayıt, kronolojik kısa gönderi, tek seviyeli yanıt, beğeni, takip, takipçi/takip sosyal grafı, kullanıcı profili, engelleme, şikâyet ve moderasyon özelliklerine sahip Material 3 mikroblog platformu."
colors:
  primary: "#6750A4"
  primary-hover: "#5B4595"
  primary-pressed: "#4F378B"
  primary-container: "#EADDFF"
  on-primary: "#FFFFFF"
  on-primary-container: "#21005D"
  secondary: "#625B71"
  secondary-container: "#E8DEF8"
  tertiary: "#7D5260"
  background: "#FFFBFE"
  surface: "#FFFBFE"
  surface-container: "#F3EDF7"
  surface-container-high: "#ECE6F0"
  text-primary: "#1D1B20"
  text-secondary: "#49454F"
  border: "#CAC4D0"
  success: "#2E7D32"
  success-container: "#C8E6C9"
  warning: "#8A5100"
  warning-container: "#FFE0B2"
  error: "#B3261E"
  error-container: "#F9DEDC"
  overlay: "#1D1B2099"
typography:
  display-sm:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: 700
    lineHeight: 40px
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: 700
    lineHeight: 32px
  title-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: 700
    lineHeight: 28px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: 600
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: 400
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: 400
    lineHeight: 18px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: 600
    lineHeight: 20px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
  xxl: 32px
rounded:
  sm: 8px
  md: 12px
  lg: 18px
  pill: 999px
components:
  app-shell:
    maxContentWidth: 720px
    pagePadding: "{spacing.lg}"
  navigation-drawer:
    width: 300px
    selectedColor: "{colors.primary-container}"
  post-card:
    padding: "{spacing.lg}"
    radius: "{rounded.md}"
    border: "{colors.border}"
  composer:
    minHeight: 144px
    maxLength: 280
    radius: "{rounded.lg}"
  profile-summary:
    avatarSize: 80px
  profile-stats:
    minTouchTarget: 44px
    gap: "{spacing.lg}"
  social-graph-list-item:
    minHeight: 72px
    avatarSize: 48px
    paddingHorizontal: "{spacing.lg}"
    paddingVertical: "{spacing.sm}"
  relationship-button:
    height: 40px
    radius: "{rounded.pill}"
  input:
    height: 52px
    radius: "{rounded.md}"
    border: "{colors.border}"
  primary-button:
    height: 48px
    radius: "{rounded.pill}"
  bottom-navigation:
    height: 64px
    itemCount: 2
  state-panel:
    maxWidth: 360px
    iconSize: 48px
  safety-action-menu:
    minTouchTarget: 44px
  report-sheet:
    radius: "{rounded.lg}"
    maxDescriptionLength: 500
  moderation-card:
    padding: "{spacing.lg}"
    radius: "{rounded.md}"
    border: "{colors.border}"
---

## Overview

Pulse, herkesin davet kodu, e-posta domain kısıtı veya yönetici onayı olmadan kayıt olabildiği açık bir mikroblog platformudur.

Temel kapsam:

- Kayıt olma ve JWT ile oturum açma
- Kronolojik ana akış
- En fazla 280 karakterlik gönderi
- Kullanıcının kendi gönderisini silmesi
- Beğeni
- Tek seviyeli yanıt
- Takip etme ve takibi bırakma
- Profil üzerinden takipçi ve takip edilen sayılarını görüntüleme
- Kendi takipçilerini ve takip ettiği hesapları görüntüleme
- Başka kullanıcı profillerinin takipçilerini ve takip ettiği hesapları görüntüleme
- Sosyal graf listesindeki kullanıcıdan profile geçiş
- Kullanıcı profili ve gönderi listesi
- Başka kullanıcıyı engelleme ve engeli kaldırma
- Gönderi veya kullanıcı hesabını şikâyet etme
- Şikâyetlerin yetkili moderatör tarafından incelendiği moderasyon kuyruğu
- Architect API kontratında tanımlanan moderasyon aksiyonları

Özel mesaj, bildirim merkezi, anket, medya gönderisi, yer imi, yeniden paylaşım, alıntı paylaşım, hashtag trendleri ve çok seviyeli thread kapsam dışıdır.

Flutter uygulaması `ThemeData(useMaterial3: true)` ve semantik `ColorScheme` token'larıyla uygulanır.

UI katmanı API endpoint, role, report reason, moderation status veya moderation action değeri üretmez. Değerler canonical `docs/api-contract.md` sözleşmesinden map edilir.

Sosyal graf veri kaynakları canonical olarak:

- Takipçiler: `GET /api/v1/profiles/{username}/followers`
- Takip Edilenler: `GET /api/v1/profiles/{username}/following`
- Takip Et: `POST /api/v1/profiles/{username}/follow`
- Takibi Bırak: `DELETE /api/v1/profiles/{username}/follow`

Followers/Following isteğindeki `{username}`, sosyal graf sayacına basılan profilin kullanıcı adıdır. Başka bir profil görüntülenirken oturum açmış kullanıcının username'i kullanılmaz.

Response yapısı ve varsa pagination davranışı yalnız `docs/api-contract.md` ile belirlenir; UI ek cursor, offset veya query parametresi üretmez.

## Colors

- Birincil CTA ve seçili navigasyon için `{colors.primary}` kullanılır.
- Seçili navigasyon arka planı `{colors.primary-container}` kullanır.
- Beğeninin seçili durumu `{colors.tertiary}` kullanır.
- Silme ve kritik destructive aksiyonlar `{colors.error}` kullanır.
- Başarı mesajları `{colors.success}` kullanır.
- Uyarı ve inceleme durumlarında `{colors.warning}` kullanılabilir.
- Gövde metni `{colors.text-primary}`, metadata `{colors.text-secondary}` kullanır.
- Bileşen kodunda sabit renk yazılmaz.
- Dark mode aynı semantik token adlarıyla ayrı `ColorScheme` üretir.

## Typography

- Gönderi metni `{typography.body-md}` kullanır.
- Görünen ad `{typography.title-md}` kullanır.
- Kullanıcı adı, zaman, reason/status metadata ve sosyal graf ikincil bilgileri `{typography.body-sm}` kullanır.
- Sayfa başlıkları `{typography.title-lg}` veya `{typography.headline-lg}` kullanır.
- Buton, chip ve navigation etiketleri `{typography.label-md}` kullanır.
- Takipçi/takip sayıları `{typography.title-md}`, sayaç açıklamaları `{typography.body-sm}` kullanır.
- Dinamik metin ölçeklendirme desteklenir.
- Önemli içerikler sabit yükseklik nedeniyle kesilmez.

## Layout

- 600px altı: tek kolon, alt navigasyon ve gönderi oluşturma FAB'i.
- 600–1023px: NavigationRail veya drawer ve ortalanmış içerik.
- 1024px ve üzeri: solda kalıcı navigation drawer, ortada en fazla 720px içerik.
- Tüm ana ekranlarda `SafeArea` kullanılır.
- Minimum dokunma alanı 44x44px'tir.
- Akışlar `CustomScrollView` ve `SliverList` ile uygulanır.
- Takipçiler ve Takip Edilenler ekranları `CustomScrollView` + `SliverList` kullanır.
- Klavye açıldığında form CTA'sı erişilebilir kalır.
- Bottom sheet ve dialog genişlikleri büyük ekranlarda içerik genişliğini gereksiz büyütmez.
- Moderasyon kuyruğu mobilde tek kolon, geniş ekranda maksimum içerik genişliği içinde tutulur.
- Sosyal graf satırlarında avatar, kimlik metinleri ve ilişki CTA küçük ekranda taşmadan erişilebilir kalır.
- Uzun görünen adlar gerektiğinde ellipsis kullanabilir; `@username` ve follow/unfollow CTA erişilebilir kalır.

## Elevation

- Gönderi kartları elevation 0 ve 1px outline kullanır.
- Sosyal graf kullanıcı satırları elevation kullanmaz.
- Sosyal graf satırları divider veya yüzey ayrımıyla birbirinden ayrılır.
- Modal bottom sheet elevation 3 kullanır.
- Floating snackbar elevation 6 kullanır.
- Dialog Material 3 varsayılan modal elevation davranışını kullanır.
- Aynı yüzeyde yoğun gölge ve border birlikte kullanılmaz.

## Shapes

- Kartlar `{rounded.md}` veya `{rounded.lg}` kullanır.
- Inputlar `{rounded.md}` kullanır.
- Avatarlar ve ana CTA'lar `{rounded.pill}` kullanır.
- Relationship butonları `{components.relationship-button.radius}` kullanır.
- Bottom sheet `{components.report-sheet.radius}` kullanır.
- Aynı ekranda üçten fazla farklı radius değeri kullanılmaz.

## User flows

- Açılış → oturum kontrolü → JWT varsa Ana Akış, yoksa Oturum Aç.
- Oturum Aç → “Hesabın yok mu? Kayıt ol” → Kayıt Ol.
- Kayıt Ol → JWT dönerse Ana Akış.
- Kayıt Ol → JWT dönmezse e-posta alanı doldurulmuş Oturum Aç.
- Ana Akış → gönderi kartı → Gönderi Detayı.
- Ana Akış → FAB veya body CTA → Gönderi Oluştur.
- Gönderi Detayı → Yanıtla → tek seviyeli yanıt oluştur.
- Profil → kullanıcının kronolojik gönderileri.
- Başka profil → “Takip Et” veya “Takibi Bırak”.
- Kendi profilim → “Takipçi” → `FollowersPage(myUsername)`.
- Kendi profilim → “Takip” → `FollowingPage(myUsername)`.
- Başka kullanıcı profili → “Takipçi” → `FollowersPage(profile.username)`.
- Başka kullanıcı profili → “Takip” → `FollowingPage(profile.username)`.
- Takipçiler → kullanıcı satırı → `ProfilePage(row.username)`.
- Takip Edilenler → kullanıcı satırı → `ProfilePage(row.username)`.
- Profil A → Takipçiler/Takip Edilenler → Profil B → Profil B'nin Takipçiler/Takip Edilenler akışı desteklenir.
- Her sosyal graf ekranı kendi `username` route bağlamını taşır.
- Sosyal graf listesinden profile gidip geri dönüldüğünde kaynak listenin hedef username'i ve scroll konumu mümkün olduğunca korunur.
- Kullanıcının kendi sosyal graf satırında follow/unfollow CTA gösterilmez.
- Sosyal graf listesindeki başka kullanıcı için relationship state'e göre “Takip Et” veya “Takibi Bırak” gösterilir.
- Follow/unfollow sonrasında profil sayaçları ve açık sosyal graf listesi backend'in güncel sonucuyla senkronize edilir.
- Sosyal graf ekranları ana NavigationBar/NavigationDrawer destination değildir; profil sayaçlarından açılan alt ekranlardır.
- Aktif route yeniden navigation stack'e eklenmez.
- Gönderi → overflow güvenlik menüsü → “Şikâyet Et” → şikâyet bottom sheet.
- Başka profil → güvenlik menüsü → “Kullanıcıyı Engelle” → confirmation dialog.
- Engellenmiş profil → “Engeli Kaldır”.
- Moderator → Moderasyon → Moderasyon Kuyruğu → Şikâyet Detayı → canonical moderator aksiyonu.

## Components

Feature: Uygulama navigasyonu

Scope

Ana akış ve profil destination'ları; sosyal graf ve güvenlik yönetimi global nav değildir.

Components

Uygulama navigasyonu

Token: {components.navigation-drawer}, {components.bottom-navigation}

Widget hierarchy:

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

fluttertemplates kaynağı: Navigation Drawer — https://fluttertemplates.dev/widgets/navigation

Kurallar:

Drawer ve kalıcı sidebar aynı destination listesini paylaşır.

Aktif route ikinci kez stack'e eklenmez.

Moderator destination yalnızca yetkili kullanıcıya görünür.

Bottom Navigation iki ana destination içerir: Ana Akış ve Profil.

Takipçiler ve Takip Edilenler global destination değildir.

Takipçiler ve Takip Edilenler yalnız profil sosyal graf sayaçlarından açılır.

Engellenen Hesaplar global destination değildir; profil/hesap güvenliği alt akışından açılır.

401 genel error state olarak render edilmez; merkezi login akışına yönlendirilir.

Screen states

Oturum kontrolü loading; 401 login akışına gider.

Navigation

Drawer, bottom nav ve FAB ile ana ekranlar arası geçiş.

Moderator kullanıcı: Drawer Moderasyon → Moderasyon Kuyruğu → Şikâyet Detayı.

Profil / hesap güvenliği → Engellenen Hesaplar alt ekranı.

---

# Feature: Ana akış ve gönderi detayı

## Scope
Kronolojik feed, gönderi kartı ve yanıt detayı.

## Components
Gönderi listesi satırı

Token: {components.post-card}

Widget hierarchy:

```
SliverList
└── item: Card
    └── InkWell
        └── Padding
            └── Row
                ├── CircleAvatar
                └── Expanded
                    └── Column
                        ├── Row
                        │   ├── Text(displayName)
                        │   ├── Text(@username)
                        │   ├── Text(createdAt)
                        │   └── PopupMenuButton
                        ├── Text(content)
                        └── Row
                            ├── IconButton(reply) + InkWell(replyCount)
                            └── IconButton(like) + InkWell(likeCount)
```

fluttertemplates kaynağı: Core / Card — https://fluttertemplates.dev/widgets

Kurallar:

Gönderi kartı Gönderi Detayı'nı açar.

Gönderinin sahibine silme aksiyonu gösterilebilir.

Başkasının gönderisinde “Şikâyet Et” güvenlik aksiyonu bulunabilir.

Like durumu API cevabıyla senkronize edilir.

Gönderi Detayı'nda `replyCount` tıklanabilir sayaçtır; aynı route içindeki Yanıtlar koleksiyonuna scroll/focus yapar.

Gönderi Detayı'nda `likeCount` tıklanabilir sayaçtır; Beğenenler koleksiyonunu açar.

Yanıtlar koleksiyonu canonical `GET /api/v1/posts/{postId}/replies`, Beğenenler koleksiyonu canonical `GET /api/v1/posts/{postId}/likes` kontratını kullanır. Backend wiring eksikliği nedeniyle UI farklı endpoint üretmez.

Sayaçların dokunma hedefi en az 44px olmalı; ikon ve sayı aynı semantik aksiyon grubunda okunmalıdır.

PostDetail sayaç koleksiyonları

Token: {components.post-card}, {components.state-panel}, {components.social-graph-list-item}

Widget hierarchy:

```
PostDetailBody
└── CustomScrollView
    ├── SliverToBoxAdapter
    │   └── PostCard
    │       └── Row
    │           ├── reply action + tappable replyCount
    │           └── like action + tappable likeCount
    ├── replies collection
    │   ├── loading: SliverList(skeleton reply cards)
    │   ├── success: SliverList
    │   │   └── reply Card
    │   │       └── Row
    │   │           ├── CircleAvatar
    │   │           └── Expanded
    │   │               └── Column
    │   │                   ├── Row(displayName, @username, createdAt)
    │   │                   └── Text(content)
    │   ├── empty: SliverToBoxAdapter > state panel
    │   └── error: SliverToBoxAdapter > error state
    └── likeCount tap
        └── Beğenenler collection route
            └── Scaffold
                ├── AppBar(title: "Beğenenler")
                └── body
                    ├── loading: ListView(skeleton user rows)
                    ├── success: ListView
                    │   └── ListTile
                    │       ├── leading: CircleAvatar
                    │       ├── title: Text(displayName)
                    │       └── subtitle: Text(@username)
                    ├── empty: state panel
                    └── error: error state + OutlinedButton("Tekrar Dene")
```

fluttertemplates kaynağı: Social / Comments Thread — https://fluttertemplates.dev/widgets/social

fluttertemplates kaynağı: Social / User Search — https://fluttertemplates.dev/widgets/social

Kurallar:

Yanıt sayacı tap'i yeni PostDetail route'u oluşturmaz; mevcut Yanıtlar bölümünü görünür alana getirir.

Yanıt koleksiyonu yüklenirken ana gönderi görünür kalır.

Beğenenler koleksiyonundaki kullanıcı satırı profile gider.

Boş başarılı koleksiyon veya kayıt-yok semantiğindeki 404 empty state'tir; ağ/5xx error state'tir.

Alt koleksiyon hatası ana gönderiyi hata ekranıyla değiştirmez.

Empty durumda boş SliverList yerine state panel gösterilir.

Empty state

Token: {components.state-panel}

Widget hierarchy:

```
Center
└── ConstrainedBox(maxWidth: 360)
    └── Column(mainAxisSize: min)
        ├── Icon
        ├── Text(title)
        ├── Text(description)
        └── optional FilledButton.tonal | FilledButton
```

fluttertemplates kaynağı: States & Errors / Empty State — https://fluttertemplates.dev/widgets/states

Kurallar:

Kayıt yokken hata olarak gösterilmemelidir.

Kayıt yok anlamındaki 404 empty state olarak ele alınır.

Ağ/5xx empty state değildir.

Empty state'te boş SliverList gösterilmez.

Sosyal graf empty state'lerinde gereksiz primary CTA eklenmez.

Birincil oluşturma CTA'sı gereken ekranlarda body içinde bulunur.

Loading state

Token: {components.state-panel}

Widget hierarchy:

```
Scaffold body
├── oturum kontrolü:
│   └── Center(CircularProgressIndicator)
└── liste:
    └── CustomScrollView
        └── SliverList
            └── skeleton Card/ListTile placeholders
```

fluttertemplates kaynağı: States & Errors / Loading State — https://fluttertemplates.dev/widgets/states

Kurallar:

Loading sırasında önceki kullanıcıya ait veri gösterilmez.

Follow/unfollow sırasında yalnız ilgili CTA loading olur.

Mutation tekrar tetiklenemez.

Form taslakları loading nedeniyle temizlenmez.

Error state

Token: {components.state-panel}, {colors.error}

Widget hierarchy:

```
Center
└── ConstrainedBox(maxWidth: 360)
    └── Column
        ├── Icon(error_outline)
        ├── Text(title)
        ├── Text(description, optional)
        └── OutlinedButton("Tekrar Dene")
```

fluttertemplates kaynağı: States & Errors / Error State — https://fluttertemplates.dev/widgets/states

Kurallar:

401 genel error state değildir; login akışına yönlendirilir.

Kayıt yok anlamındaki 404 error değildir.

403 normal empty state gibi gösterilmez.

Validation hataları ilgili input altında gösterilir.

Ağ hatasında taslak korunur.

Success snackbar

Token: {colors.success}

Widget hierarchy:

```
ScaffoldMessenger.showSnackBar
└── SnackBar
    └── Text(successMessage)
```

fluttertemplates kaynağı: Dialogs & Sheets / Snackbars — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Mobilde floating snackbar kullanılır.

İşleme özgü Türkçe başarı metni kullanılır.

Liste yalnız başarılı yüklendi diye snackbar gösterilmez.

## Screen states
Screen States

Ana Akış

Empty state

Başlık: "Akış henüz boş"

Açıklama: "İlk gönderini paylaşarak konuşmayı başlat."

CTA: "Gönderi Oluştur"

Error state

Başlık: "Akış yüklenemedi"

CTA: "Tekrar Dene"

404 kayıt-yok hata değildir.

401 login akışına gider.

Success

"Gönderi paylaşıldı."

App bar vs body CTA

Empty state CTA body'dedir.

Normal durumda FAB kullanılabilir.

Gönderi Detayı ve Yanıtlar

Empty state

Başlık: "Henüz yanıt yok"

Açıklama: "İlk yanıtı sen yaz."

CTA: "Yanıtla"

Sayaç → koleksiyon

Yanıt sayacı hedefi: "Yanıtlar"

Yanıt koleksiyonu empty başlık: "Henüz yanıt yok"

Yanıt koleksiyonu empty açıklama: "İlk yanıtı sen yaz."

Yanıt koleksiyonu empty CTA: "Yanıtla"

Yanıt koleksiyonu error başlık: "Yanıtlar yüklenemedi"

Yanıt koleksiyonu error CTA: "Tekrar Dene"

Beğeni sayacı hedefi: "Beğenenler"

Beğenenler empty başlık: "Henüz beğeni yok"

Beğenenler empty açıklama: "Bu gönderiyi henüz kimse beğenmedi."

Beğenenler empty CTA: yok

Beğenenler error başlık: "Beğenenler yüklenemedi"

Beğenenler error CTA: "Tekrar Dene"

Error state

Ana gönderi bulunamazsa: "Gönderi bulunamadı"

Ağ hatası: "Gönderi yüklenemedi"

CTA: "Tekrar Dene"

Yanıt listesinin boş olması hata değildir.

Success

"Yanıt gönderildi."

App bar vs body CTA

"Yanıtla" body içinde bulunur.

## Navigation
Ana Akış home; kart tap → Gönderi Detayı; FAB → composer.

Gönderi Detayı `replyCount` tap → aynı route içindeki Yanıtlar koleksiyonuna scroll/focus.

Gönderi Detayı `likeCount` tap → Beğenenler koleksiyonu.

Beğenenler kullanıcı satırı tap → ilgili kullanıcı profili.

---

# Feature: Gönderi oluşturma

## Scope
280 karakterlik gönderi ve yanıt composer.

## Components
Gönderi oluşturucu

Token: {components.composer}, {components.primary-button}

Widget hierarchy:

```
Scaffold
├── AppBar
│   ├── leading: close/back
│   └── action: FilledButton("Gönder")
└── SafeArea
    └── Padding
        └── Form
            └── Column
                ├── Row
                │   ├── CircleAvatar
                │   └── Expanded
                │       └── TextFormField
                │           ├── multiline
                │           └── maxLength: 280
                ├── character counter
                └── validation message
```

fluttertemplates kaynağı: Forms / Inputs & Validation — https://fluttertemplates.dev/widgets/forms

Kurallar:

Post alanı canonical content alanına map edilir.

Boş veya yalnız whitespace içerik gönderilmez.

Maksimum 280 karakterdir.

Loading sırasında gönder CTA'sı disabled olur.

Ağ hatasında taslak korunur.

## Screen states
Gönderi Oluşturma

Empty state

Form başlangıcı API empty state değildir.

Error state

Validation input altında gösterilir.

Ağ hatasında taslak korunur.

401 login akışına gider.

Success

"Gönderi paylaşıldı."

App bar vs body CTA

Tek primary aksiyon "Gönder"dir.

## Navigation
FAB veya CTA ile açılır; başarı sonrası feed yenilenir.

---

# Feature: Profil özeti ve gönderiler

## Scope
Profil header, sayaçlar, follow CTA ve gönderi listesi.

## Components
Profil özeti

Token: {components.profile-summary}, {components.profile-stats}, {components.relationship-button}

Widget hierarchy:

```
Column
├── Row
│   ├── CircleAvatar(size: 80)
│   └── actions
│       ├── own profile:
│       │   └── OutlinedButton("Profili Düzenle")
│       └── other profile:
│           └── FilledButton | OutlinedButton
│               └── "Takip Et" | "Takibi Bırak"
├── Text(displayName)
├── Text(@username)
├── Text(bio, optional)
├── Row: profileStats
│   ├── InkWell | TextButton
│   │   └── RichText(followingCount + " Takip")
│   │       └── onTap: FollowingPage(profile.username)
│   └── InkWell | TextButton
│       └── RichText(followerCount + " Takipçi")
│           └── onTap: FollowersPage(profile.username)
└── Divider
```

fluttertemplates kaynağı: Profile / Profile Header — https://fluttertemplates.dev/widgets/profile

Kurallar:

profile.username, ekranda görüntülenen profilin kullanıcı adıdır.

Başka bir kullanıcı profili görüntülenirken current-user username kullanılmaz.

Kendi profili ile başka profil aynı sayaç widget'ını kullanır.

“Takip” → FollowingPage(profile.username).

“Takipçi” → FollowersPage(profile.username).

Sayaçların tamamı minimum 44x44px dokunma alanına sahiptir.

Başka profilde follow state'e göre yalnız “Takip Et” veya “Takibi Bırak” gösterilir.

Kendi profilinde follow ve block aksiyonu gösterilmez.

Profil gönderileri mevcut post component'iyle listelenir.

Follow/unfollow loading sırasında CTA tekrar tetiklenemez.

Sayaçlar mutation sonrası backend state ile senkronize edilir.

Profil güncelleme başarı mesajı: “Profil güncellendi.”

## Screen states
Profil

Empty state

Başlık: "Henüz gönderi yok"

Açıklama: "Bu kullanıcının henüz gönderisi yok."

Kendi profilinde CTA: "Gönderi Oluştur"

Başka profilde zorunlu primary CTA yoktur.

Error state

Ağ/5xx: "Profil yüklenemedi"

Kullanıcı bulunamazsa: "Kullanıcı bulunamadı"

CTA: "Tekrar Dene"

401 login akışına gider.

Success

Profil güncelleme: "Profil güncellendi."

Follow: "Takip edildi."

Unfollow: "Takip bırakıldı."

App bar vs body CTA

"Profili Düzenle" profil header içindedir.

Follow CTA başka profil header'ındadır.

“Takip” ve “Takipçi” sayaçları profil body/header içindeki navigation aksiyonlarıdır.

## Navigation
Bottom nav / drawer Profil; sayaç tap → social-graph feature.

---

# Feature: Takipçiler ve takip edilenler

## Scope
Profil sayaçlarından açılan sosyal graf listeleri.

## Components
Sosyal graf kullanıcı satırı

Token: {components.social-graph-list-item}, {components.relationship-button}

Widget hierarchy:

```
SocialGraphListItem(user)
└── InkWell
    └── ConstrainedBox(minHeight: 72)
        └── Padding
            └── Row
                ├── CircleAvatar(size: 48)
                ├── SizedBox(width: spacing.md)
                ├── Expanded
                │   └── Column(crossAxis: start)
                │       ├── Text(user.displayName)
                │       └── Text("@${user.username}")
                └── relationship action
                    ├── user == currentUser
                    │   └── no action
                    ├── isFollowing == false
                    │   └── FilledButton("Takip Et")
                    └── isFollowing == true
                        └── OutlinedButton("Takibi Bırak")
```

fluttertemplates kaynağı: Core / Lists — https://fluttertemplates.dev/widgets

Kurallar:

Avatar, displayName, username veya satırın profil alanına dokunulduğunda ProfilePage(user.username) açılır.

Parent Followers/Following ekranının username'i yerine satırdaki user.username kullanılır.

Kullanıcının kendi satırında follow CTA gösterilmez.

Relationship state canonical backend sonucundan gelir.

Follow/unfollow sırasında yalnız ilgili satır CTA'sı disabled/loading olur.

Tüm liste loading state'e dönmez.

Optimistic update kullanılırsa hata halinde eski state geri alınır.

Follow/unfollow sonrası profil ve sosyal graf sayaçları backend sonucuyla senkronize edilir.

Engelle/şikâyet aksiyonları bu satıra eklenmez; profil güvenlik menüsünden yürütülür.

Takipçiler listesi

Token: {components.social-graph-list-item}, {components.state-panel}

Widget hierarchy:

```
FollowersPage(username)
└── Scaffold
    ├── AppBar
    │   ├── leading: BackButton
    │   └── title
    │       └── Column
    │           ├── Text("Takipçiler")
    │           └── optional Text("@username")
    └── SafeArea
        └── state
            ├── loading-state
            ├── empty-state
            ├── error-state
            └── CustomScrollView
                └── SliverList
                    └── SocialGraphListItem[]
```

fluttertemplates kaynağı: Core / Lists — https://fluttertemplates.dev/widgets

Kurallar:

Ekran zorunlu username route parametresi alır.

Veri kaynağı: GET /api/v1/profiles/{username}/followers.

{username}, sosyal grafı görüntülenen profilin username değeridir.

Kendi profilimde sayaçtan açıldığında kendi username'im kullanılır.

Başka profilin sayacından açıldığında o profilin username'i kullanılır.

Liste ilgili profilin takipçilerini gösterir.

Satırdan profile geçerken row.username kullanılır.

Profil A'nın takipçileri içinde Profil B'ye girildiğinde Profil B'nin sayaçları Profil B username'i ile yeni sosyal graf açar.

Geri navigasyonda kaynak FollowersPage(username) route'u korunur.

Mümkünse scroll pozisyonu korunur.

404 kayıt-yok semantiği taşıyorsa empty state olarak ele alınır.

Ağ/5xx empty state'e dönüştürülmez.

401 login akışına gider.

Empty durumda boş SliverList render edilmez.

UI canonical API dışında endpoint veya query parametresi üretmez.

Takip Edilenler listesi

Token: {components.social-graph-list-item}, {components.state-panel}

Widget hierarchy:

```
FollowingPage(username)
└── Scaffold
    ├── AppBar
    │   ├── leading: BackButton
    │   └── title
    │       └── Column
    │           ├── Text("Takip Edilenler")
    │           └── optional Text("@username")
    └── SafeArea
        └── state
            ├── loading-state
            ├── empty-state
            ├── error-state
            └── CustomScrollView
                └── SliverList
                    └── SocialGraphListItem[]
```

fluttertemplates kaynağı: Core / Lists — https://fluttertemplates.dev/widgets

Kurallar:

Ekran zorunlu username route parametresi alır.

Veri kaynağı: GET /api/v1/profiles/{username}/following.

{username}, sosyal grafı görüntülenen profilin username değeridir.

Kendi profilimde sayaçtan açıldığında kendi username'im kullanılır.

Başka profilin sayacından açıldığında o profilin username'i kullanılır.

Liste ilgili profilin takip ettiği kullanıcıları gösterir.

Satırdan profile geçerken row.username kullanılır.

Profil A'nın takip listesi içinden Profil B'ye geçildiğinde Profil B sosyal grafı Profil B username'iyle açılır.

Geri navigasyonda kaynak FollowingPage(username) route'u korunur.

Mümkünse scroll pozisyonu korunur.

Relationship CTA canonical backend state'e göre gösterilir.

404 kayıt-yok semantiği taşıyorsa error değildir.

Ağ/5xx error state'tir.

401 login akışına gider.

Empty durumda boş SliverList render edilmez.

UI canonical API dışında endpoint veya query parametresi üretmez.

## Screen states
Takipçiler

Route

FollowersPage(username)

API: GET /api/v1/profiles/{username}/followers

{username} = sosyal grafı görüntülenen profil.

Empty state

Başlık: "Henüz takipçi yok"

Açıklama: "Bu hesabı henüz kimse takip etmiyor."

Birincil CTA yoktur.

Error state

Başlık: "Takipçiler yüklenemedi"

Açıklama: "Takipçi listesi alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

404 kayıt-yok error değildir.

401 login akışına gider.

Success

Liste yüklenmesinde snackbar yoktur.

Follow: "Takip edildi."

Unfollow: "Takip bırakıldı."

App bar vs body CTA

AppBar: geri + "Takipçiler".

Follow/unfollow ilgili satırdadır.

Takip Edilenler

Route

FollowingPage(username)

API: GET /api/v1/profiles/{username}/following

{username} = sosyal grafı görüntülenen profil.

Empty state

Başlık: "Henüz kimse takip edilmiyor"

Açıklama: "Takip edilen hesaplar burada görünür."

Birincil CTA yoktur.

Error state

Başlık: "Takip edilenler yüklenemedi"

Açıklama: "Takip edilen hesaplar alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

404 kayıt-yok error değildir.

401 login akışına gider.

Success

Liste yüklenmesinde snackbar yoktur.

Follow: "Takip edildi."

Unfollow: "Takip bırakıldı."

App bar vs body CTA

AppBar: geri + "Takip Edilenler".

Follow/unfollow ilgili satırdadır.

## Navigation
Profil Takip/Takipçi sayaçlarından; liste satırı → profil.

---

Feature: Engelleme ve şikâyet

Scope

Güvenlik menüsü, şikâyet sheet, engelleme dialogu ve engellenen hesap yönetimi.

Components

Güvenlik aksiyon menüsü

Token: {components.safety-action-menu}

Widget hierarchy:

PopupMenuButton | MenuAnchor

└── menuChildren

├── gönderi:

│   └── MenuItemButton

│       ├── Icon(flag_outlined)

│       └── Text("Şikâyet Et")

└── başka kullanıcı profili:

├── MenuItemButton

│   ├── Icon(flag_outlined)

│   └── Text("Şikâyet Et")

└── MenuItemButton

├── Icon(block)

└── Text("Kullanıcıyı Engelle" | "Engeli Kaldır")

fluttertemplates kaynağı: Dialogs & Sheets / Menus — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Minimum dokunma alanı 44x44px'tir.

Kullanıcı kendi hesabını engelleyemez.

Kullanıcı kendi hesabı veya kendi gönderisi için şikâyet aksiyonu görmez.

Engelleme destructive/security aksiyonudur.

UI block/report endpoint veya enum üretmez.

Report target yalnız canonical Post veya User değerine map edilir.

Report reason yalnız canonical Spam, Harassment, HateSpeech, Violence, SexualContent, Impersonation veya Other değerlerinden biridir.

Şikâyet bottom sheet

Token: {components.report-sheet}, {components.input}, {components.primary-button}

Widget hierarchy:

showModalBottomSheet

└── SafeArea

└── Padding

└── Form

└── Column(mainAxisSize: min)

├── drag handle

├── Text("Şikâyet Et")

├── Text("Neden şikâyet ediyorsun?")

├── RadioGroup | RadioListTile[]

│   └── canonical report reason seçenekleri

├── TextFormField

│   ├── label: "Açıklama (isteğe bağlı)"

│   ├── multiline

│   └── maxLength: 500

└── FilledButton("Şikâyet Et")

fluttertemplates kaynağı: Dialogs & Sheets / Modal Bottom Sheet — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Gönderi ve kullanıcı şikâyeti aynı component'i kullanır.

Reason canonical API kontratından map edilir.

Reason seçilmeden submit aktif olmaz.

Açıklama en fazla 500 karakterdir.

Ağ hatasında reason ve açıklama korunur.

400 validation hatasında sheet açık kalır ve backend field bilgisi ilgili input'a map edilir.

404 hedefin artık bulunamadığı veya görünmediği durumdur; UI block sebebini tahmin etmez.

409 duplicate pending report başarı gibi gösterilmez.

Başarı snackbar'ı: “Şikâyetiniz alındı”.

Engelleme onay dialogu

Token: {components.safety-action-menu}, {colors.error}

Widget hierarchy:

showDialog

└── AlertDialog

├── title: Text("Kullanıcı engellensin mi?")

├── content: Text(

│       "Bu kullanıcının içerik ve etkileşimleri bloklama kurallarına göre sınırlandırılacak."

│   )

└── actions

├── TextButton("İptal")

└── FilledButton("Engelle")

fluttertemplates kaynağı: Dialogs & Sheets / Alert Dialog — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Engelleme confirmation olmadan başlamaz.

Loading sırasında CTA tekrar tetiklenemez.

Başarı: “Kullanıcı engellendi.”

Engeli kaldırma: “Engel kaldırıldı.”

Backend görünürlük kuralları UI'da yeniden tanımlanmaz.

Block sonrasında backend tarafından kaldırılan follow ilişkileri local state ile geri üretilmez.

Unblock eski follow ilişkilerini otomatik geri getirmez.

Engellenen kullanıcılar listesi

Token: {components.social-graph-list-item}, {components.state-panel}

Widget hierarchy:

BlockedUsersPage

└── Scaffold

├── AppBar

│   └── Text("Engellenen Hesaplar")

└── SafeArea

└── blocked users state

├── loading

├── empty

├── error

└── CustomScrollView

└── SliverList

└── Padding

└── Row

├── CircleAvatar

├── Expanded

│   └── Column(crossAxis: start)

│       ├── Text(displayName)

│       └── Text("@username")

└── OutlinedButton("Engeli Kaldır")

Kurallar:

Veri yalnız GET /api/v1/blocks response'undan gelir.

Liste canonical id, username, displayName, avatarUrl ve blockedAt alanlarını kullanır.

UI ek filter, sort, cursor veya pagination parametresi üretmez.

“Engeli Kaldır” canonical DELETE /api/v1/profiles/{username}/block işlemine map edilir.

Mutation sırasında yalnız ilgili satır CTA'sı loading/disabled olur.

204 başarıdan sonra ilgili satır listeden kaldırılır.

Unblock eski follow ilişkisini geri getirmez.

Minimum dokunma alanı 44x44px korunur.

Screen states

Şikâyet Formu

Empty state

Reason seçilmemiş başlangıç hali API empty state değildir.

Error state

"Şikâyet gönderilemedi. Tekrar deneyin."

400 canonical validation mesajı ilgili alanda gösterilir.

404 hedefin artık kullanılamadığı belirtilir; block ilişkisi ifşa edilmez.

409: "Bu içerik veya hesap için zaten bekleyen bir şikâyetin var."

401 login akışına gider.

Taslak korunur.

Success

"Şikâyetiniz alındı"

App bar vs body CTA

CTA bottom sheet içinde "Şikâyet Et".

Kullanıcı Engelleme

Empty state

Uygulanmaz.

Error state

Ağ hatasında profil korunur.

401 login akışına gider.

Success

"Kullanıcı engellendi."

"Engel kaldırıldı."

App bar vs body CTA

Güvenlik menüsünden başlatılır.

Engellenen Hesaplar

Loading state

Liste yüklenirken sayfa bağlamı korunur.

Empty state

Başlık: "Engellenen hesap yok"

Açıklama: "Engellediğin hesaplar burada görünür."

CTA yoktur.

Error state

Başlık: "Engellenen hesaplar yüklenemedi"

Açıklama: "Liste alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

401 login akışına gider.

Success

Canonical items listesi render edilir.

Unblock başarıyla tamamlandığında ilgili satır kaldırılır.

App bar vs body CTA

Sayfa seviyesinde destructive CTA yoktur.

“Engeli Kaldır” yalnız ilgili liste satırındadır.

Navigation

Gönderi overflow veya profil güvenlik menüsünden.

Profil / hesap güvenliği → "Engellenen Hesaplar" → BlockedUsersPage.

BlockedUsersPage global NavigationBar veya NavigationDrawer destination değildir.

---

Feature: Moderasyon kuyruğu

Scope

Moderator-only şikâyet kuyruğu, detay inceleme ve canonical karar aksiyonları.

Components

Moderasyon kuyruğu kartı

Token: {components.moderation-card}

Widget hierarchy:

CustomScrollView

└── SliverList

└── Card

└── Padding

└── Column(crossAxis: start)

├── Row

│   ├── target summary

│   └── status badge

├── Text(report reason)

├── Text(report description, optional)

├── Text(metadata)

└── action area

└── canonical moderator actions

fluttertemplates kaynağı: Core / Cards — https://fluttertemplates.dev/widgets

Kurallar:

Yalnız moderator kullanıcıya gösterilir.

Status ve action değerleri docs/api-contract.md ile map edilir.

UI yeni role/status/action üretmez.

İşlenen kayıt backend sonucuna göre yenilenir veya listeden çıkarılır.

Kuyruk query verilmediğinde canonical Pending durumunu kullanır.

Durum filtresi sunulursa yalnız Pending, Resolved ve Dismissed değerleri kullanılır.

Liste satırı canonical report.id ile ModerationDetailPage açar.

Moderasyon detay ve karar yüzeyi

Token: {components.moderation-card}, {components.input}, {components.primary-button}

Widget hierarchy:

ModerationDetailPage

└── Scaffold

├── AppBar

│   └── Text("Şikâyet Detayı")

└── SafeArea

└── CustomScrollView

└── SliverToBoxAdapter

└── Column

├── report metadata

│   ├── targetType + targetId

│   ├── reporterUserId

│   ├── reason

│   ├── details, optional

│   ├── status

│   ├── createdAt

│   ├── resolvedAt, optional

│   └── resolvedByUserId, optional

└── status == Pending ise action area

├── moderation action selector

│   ├── NoAction

│   └── targetType == Post ise RemovePost

├── TextFormField

│   ├── label: "Moderatör notu (isteğe bağlı)"

│   ├── multiline

│   └── maxLength: 500

├── FilledButton("Çözümle")

└── OutlinedButton("Reddet")

Kurallar:

Detay yalnız GET /api/v1/moderation/reports/{reportId} sonucundan render edilir.

Resolve yalnız POST /api/v1/moderation/reports/{reportId}/resolve işlemine map edilir.

Dismiss yalnız POST /api/v1/moderation/reports/{reportId}/dismiss işlemine map edilir.

Resolve action yalnız canonical NoAction veya RemovePost olabilir.

RemovePost yalnız targetType=Post için gösterilir.

User report için RemovePost gösterilmez veya request'e yazılmaz.

note en fazla 500 karakterdir.

Mutation sırasında resolve/dismiss CTA'ları tekrar tetiklenemez.

Resolved veya Dismissed kayıtta yeni karar CTA'sı gösterilmez.

Başarılı işlem sonrası status/action backend response'undan alınır.

Moderasyon kaldırması standart DELETE /api/v1/posts/{postId} endpoint'ine map edilmez.

Dismiss target kaynağını değiştirmez.

Screen states

Moderasyon Kuyruğu

Empty state

Başlık: "Bekleyen şikâyet yok"

Açıklama: "İncelenecek yeni şikâyet bulunmuyor."

CTA yoktur.

Error state

Başlık: "Moderasyon kuyruğu yüklenemedi"

Açıklama: "Şikâyetler alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

403 empty değildir.

401 login akışına gider.

Success

Backend'in güncel moderation sonucu render edilir.

App bar vs body CTA

Moderasyon aksiyonları ilgili kayıt body alanındadır.

Şikâyet Detayı

Loading state

Canonical report kaydı yüklenene kadar loading gösterilir.

Empty state

Tekil report detayında empty state kullanılmaz.

Error state

400 canonical action/note validation hatası form üzerinde gösterilir.

401 login akışına gider.

403 yetkisiz durumudur; empty state değildir ve moderation CTA'ları gösterilmez.

404:

Başlık: "Şikâyet bulunamadı"

Açıklama: "Bu şikâyet artık mevcut değil veya erişilemiyor."

409:

Başlık: "Şikâyet daha önce işlendi"

Açıklama: "Güncel durumu görmek için kaydı yenile."

CTA: "Yenile"

Success

Resolve sonucu Resolved, dismiss sonucu Dismissed olarak backend response'undan render edilir.

RemovePost sonucunda istemci post görünürlüğünü local olarak taklit etmez; sonraki canonical read sonucu kaynak kabul edilir.

App bar vs body CTA

Karar CTA'ları yalnız Pending kaydın body alanındadır.

Do's and Don'ts

Do

Material 3 semantik token'larını kullan.

401'i login akışına gönder.

403'ü normal empty state gibi gösterme.

Moderator-only navigation ve aksiyonları yalnız doğrulanmış Moderator yetki durumunda göster.

403 alındığında moderation içeriğini veya karar CTA'larını göstermeye devam etme.

Pending kayıtta yalnız canonical moderation aksiyonlarını göster.

User report'unda RemovePost aksiyonunu gösterme.

Resolve/dismiss sonrasında backend response'unu kaynak kabul et.

409 durumunda kaydın güncel durumunu yeniden yükle.

Minimum dokunma alanını 44x44px koru.

Don'ts

401'i normal retry paneli olarak gösterme.

Moderator olmayan kullanıcıya moderation action gösterme.

API kontratında olmayan role, status veya moderation action üretme.

User report için RemovePost request'i üretme.

Resolved veya Dismissed report üzerinde tekrar resolve/dismiss gösterme.

Moderasyon kaldırması için standart post DELETE endpoint'ini kullanma.

403 sonucunu boş moderation kuyruğu gibi gösterme.

409 sonrasında eski Pending state'i yalnız local state ile koruma.

Resolve veya dismiss sonucunu yalnız optimistic state ile kalıcı kaynak kabul etme.

Çok seviyeli thread, DM veya kapsam dışı yeni özellik ekleme.

Navigation

Drawer Moderasyon destination (moderator rolü).

Moderasyon Kuyruğu → ModerationDetailPage(report.id).

Detay işlendiğinde geri dönülen kuyruk backend'in güncel sonucu ile yenilenir.

---

# Feature: Öncelik 1 ürün tamamlama deneyimi

## Scope

Ürünün temel sosyal deneyimini tamamlayan yüzeyler:

- Kullanıcı ve içerik araması
- Gönderi oluştururken mention keşfi ve seçimi
- Profilde sabitlenmiş gönderi gösterimi
- Kullanıcıyı sessize alma ve sessizden çıkarma
- Gönderi oluşturma taslağının korunması
- Kullanıcının kendi gönderisini düzenlemesi

Tüm API, response, permission ve mutation davranışları canonical `docs/api-contract.md` sözleşmesinden map edilir.

UI:

- API kontratında olmayan endpoint üretmez.
- API kontratında olmayan query parametresi üretmez.
- API kontratında olmayan role, status, enum veya action üretmez.
- Backend'in desteklemediği davranışı yalnız local state ile kalıcı ürün özelliği gibi göstermez.
- Canonical response field adlarını yeniden tanımlamaz.

## User flows

### Arama

1. Arama giriş noktası → Arama ekranı.
2. Kullanıcı sorgusunu girer.
3. Sonuçlar canonical backend response'una göre render edilir.
4. Kullanıcı sonucu → `ProfilePage(result.username)`.
5. Gönderi sonucu → ilgili Gönderi Detayı.

Kurallar:

- Sonuç bulunmaması empty state'tir.
- Ağ/5xx empty state değildir.
- 401 merkezi login akışına gider.
- Yeni sorgu başladığında eski sorgunun geciken cevabı güncel sonucu overwrite etmez.

### Mention

1. Composer içinde `@` mention bağlamı başladığında suggestion yüzeyi açılır.
2. Suggestion verisi yalnız canonical API davranışından gelir.
3. Kullanıcı suggestion seçtiğinde canonical username composer'a eklenir.
4. Suggestion loading, empty veya error durumunda composer taslağı korunur.
5. Render edilmiş mention destekleniyorsa `ProfilePage(username)` açar.

UI backend'in tanımadığı mention identifier veya syntax üretmez.

### Profil ve pinned post

1. Profil yüklenir.
2. Backend response sabitlenmiş gönderi içeriyorsa profil gönderilerinden önce pinned yüzeyi gösterilir.
3. Pinned gönderi mevcut post-card bileşenini yeniden kullanır.
4. Pinned karta dokunma → Gönderi Detayı.

Kurallar:

- Pinned state yalnız backend sonucundan gelir.
- Pinned gönderi yoksa placeholder veya empty panel gösterilmez.

### Mute / unmute

Başka kullanıcı profili → güvenlik/overflow menüsü.

Backend relationship state'e göre:

- Sessize Al
- Sessizden Çıkar

Kurallar:

- Kendi profilinde mute/unmute gösterilmez.
- Mutation sırasında yalnız ilgili aksiyon loading/disabled olur.
- Başarı sonrası state backend sonucuyla senkronize edilir.
- Hata halinde önceki state korunur.
- Feed görünürlük davranışı UI'da yeniden uygulanmaz.

### Draft

- Composer'daki yazılmış içerik gönderim tamamlanana veya kullanıcı açıkça silene kadar korunur.
- Ağ hatası taslağı temizlemez.
- Validation hatası taslağı temizlemez.
- Mention lookup loading/error taslağı temizlemez.
- Başarılı gönderim taslağı temizler.
- İçerik bulunan composer kapatılırken discard confirmation gösterilir.
- Vazgeç composer'a döner.
- Taslağı Sil taslağı temizler ve composer'ı kapatır.
- Backend desteği yoksa cross-device draft sync üretilmez.

### Gönderi düzenleme

1. Kullanıcının kendi düzenlenebilir gönderisi → overflow → Gönderiyi Düzenle.
2. Edit ekranı mevcut içerikle açılır.
3. Kullanıcı canonical validation kuralları içinde içeriği günceller.
4. Başarılı mutation sonrası backend'in döndürdüğü güncel post render edilir.

Kurallar:

- Değişmiş fakat kaydedilmemiş içerikle çıkılırsa discard confirmation gösterilir.
- Başkasının gönderisinde edit aksiyonu gösterilmez.
- Backend izin vermiyorsa local edit kalıcılaştırılmaz.

## Components

### Arama alanı

Token: `{components.input}`

Widget hierarchy:

```text
SearchPage
└── Scaffold
    ├── AppBar
    │   └── Text("Ara")
    └── SafeArea
        └── Column
            ├── Padding
            │   └── SearchBar | TextField
            │       ├── leading: search icon
            │       ├── hintText
            │       └── optional clear action
            └── Expanded
                └── search state
                    ├── initial
                    ├── loading
                    ├── empty
                    ├── error
                    └── result list
                    ```
                    
                    Kurallar:

Sorgu canonical arama parametresine map edilir.

Contract dışında filter, sort, cursor veya pagination parametresi üretilmez.

Sorgu temizlendiğinde önceki sonuçlar yeni sorguya aitmiş gibi gösterilmez.

Stale request güncel sorgu sonucunu overwrite etmez.

Sonuç satırları minimum 44x44px dokunma alanına sahiptir.

Kullanıcı sonucuna giderken result.username kullanılır.

Arama sonucu kullanıcı satırı

Token: {components.social-graph-list-item}

Widget hierarchy:

InkWell
└── Padding
    └── Row
        ├── CircleAvatar
        ├── Expanded
        │   └── Column(crossAxis: start)
        │       ├── Text(displayName)
        │       └── Text("@username")
        └── optional relationship action

Kurallar:

Mevcut kullanıcı satırı pattern'i reuse edilir.

Satıra dokunma → ProfilePage(result.username).

Duplicate block/report aksiyonları eklenmez.

Mention suggestion overlay

Token: {components.input}, {components.social-graph-list-item}

Widget hierarchy:

Composer
└── Stack
    ├── TextFormField
    └── mention active ise
        └── suggestion surface
            └── ConstrainedBox
                └── ListView
                    └── suggestion row
                        ├── CircleAvatar
                        └── Column
                            ├── Text(displayName)
                            └── Text("@username")

Kurallar:

Suggestion yüzeyi composer'ı kullanılmaz hale getirmez.

Klavye açıkken erişilebilir kalır.

Seçimde canonical username kullanılır.

Suggestion error full-screen composer error'a dönüşmez.

Empty suggestion taslağı etkilemez.

Contract dışı mention endpoint'i üretilmez.

Pinned post alanı

Token: {components.post-card}

Widget hierarchy:

ProfilePage
└── profile content
    ├── ProfileSummary
    ├── pinned post varsa
    │   └── Column
    │       ├── Row
    │       │   ├── Icon(push_pin_outlined)
    │       │   └── Text("Sabitlenmiş")
    │       └── PostCard(pinnedPost)
    └── profile posts

Kurallar:

Yalnız backend state varsa gösterilir.

Yeni post-card varyantı üretilmez.

Mevcut post navigation ve güvenlik davranışları korunur.

Pinned metadata görsel olarak ikincildir.

Pinned state yokluğu empty state değildir.

Mute aksiyonu

Token: {components.safety-action-menu}

Widget hierarchy:

MenuAnchor | PopupMenuButton
└── other profile actions
    └── MenuItemButton
        ├── Icon(volume_off_outlined | volume_up_outlined)
        └── Text("Sessize Al" | "Sessizden Çıkar")

Kurallar:

Yalnız başka kullanıcı profillerinde gösterilir.

Backend relationship state uygun aksiyonu belirler.

Mutation sırasında tekrar tetiklenemez.

Block/report ile mevcut security menu pattern'i reuse edilir.

Mute, block davranışı gibi yorumlanmaz.

Draft discard dialog

Token: {colors.error}

Widget hierarchy:

AlertDialog
├── title: Text("Taslak silinsin mi?")
├── content: Text("Yazdığın değişiklikler kaybolacak.")
└── actions
    ├── TextButton("Vazgeç")
    └── TextButton | FilledButton("Taslağı Sil")

Kurallar:

Boş composer kapanırken gösterilmez.

Başarılı gönderim sonrası gösterilmez.

Ağ hatası discard sayılmaz.

Destructive aksiyon açık biçimde etiketlenir.

Gönderi düzenleme ekranı

Token: {components.composer}, {components.primary-button}

Widget hierarchy:

EditPostPage
└── Scaffold
    ├── AppBar
    │   ├── leading: back
    │   └── action: FilledButton("Kaydet")
    └── SafeArea
        └── Padding
            └── Form
                └── Column
                    ├── TextFormField
                    │   ├── current content
                    │   ├── multiline
                    │   └── canonical maxLength
                    ├── character counter
                    └── validation message

Kurallar:

Edit alanı yalnız canonical editable content alanına map edilir.

Composer validation kuralları reuse edilir.

İçerik değişmemişse gereksiz mutation gönderilmez.

Loading sırasında Kaydet tekrar tetiklenemez.

Ağ hatasında düzenlenmiş local metin korunur.

Başarılı backend response güncel post state'inin kaynağıdır.

Başkasının gönderisine edit UI gösterilmez.

Screen states

Arama

Initial state

Başlık: "Ara"

Açıklama: "Kullanıcıları veya içerikleri bulmak için arama yap."

Bu durum API empty state değildir.

Loading state

Arama input'u kullanılabilir kalır.

Loading son aktif sorguya aittir.

Önceki sorgunun sonuçları yeni sorguya ait gibi gösterilmez.

Empty state

Başlık: "Sonuç bulunamadı"

Açıklama: "Aramana uygun bir sonuç bulunamadı."

CTA yoktur.

Error state

Başlık: "Arama yapılamadı"

Açıklama: "Sonuçlar alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

401 login akışına gider.

Mention suggestions

Initial state

Mention aktif değilse suggestion yüzeyi gösterilmez.

Empty state

Eşleşme bulunamazsa inline durum gösterilebilir.

Composer taslağı korunur.

Full-screen empty state kullanılmaz.

Error state

Suggestion yüzeyinde non-blocking hata gösterilebilir.

Composer içeriği korunur.

Pinned post

Empty state

Pinned gönderi yoksa state panel gösterilmez.

Profil normal şekilde devam eder.

Error state

Pinned veri profil response'unun parçasıysa profil error semantiği canonical response'a göre uygulanır.

Sahte pinned veri üretilmez.

Mute / unmute

Success

"Kullanıcı sessize alındı."

"Kullanıcı sessizden çıkarıldı."

Error

Profil state'i korunur.

İlgili aksiyon tekrar kullanılabilir hale gelir.

401 login akışına gider.

Draft

Success

Başarılı gönderim sonrası composer taslağı temizlenir.

Başarılı edit sonrası edit taslağı temizlenir.

Error

Ağ/5xx taslağı temizlemez.

Validation taslağı temizlemez.

Mention lookup hatası taslağı temizlemez.

Gönderi düzenleme

Error state

Validation:

İlgili input altında gösterilir.

Ağ/5xx:

Düzenlenmiş metin korunur.

Kullanıcı tekrar deneyebilir.

401:

Merkezi login akışına gider.

403:

Empty veya validation state gibi gösterilmez.

404:

Canonical semantiğe göre gönderinin artık bulunamadığı durum gösterilir.

Form sahte local post ile devam etmez.

Success

"Gönderi güncellendi."

Backend'in döndürdüğü güncel post render edilir.

Navigation

Arama giriş noktası → Arama ekranı.

Arama kullanıcı sonucu → ProfilePage(result.username).

Arama gönderi sonucu → ilgili Gönderi Detayı.

Composer mention seçimi → composer içinde kalır.

Render edilmiş mention → destekleniyorsa ProfilePage(username).

Profil pinned post → Gönderi Detayı.

Başka profil güvenlik menüsü → mute/unmute; route değişmez.

Kendi gönderisi overflow → EditPostPage.

Edit başarı → önceki ekrana backend'in güncel post state'iyle dönülür.

Draft discard → önceki route'a dönülür.

Do's and Don'ts

Do

Arama sonucunda backend'den gelen gerçek kullanıcı/post kimliğini kullan.

Mention seçiminde canonical username kullan.

Pinned post için mevcut post-card bileşenini reuse et.

Mute/unmute state'ini backend sonucuyla senkronize et.

Composer ve edit taslaklarını ağ hatasında koru.

Edit validation için composer kurallarını reuse et.

Mutation sonrası backend response'u kaynak kabul et.

401'i merkezi login akışına gönder.

403'ü normal empty state gibi gösterme.

Minimum 44x44px dokunma alanını koru.

Dinamik metin ölçeklendirmeyi destekle.

Don'ts

API kontratında olmayan search, mention, mute, pin, draft veya edit endpoint'i varsayma.

API kontratında olmayan query parametresi, cursor, filter veya sort üretme.

Mention için backend'de bulunmayan kullanıcıyı local string üzerinden gerçek entity kabul etme.

Pinned state'i yalnız local state ile kalıcılaştırma.

Mute state'ini yalnız optimistic state ile kalıcı kaynak kabul etme.

Backend desteği yokken cross-device draft sync sunma.

Başkasının gönderisinde Gönderiyi Düzenle gösterme.

Arama sonucu yokluğunu network error'a dönüştürme.

Mention suggestion hatasında composer taslağını temizleme.

Kullanıcının kendi profilinde mute aksiyonu gösterme.

Yeni role, permission, moderation status veya sosyal davranış üretme.

---

Feature: Öncelik 2 sosyal deneyim akışları

Scope

Bu feature profil merkezli sosyal graf deneyimini tamamlar:

Profilde takipçi ve takip edilen sayılarını görüntüleme.

Takipçi listesini açma.

Takip edilenler listesini açma.

Sosyal graf listesinden kullanıcı profiline geçme.

Başka kullanıcıyı takip etme.

Başka kullanıcıyı takipten çıkarma.

Başka kullanıcı profillerinde ilişki durumuna göre doğru CTA'yı gösterme.

“Takip Ettiklerim” feed filtresi kabul yüzeyini contract-gated olarak tasarlama.

“Seni takip ediyor” ve “Karşılıklı takip” ilişki göstergelerini contract-gated olarak tasarlama.

Loading, empty, error ve mutation durumlarını tutarlı biçimde ele alma.

Tüm endpoint, response alanı ve permission davranışları canonical API sözleşmesinden map edilir.

UI hiçbir zaman sözleşmede bulunmayan endpoint, query parametresi, response alanı veya sosyal ilişki durumu üretmez.

“Takip Ettiklerim” ve ilişki göstergeleri kabul kapsamının zorunlu yüzeyleridir. Canonical contract desteğinin bulunmaması bu yüzeyleri tasarım kapsamından çıkarmaz; bunun yerine her yüzey için açık bir contract-unavailable durumu tanımlanır.

Takip Ettiklerim feed filtresi — contract-gated

Feed filtre kontrolünde “Tümü” ve “Takip Ettiklerim” seçenekleri birlikte görünür.

“Takip Ettiklerim” seçeneği canonical contract desteği bulunmadığında gizlenmez, kaldırılmaz veya kapsam dışı sayılmaz.

Contract mevcutsa yalnız canonical endpoint/query/response kullanılır ve seçili “Takip Ettiklerim” yüzeyi loading, success, empty ve error state'lerini gösterir.

Contract henüz mevcut değilse seçili “Takip Ettiklerim” yüzeyi contract-unavailable state gösterir:

Başlık: “Takip Ettiklerim”.

Açıklama: “Bu akış şu anda kullanılamıyor.”

Yeni endpoint, query parametresi veya client-side takip listesi birleştirmesi üretilmez.

Kullanıcı “Tümü” seçeneğine geri dönebilir.

Contract-unavailable, empty state değildir; takip edilen kullanıcı olmadığı anlamına gelmez.

Profil ilişki göstergeleri — contract-gated

Başka kullanıcı profili tasarımında iki ayrı ilişki göstergesi yüzeyi bulunur:

“Seni takip ediyor”.

“Karşılıklı takip”.

Canonical relationship metadata bu durumları desteklediğinde etiketler yalnız backend tarafından doğrulanan ilişki state'ine göre gösterilir.

“Seni takip ediyor”, görüntülenen kullanıcının current user'ı takip ettiği canonical state'i temsil eder.

“Karşılıklı takip”, iki yönlü takip ilişkisinin canonical olarak doğrulandığı state'i temsil eder.

Canonical contract bu ilişki metadata'sını henüz sağlamıyorsa bu acceptance yüzeyleri tasarımdan çıkarılmaz. Profil içinde relationship metadata alanı korunur ve contract-unavailable davranışı tanımlanır; tahmini “Seni takip ediyor” veya “Karşılıklı takip” etiketi üretilmez.

Contract desteği geldiğinde aynı relationship metadata alanı gerçek canonical state ile güncellenir; yeni ve paralel bir UI yüzeyi oluşturulmaz.

Follow/unfollow CTA state'i ile “Seni takip ediyor” / “Karşılıklı takip” metadata state'i birbirinin yerine kullanılmaz.

Bu iki acceptance yüzeyi contract desteği bulunmadığı gerekçesiyle gizlenemez, kaldırılamaz veya sonraki faza ertelenmiş sayılmaz.

“Takip Ettiklerim” yüzeyi contract-unavailable durumda da kullanıcı tarafından görülebilir kalır; yalnız veri isteği üretilmez.

“Seni takip ediyor” ve “Karşılıklı takip” yüzeyleri için contract-unavailable durumunun tasarlanması zorunludur; canonical ilişki verisi bulunmadan tahmini ilişki etiketi üretilmez.

User flows

Profil → sosyal graf

Profil yüklenir.

followerCount ve followingCount canonical profile response'tan gösterilir.

“Takipçi” sayacına dokunma → FollowersPage(profile.username).

“Takip” sayacına dokunma → FollowingPage(profile.username).

Açılan sosyal graf ekranı kendi route username bağlamını korur.

Başka profil görüntülenirken endpoint current-user username ile değiştirilmez.

Sosyal graf listesindeki kullanıcı satırına dokunma → ProfilePage(row.username).

Takipçiler

FollowersPage(username) route parametresindeki profile ait takipçileri yükler.

Başlık: “Takipçiler”.

Liste canonical followers response'una göre render edilir.

Her satır canonical kullanıcı kimliği ve username değerini kullanır.

Satıra dokunulduğunda ilgili profil açılır.

Liste boşsa empty state gösterilir.

Network veya 5xx hatası empty state gibi gösterilmez.

401 merkezi login akışına gider.

403 normal empty state değildir.

Yeniden deneme mevcut route username bağlamını korur.

Takip edilenler

FollowingPage(username) route parametresindeki profile ait takip edilen hesapları yükler.

Başlık: “Takip Edilenler”.

Liste canonical following response'una göre render edilir.

Her satır canonical kullanıcı kimliği ve username değerini kullanır.

Satıra dokunulduğunda ilgili profil açılır.

Liste boşsa empty state gösterilir.

Network veya 5xx hatası empty state gibi gösterilmez.

401 merkezi login akışına gider.

403 normal empty state değildir.

Yeniden deneme mevcut route username bağlamını korur.

Profilde follow / unfollow

Başka profil:

isFollowedByCurrentUser=false → “Takip Et”.

isFollowedByCurrentUser=true → “Takibi Bırak”.

Kendi profilinde follow/unfollow CTA gösterilmez; mevcut profil düzenleme davranışı korunur.

Takip Et:

Canonical follow endpoint'i profile.username ile çağrılır.

Mutation süresince yalnız ilgili relationship CTA loading/disabled olur.

Aynı mutation tekrar tetiklenemez.

Başarı response'u canonical relationship state ile eşleşmelidir.

Başarı sonrası profil state'i backend sonucuyla senkronize edilir.

İlgili açık sosyal graf read state'i invalidate/refetch edilir.

Başarısız mutation'da önceki doğrulanmış relationship state korunur.

Takibi Bırak:

Canonical unfollow endpoint'i profile.username ile çağrılır.

Mutation süresince yalnız ilgili relationship CTA loading/disabled olur.

Aynı mutation tekrar tetiklenemez.

Başarı sonrası profil state'i backend sonucuyla senkronize edilir.

İlgili açık sosyal graf read state'i invalidate/refetch edilir.

Başarısız mutation'da önceki doğrulanmış relationship state korunur.

Sosyal graf satırında relationship aksiyonu

Canonical response satır bazında ilişki aksiyonunu güvenilir biçimde destekliyorsa mevcut relationship CTA pattern'i reuse edilebilir.

Canonical response gerekli ilişki bilgisini vermiyorsa liste satırında tahmini follow/unfollow butonu üretilmez.

Satırın ana navigasyon davranışı her durumda ProfilePage(row.username) olur.

Mutation aksiyonu ile satır navigasyonu birbirine karıştırılmaz.

Takip Ettiklerim feed filtresi — contract-gated

Feed ekranının sosyal deneyim yüzeyinde iki seçenek bulunur:

“Tümü”.

“Takip Ettiklerim”.

“Tümü” canonical GET /api/v1/feed davranışını kullanır.

“Takip Ettiklerim” seçeneği kabul kapsamının kalıcı bir parçasıdır; canonical contract bu filtreyi desteklediğinde yalnız sözleşmede tanımlanan path/query/response davranışı kullanılır.

Canonical contract “Takip Ettiklerim” için gerekli endpoint veya filtre parametresini henüz tanımlamıyorsa Mobile yeni query parametresi, alternatif endpoint veya client-side takip listesi birleştirmesi üretmez.

Bu durumda “Takip Ettiklerim” yüzeyi kaldırılmaz. Seçenek görünür kalır ve contract-unavailable durumuna geçer.

Contract-unavailable:

Başlık: “Takip Ettiklerim”.

Açıklama: “Bu akış şu anda kullanılamıyor.”

Birincil CTA yoktur.

Mevcut “Tümü” akışı çalışmaya devam eder.

Contract desteği geldiğinde aynı yüzey loading, success, empty ve error state'lerini kullanır.

Loading sırasında seçili filtre korunur.

Empty state kayıt-yok durumudur; network/5xx hatası empty state'e çevrilmez.

401 merkezi login akışına gider.

Profil ilişki göstergeleri — contract-gated

Başka kullanıcı profillerinde ilişki metadata alanı aşağıdaki kabul yüzeylerini destekler:

“Seni takip ediyor”.

“Karşılıklı takip”.

Bu etiketler yalnız canonical profile/relationship response gerekli ilişki bilgisini açıkça verdiğinde gösterilir.

“Seni takip ediyor”, canonical veri görüntülenen kullanıcının current user'ı takip ettiğini doğruladığında gösterilir.

“Karşılıklı takip”, canonical veri iki yönlü takip ilişkisini doğruladığında gösterilir.

“Karşılıklı takip” gösterildiğinde aynı anda ikinci bir “Seni takip ediyor” etiketi tekrarlanmaz.

Follow/unfollow CTA state'i bu göstergelerin yerine kullanılmaz; CTA current user → profile ilişkisini, göstergeler profile → current user veya karşılıklı ilişkiyi temsil eder.

Canonical contract ters yön ilişki veya karşılıklılık bilgisini henüz sağlamıyorsa UI boolean tahmin etmez, followers/following listelerini client-side çaprazlayarak ilişki üretmez ve sahte etiketi göstermez.

Bu durumda ilişki göstergesi yüzeyi kapsamdan çıkarılmaz; contract-unavailable state olarak ayrılmış metadata alanı kullanılır.

Contract-unavailable:

İlişki iddiası taşıyan “Seni takip ediyor” veya “Karşılıklı takip” etiketi gösterilmez.

Profilin mevcut follow/unfollow CTA'sı canonical state ile çalışmaya devam eder.

Yeni endpoint, query parametresi veya response alanı üretilmez.

Components

Profil sosyal sayaçları

Token: {components.social-summary-card}

Widget hierarchy:

Card
└── Padding
    └── Row
        ├── InkWell
        │   └── Column
        │       ├── Text(followerCount)
        │       └── Text("Takipçi")
        └── InkWell
            └── Column
                ├── Text(followingCount)
                └── Text("Takip")

fluttertemplates: Social Profile — /widgets/social

Kurallar:

Sayaçlar canonical profile response değerlerinden gelir.

Takipçi sayacı → FollowersPage.

Takip sayacı → FollowingPage.

Sayaç varsa karşılık gelen liste ekranı ve empty/error state zorunludur.

Takipçiler / Takip Edilenler listesi

Token: {components.social-graph-list}

Widget hierarchy:

Scaffold
├── AppBar
│   └── Text("Takipçiler" | "Takip Edilenler")
└── body
    └── state
        ├── loading: ListView
        │   └── shimmer rows
        ├── success: ListView
        │   └── user row
        │       ├── CircleAvatar
        │       ├── Column
        │       │   ├── Text(displayName if available)
        │       │   └── Text("@username")
        │       └── optional canonical relationship action
        ├── empty: EmptyState
        └── error: ErrorState
            └── FilledButton("Yeniden Dene")

fluttertemplates: User Search / Social Profile — /widgets/social

Kurallar:

Satır tap → ProfilePage(row.username).

Relationship action yalnız canonical row state bunu destekliyorsa gösterilir.

404 veya canonical “kayıt yok” semantiği empty state'tir.

Network/5xx/403 empty olarak gösterilmez.

Takip Et / Takibi Bırak CTA

Token: {components.relationship-action}

Widget hierarchy:

FilledButton | OutlinedButton
├── state: idle
│   └── Text("Takip Et" | "Takibi Bırak")
└── state: loading
    └── SizedBox
        └── CircularProgressIndicator

fluttertemplates: Social Profile — /widgets/social

Kurallar:

Kendi profilinde gösterilmez.

Mutation sırasında disabled olur.

Başarısız mutation mevcut doğrulanmış state'i bozmaz.

CTA metni yalnız canonical relationship state'ten türetilir.

Takip Ettiklerim feed filtresi — zorunlu kabul yüzeyi

Token: {components.following-feed-filter}

Bu yüzey kabul kapsamının zorunlu parçasıdır ve iki contract durumuyla tasarlanır.

Contract available

Canonical feed contract takip edilen hesaplarla sınırlı bir feed scope/filter tanımlıyorsa Ana Akış içinde “Takip Ettiklerim” seçimi render edilir.

Widget hierarchy:

FeedPage
├── AppBar
└── body
    └── Column
        ├── feed filter region
        │   └── SegmentedButton | FilterChip row
        │       ├── canonical default feed option
        │       └── option: Text("Takip Ettiklerim")
        └── Expanded
            └── feed state
                ├── loading: feed skeleton
                ├── success: ListView
                │   └── PostCard*
                ├── empty: EmptyState
                └── error: ErrorState
                    └── FilledButton("Yeniden Dene")

fluttertemplates: Activity Feed — /widgets/social

Kurallar:

Seçim mevcut feed route'u içinde kalır.

Yeni NavigationBar veya NavigationDrawer destination oluşturulmaz.

Request yalnız canonical contract'ta tanımlanan endpoint, parametre ve değer mapping'iyle oluşturulur.

UI kendi following, followedOnly, scope veya benzeri query parametresi/değeri üretmez.

Filtre değişiminde önceki liste yeni scope altında stale içerik olarak gösterilmez.

Loading yalnız feed gövdesini etkiler.

Empty state filtre bağlamını açıkça belirtir.

Retry aynı seçili filtreyi korur.

Contract unavailable

Canonical feed contract takip edilen hesaplarla sınırlı bir request mapping'i tanımlamıyorsa yüzey tasarımdan çıkarılmaz.

Widget hierarchy:

FeedPage
├── AppBar
└── body
    └── Column
        ├── feed filter region
        │   └── Tooltip / helper region
        │       └── disabled FilterChip
        │           └── Text("Takip Ettiklerim")
        ├── Text("Takip Ettiklerim görünümü şu anda kullanılamıyor.")
        └── Expanded
            └── canonical default feed

Kurallar:

Disabled yüzey herhangi bir HTTP isteği üretmez.

Kullanıcıya default feed gösterilmeye devam edilir.

“Takip Ettiklerim” seçilmiş gibi sahte state oluşturulmaz.

Yeni endpoint veya parametre icat edilmez.

Bu durum kabul yüzeyinin tasarlandığını kanıtlar; kriter kapsamdan çıkarılmış sayılmaz.

Profil ilişki göstergeleri — zorunlu kabul yüzeyi

Token: {components.relationship-indicators}

Bu yüzey “Seni takip ediyor” ve “Karşılıklı takip” durumlarını kapsar ve iki contract durumuyla tasarlanır.

Contract available

Canonical profile/relationship response gerekli ilişki bilgisini güvenilir biçimde sağlıyorsa başka kullanıcı profilinde relationship CTA yakınında gösterilir.

Widget hierarchy:

ProfileHeader
└── Column
    ├── identity row
    │   ├── CircleAvatar
    │   └── Column
    │       ├── Text(displayName)
    │       └── Text("@username")
    ├── relationship indicator region
    │   └── Wrap
    │       ├── optional AssistChip
    │       │   └── Text("Seni takip ediyor")
    │       └── optional AssistChip
    │           └── Text("Karşılıklı takip")
    └── relationship CTA
        └── FilledButton | OutlinedButton

fluttertemplates: Social Profile — /widgets/social

Kurallar:

“Seni takip ediyor” yalnız canonical response bunun doğru olduğunu açıkça gösteriyorsa görünür.

“Karşılıklı takip” yalnız canonical response iki yönlü ilişkiyi güvenilir biçimde belirlemeye izin veriyorsa görünür.

Göstergeler tahmin amacıyla follower/following count değerlerinden türetilmez.

CTA state'i ile indicator state'i farklı kaynaklardan geliyorsa biri diğerinden varsayılmaz.

Kendi profilinde bu relationship göstergeleri gösterilmez.

Mutation sonrasında canonical response/refetch ile yeniden hesaplanır.

Contract unavailable

Canonical response gerekli ilişki bilgisini sağlamıyorsa kabul yüzeyi tasarımdan çıkarılmaz; nötr bir unavailable durumu tanımlanır.

Widget hierarchy:

ProfileHeader
└── Column
    ├── identity row
    ├── relationship indicator region
    │   └── Text("İlişki bilgisi kullanılamıyor")
    └── canonical relationship CTA, available ise

Kurallar:

“Seni takip ediyor” veya “Karşılıklı takip” etiketi sahte olarak gösterilmez.

Nötr unavailable metni ilişki yönü iddia etmez.

Bu durum takip/follow CTA'sını canonical state destekliyorsa engellemez.

Response alanı veya ikinci bir ilişki endpoint'i tasarım tarafından uydurulmaz.

Canonical destek eklendiğinde aynı region available hierarchy'ye geçer; navigation yapısı değişmez.

Screen states

FollowersPage

Empty state:

title: "Henüz takipçi yok"

description: "Bu profili takip eden hesaplar burada görünecek."

primaryCta: yok

Error state:

title: "Takipçiler yüklenemedi"

description: "Bağlantını kontrol edip yeniden deneyebilirsin."

primaryCta: "Yeniden Dene"

401:

merkezi login/session akışına yönlendir.

403:

title: "Bu listeye erişilemiyor"

empty state olarak gösterilmez.

FollowingPage

Empty state:

title: "Henüz takip edilen hesap yok"

description: "Bu profilin takip ettiği hesaplar burada görünecek."

primaryCta: yok

Error state:

title: "Takip edilenler yüklenemedi"

description: "Bağlantını kontrol edip yeniden deneyebilirsin."

primaryCta: "Yeniden Dene"

401:

merkezi login/session akışına yönlendir.

403:

title: "Bu listeye erişilemiyor"

empty state olarak gösterilmez.

Takip Ettiklerim feed filtresi

Available empty state:

title: "Takip ettiklerinden henüz gönderi yok"

description: "Takip ettiğin hesapların gönderileri burada görünecek."

primaryCta: yok

Available error state:

title: "Gönderiler yüklenemedi"

description: "Bağlantını kontrol edip yeniden deneyebilirsin."

primaryCta: "Yeniden Dene"

Contract-unavailable:

title: "Takip Ettiklerim"

description: "Takip Ettiklerim görünümü şu anda kullanılamıyor."

primaryCta: yok

default feed görünmeye devam eder.

İlişki göstergeleri

Available:

exact canonical state'e göre “Seni takip ediyor” ve/veya “Karşılıklı takip” gösterilir.

Contract-unavailable:

title: yok

description: "İlişki bilgisi kullanılamıyor."

ilişki yönü tahmin edilmez.

Follow / unfollow mutation

Success:

Takip sonrası snackbar: "Takip edildi."

Takipten çıkarma sonrası snackbar: "Takipten çıkarıldı."

Error:

title: yok

snackbar: "İşlem tamamlanamadı. Tekrar deneyin."

doğrulanmış önceki relationship state korunur.

Navigation

ProfilePage(username) → “Takipçi” sayacı → FollowersPage(username).

ProfilePage(username) → “Takip” sayacı → FollowingPage(username).

FollowersPage kullanıcı satırı → ProfilePage(row.username).

FollowingPage kullanıcı satırı → ProfilePage(row.username).

“Takip Ettiklerim” mevcut FeedPage içinde filtre yüzeyidir; yeni top-level destination değildir.

Relationship indicator kullanıcıyı yeni route'a götürmez; profil bağlamında salt-okunur durum göstergesidir.

Follow/unfollow CTA profil route'unu değiştirmez.

Route username hiçbir durumda current-user username ile sessizce değiştirilmez.

Do's and Don'ts

Do

Canonical contract tarafından sağlanan relationship state'i kullan.

Feed filtresini contract available/unavailable olarak açık tasarla.

Relationship göstergelerini contract available/unavailable olarak açık tasarla.

Sayaçlardan gerçek liste ekranlarına navigasyon sağla.

404/kayıt-yok semantiğini empty state olarak ele al.

Retry sırasında mevcut route ve filtre bağlamını koru.

Don't

“Takip Ettiklerim” kriterini canonical destek yok diye tasarım kapsamından çıkarma.

“Seni takip ediyor / Karşılıklı takip” kriterini canonical destek yok diye silme.

Canonical contract'ta olmayan query parametresi veya endpoint üretme.

Follower/following count üzerinden ilişki yönü tahmin etme.

Network/5xx/403 durumlarını empty state gibi gösterme.

Başka profil route'unu current-user username ile değiştirme.

---

Öncelik 2 Sosyal Deneyim Kontrat Kapıları

Scope
Bu feature, Öncelik 2 sosyal deneyim akışlarının ürün ve API kontratıyla uyumlu çalışması için gerekli tasarım kapılarını tanımlar.

### Modular design ve doğrulama kabul kapısı
Bu dosya design/features/manifest.yaml içindeki features listesinde benzersiz id, file, title ve api_contract_refs alanlarıyla kayıtlı olmalıdır.
Manifest kaydı olmadan bu feature tamamlanmış kabul edilmez; orphan feature design auto_verify hatasıdır.
Modular compile sonucunda bu feature içeriği üretilen design/DESIGN.md kapsamına dahil olmalıdır.
design/DESIGN.md doğrudan düzenlenmez; doğruluk kaynağı bu feature dosyası ve manifest kaydıdır.
- Uygulama build veya testlerinin başarılı olması design katmanının geçtiği anlamına gelmez.
- Design kabulü için manifest bütünlüğü, modular compile ve bu feature'daki design kontrat kapıları ayrı olarak başarılı olmalıdır.

- Bu dosya design/features/manifest.yaml içindeki features listesinde benzersiz id, file, title ve api_contract_refs alanlarıyla kayıtlı olmalıdır.
- Manifest kaydı olmadan bu feature tamamlanmış kabul edilmez; orphan feature design auto_verify hatasıdır.
- Modular compile sonucunda bu feature içeriği üretilen design/DESIGN.md kapsamına dahil olmalıdır.
- design/DESIGN.md doğrudan düzenlenmez; doğruluk kaynağı bu feature dosyası ve manifest kaydıdır.
Amaçları:
Sosyal deneyim ekranlarında yalnızca desteklenen davranışların kullanıcıya sunulması.
Veri bekleme, boş sonuç, hata ve başarılı veri durumlarının açık biçimde tasarlanması.
Liste, detay ve profil geçişlerinin tutarlı navigasyon davranışı göstermesi.
API tarafından desteklenmeyen bir davranışın yalnızca arayüz seviyesinde varmış gibi gösterilmemesi.
Kullanıcının yaptığı sosyal aksiyonlardan sonra ekrandaki durumun güncel sonucu açık biçimde yansıtması.
### Backend golden JSON ↔ mobil request body kontrat kapısı

- Mobil toJson çıktısı ve gönderilen HTTP request body, ilgili backend contract/golden JSON ile birebir aynı JSON alan adlarını, wire değerlerini ve null/omitted semantiğini kullanmalıdır.
- Backend golden JSON'da bulunmayan alan mobil tarafından eklenmez; golden JSON'da zorunlu olan alan farklı adla veya farklı veri tipiyle gönderilmez.
- UI etiketi, enum gösterim metni veya istemci modeli doğrudan wire değeri kabul edilmez; request body yalnız canonical API kontratındaki serialization değerlerinden oluşturulur.
- Backend golden JSON ile mobil request body arasında fark varsa build/test sonucu bağımsız olarak design/API kontrat kapısı kırmızı kabul edilir.
- UI veya repository katmanı kontratta bulunmayan ek request alanı üretmez.
- Alan adları istemci tarafında yeniden adlandırılmaz; backend golden JSON hangi JSON key'i tanımlıyorsa mobil aynı key'i gönderir.
- Enum/string değerleri UI metinlerinden türetilmez; canonical kontratta tanımlanan wire değerleri kullanılır.
- null, boş string ve alanın hiç gönderilmemesi birbirinin yerine kullanılmaz; backend golden JSON ve canonical API kontratındaki semantik korunur.
- Collection create işlemleri yalnız endpoint matrisindeki POST sözleşmesini, güncelleme işlemleri ise yalnız tanımlı update method/path sözleşmesini kullanır; istemci farklı method veya payload şekli tahmin etmez.
### Takip edilenler akışı kontrat kapısı

- Boss kapsamındaki Tümü ve Takip Ettiklerim ayrımı ürün hedefidir.
- Güncel backend endpoint matrisinde akış için yalnızca GET /api/v1/feed tanımlıdır.
- Takip Ettiklerim için ayrı endpoint, query parametresi veya filtre sözleşmesi tanımlı değilse mobil katman bunlardan birini tahmin ederek üretmez.
- Kontrat desteği bulunmadığı sürece Takip Ettiklerim sekmesi gerçek veri kaynağı varmış gibi aktif bir akış yüzeyi olarak sunulmaz.
- Kontrat bu ayrımı destekleyecek şekilde güncellendiğinde iki görünüm de aynı durum modelini kullanır: loading, empty, error ve success.
- Akışın kronolojik sıralaması backend kontratından gelir; istemci ek bir sıralama semantiği uydurmaz.

Components

Sosyal deneyim akışlarında ihtiyaç oldukça aşağıdaki bileşenler kullanılır:

Kullanıcı satırı veya kullanıcı kartı.

Avatar, görünen ad ve @username kimlik alanları.

Sosyal ilişki durumunu gösteren aksiyon alanı.

Gönderi kartı.

Liste bölümü ve bölüm başlığı.

Yükleniyor göstergesi.

Boş durum bileşeni.

Hata mesajı ve tekrar deneme aksiyonu.

Sayfa veya liste yenileme davranışı.

Navigasyon için dokunulabilir kullanıcı ve gönderi yüzeyleri.

Aynı sosyal aksiyon birden fazla ekranda bulunuyorsa etiket, durum ve geri bildirim davranışı tutarlı olmalıdır.

Screen states

Her veri kullanan sosyal deneyim yüzeyi aşağıdaki durumları ayırt eder:

Loading

İlk veri yüklenirken kullanıcıya yükleme durumu gösterilir.

Henüz veri alınmamışken yanlış bir boş durum gösterilmez.

Mevcut veri yenilenirken içerik gereksiz yere kaybolmamalıdır.

Empty

İstek başarıyla tamamlanmış ancak gösterilecek veri yoksa açık bir boş durum gösterilir.

Boş durum hata gibi sunulmaz.

Kullanıcının yapabileceği anlamlı bir sonraki aksiyon varsa boş durum içinde gösterilebilir.

Error

İstek başarısız olduğunda kullanıcıya anlaşılır bir hata durumu gösterilir.

Tekrar denenebilen okuma işlemlerinde tekrar deneme aksiyonu sağlanır.

Başarısız sosyal aksiyonlar başarılıymış gibi kalıcı biçimde gösterilmez.

Success

Başarılı veri yüklemesinde gerçek içerik gösterilir.

Kullanıcı tarafından gerçekleştirilen başarılı sosyal aksiyon sonrasında ilgili görsel durum güncellenir.

Sayaç, durum etiketi veya aksiyon metni kullanılıyorsa ekrandaki yeni durumla tutarlı kalır.

Navigation

Kullanıcı adı, avatar veya kullanıcıyı temsil eden dokunulabilir alan profil ekranına yönlendirir.

Gönderiyi temsil eden dokunulabilir alan, detay akışı destekleniyorsa gönderi detayına yönlendirir.

Alt sayfadan geri dönüldüğünde kullanıcı mümkün olduğunca önceki sosyal bağlamına geri döner.

Aynı hedefe giden farklı sosyal yüzeyler tutarlı navigasyon davranışı kullanır.

Sadece navigasyon amacıyla ikinci ve bağımsız bir ana uygulama kabuğu oluşturulmaz.

Navigasyon hedefi ürün veya kontrat kapsamında desteklenmiyorsa kullanıcıya çalışmayan bir geçiş sunulmaz.

---

Feature: Öncelik 3 güvenlik ve yönetim deneyimi

Scope

Bu feature güvenlik ve yetkili moderasyon deneyimini kapsar:

Başka kullanıcıyı engelleme.

Engeli kaldırma.

Engellenen hesapları görüntüleme ve listeden engeli kaldırma.

Başkasının gönderisini şikâyet etme.

Başka kullanıcı hesabını şikâyet etme.

Canonical report reason seçimi ve isteğe bağlı açıklama.

Moderator rolünde şikâyet kuyruğunu görüntüleme.

Pending, Resolved ve Dismissed durumları arasında canonical filtreleme.

Şikâyet detayını görüntüleme.

Pending şikâyeti canonical resolve aksiyonuyla sonuçlandırma.

Pending şikâyeti ayrı dismiss akışıyla kapatma.

Loading, empty, error, conflict ve success durumlarını ayrı ele alma.

UI canonical API sözleşmesinde bulunmayan endpoint, enum, role, request alanı veya response alanı üretmez.

404 cevabından kullanıcının engellenmiş olduğu sonucu çıkarılmaz.

Moderator olmayan kullanıcıya moderasyon navigation veya mutation aksiyonu gösterilmez.

Standart kullanıcı post silme davranışı moderasyon kaldırma aksiyonu yerine kullanılmaz.

Components

Profil güvenlik menüsü

Token: {components.security-overflow-menu}

Widget hierarchy:

PopupMenuButton
└── items
    ├── PopupMenuItem
    │   └── Text("Kullanıcıyı Engelle" | "Engeli Kaldır")
    └── PopupMenuItem
        └── Text("Şikâyet Et")

fluttertemplates: Popup Menu — /widgets/overlays

Kurallar:

Kendi profilinde block/report aksiyonları gösterilmez.

Engelleme state'i yalnız canonical relationship/block bilgisinden gelir.

Block seçildiğinde confirmation dialog açılır.

Mutation sırasında ilgili aksiyon tekrar tetiklenemez.

Engelleme onay dialogu

Token: {components.destructive-confirm-dialog}

Widget hierarchy:

AlertDialog
├── title: Text("Kullanıcıyı engelle?")
├── content: Text
└── actions
    ├── TextButton("İptal")
    └── FilledButton("Engelle")

fluttertemplates: Dialogs — /widgets/overlays

Kurallar:

“İptal” hiçbir mutation üretmez.

“Engelle” canonical block mutation'ını tetikler.

Loading sırasında destructive CTA disabled olur.

Başarı snackbar: "Kullanıcı engellendi."

Engellenen hesaplar listesi

Token: {components.blocked-users-list}

Widget hierarchy:

Scaffold
├── AppBar
│   └── Text("Engellenen Hesaplar")
└── body
    └── state
        ├── loading: ListView
        │   └── shimmer row*
        ├── success: ListView
        │   └── Card
        │       └── ListTile
        │           ├── leading: CircleAvatar
        │           ├── title: Text(displayName)
        │           ├── subtitle: Column
        │           │   ├── Text("@username")
        │           │   └── Text(blockedAt)
        │           └── trailing: TextButton("Engeli Kaldır")
        ├── empty: EmptyState
        └── error: ErrorState
            └── FilledButton("Yeniden Dene")

fluttertemplates: List Item / Settings — /widgets/layouts, /widgets/profile

Kurallar:

Liste yalnız canonical blocked-users response alanlarını kullanır.

Satıra follow CTA eklenmez.

Unblock sırasında yalnız ilgili satır loading/disabled olur.

Son kayıt kaldırılırsa successful empty state'e geçilir.

Başarı snackbar: "Engel kaldırıldı."

Şikâyet formu

Token: {components.report-sheet}

Widget hierarchy:

ModalBottomSheet
└── SafeArea
    └── Form
        └── Column
            ├── Text("Şikâyet Et")
            ├── RadioListTile | DropdownButtonFormField
            │   └── canonical reason options
            ├── TextFormField
            │   ├── labelText: "Açıklama"
            │   └── maxLength: 500
            └── FilledButton("Şikâyeti Gönder")

fluttertemplates: Bottom Sheets + Form — /widgets/overlays, /widgets/forms

Kurallar:

Reason seçilmeden submit aktif olmaz.

Gönderi şikâyeti canonical post target id kullanır.

Kullanıcı şikâyeti canonical user target id kullanır.

username, postId, userId, reportType gibi sözleşmede olmayan alternatif request alanları üretilmez.

Network/5xx hatasında form içeriği korunur.

Başarı snackbar: "Şikâyetiniz alındı"

Duplicate pending conflict başarılı submission gibi gösterilmez.

Moderasyon kuyruğu

Token: {components.moderation-queue}

Widget hierarchy:

Scaffold
├── AppBar
│   └── Text("Moderasyon")
└── body
    └── Column
        ├── SegmentedButton | TabBar
        │   ├── Text("Bekleyen")
        │   ├── Text("Çözümlenen")
        │   └── Text("Kapatılan")
        └── Expanded
            └── state
                ├── loading: ListView
                │   └── shimmer card*
                ├── success: ListView
                │   └── ReportCard*
                │       ├── report summary
                │       ├── status
                │       └── chevron
                ├── empty: EmptyState
                └── error: ErrorState
                    └── FilledButton("Yeniden Dene")

fluttertemplates: Dashboard / Tabbed Content — /widgets/dashboard, /widgets/layouts

Kurallar:

Yalnız Moderator rolüne gösterilir.

Filtre yalnız canonical report status değerlerine map edilir.

Filtre değişiminde eski listenin stale sonucu yeni filtre altında gösterilmez.

Retry mevcut filtreyi korur.

Moderasyon detay ve aksiyonları

Token: {components.moderation-detail}

Widget hierarchy:

Scaffold
├── AppBar
│   └── Text("Şikâyet Detayı")
└── body
    └── state
        ├── loading: detail skeleton
        ├── success: SingleChildScrollView
        │   └── Column
        │       ├── report metadata card
        │       ├── reason/details card
        │       ├── TextFormField
        │       │   ├── labelText: "Not"
        │       │   └── maxLength: 500
        │       └── action region
        │           ├── FilledButton("Çözümle")
        │           └── OutlinedButton("Kapat")
        └── error: ErrorState
            └── FilledButton("Yeniden Dene")

fluttertemplates: Detail + Edit Form — /widgets/admin

Kurallar:

Resolve yalnız canonical moderation action seçeneklerini kullanır.

Dismiss ayrı mutation davranışıdır; moderation action enum değeri gibi modellenmez.

Pending olmayan report için geçersiz aksiyon gösterilmez.

Mutation sırasında yalnız aksiyon alanı disabled/loading olur.

Başarı sonrası detay ve kuyruk state'i backend sonucuyla invalidate/refetch edilir.

Screen states

Engellenen Hesaplar

Empty state:

title: "Engellediğin hesap yok"

description: "Engellediğin hesaplar burada görünecek."

primaryCta: yok

Error state:

title: "Engellenen hesaplar yüklenemedi"

description: "Bağlantını kontrol edip yeniden deneyebilirsin."

primaryCta: "Yeniden Dene"

Success:

unblockSnackbar: "Engel kaldırıldı."

Şikâyet formu

Success:

snackbar: "Şikâyetiniz alındı"

Conflict:

description: "Bu içerik veya hesap için zaten bekleyen bir şikâyetin var."

form state korunur.

Error:

description: "Şikâyet gönderilemedi. Tekrar deneyin."

reason ve details korunur.

Moderasyon kuyruğu

Empty state:

title: "Bu durumda şikâyet yok"

description: "Seçili filtreye ait şikâyet bulunmuyor."

primaryCta: yok

Error state:

title: "Moderasyon kuyruğu yüklenemedi"

description: "Bağlantını kontrol edip yeniden deneyebilirsin."

primaryCta: "Yeniden Dene"

401:

merkezi session/login akışı.

403:

normal empty state değildir.

moderator yüzeyi gösterilmez veya yetkisiz erişim durumu gösterilir.

Moderasyon mutation

Success:

resolveSnackbar: "Şikâyet çözümlendi."

dismissSnackbar: "Şikâyet kapatıldı."

Error:

snackbar: "İşlem tamamlanamadı. Tekrar deneyin."

önceki doğrulanmış report state korunur.

Navigation

Başka kullanıcı profili → overflow → Engelle / Engeli Kaldır / Şikâyet Et.

Hesap/Güvenlik → Engellenen Hesaplar.

Başkasının gönderisi → overflow → Şikâyet Et.

Moderator navigation → Moderasyon.

Moderasyon kuyruğu → report satırı → Şikâyet Detayı.

Resolve/dismiss sonrasında route zorunlu olarak değişmez; detay ve kuyruk state'i yenilenir.

Do's and Don'ts

Do:

Canonical enum ve request alanlarını birebir kullan.

Empty, error, conflict ve unauthorized durumlarını ayır.

Destructive mutation'larda confirmation veya açık aksiyon sınırı kullan.

Moderator görünürlüğünü role göre sınırla.

Mutation sonrasında backend state'ini doğruluk kaynağı kabul et.

Don't:

404 sonucundan block nedeni çıkarma.

Moderator olmayan kullanıcıya moderation action gösterme.

Standart post delete endpoint'ini moderation remove davranışı olarak kullanma.

Client-side optimistic state'i kalıcı doğruluk kaynağı yapma.

Contract'ta olmayan reason/status/action değeri üretme.

---

Feature: Öncelik 3 güvenlik ve yönetim deneyimi

Scope

Bu feature mevcut güvenlik ve moderasyon yüzeylerini canonical API kontratıyla tamamlar:

Başka kullanıcıyı engelleme.

Başka kullanıcı üzerindeki engeli kaldırma.

Oturum sahibinin engellediği hesapları görüntüleme.

Engellenen hesaplar listesinden engeli kaldırma.

Başkasının gönderisini şikâyet etme.

Başka kullanıcı hesabını şikâyet etme.

Canonical report reason seçimi ve isteğe bağlı details girişi.

Moderator rolündeki kullanıcı için şikâyet kuyruğunu görüntüleme.

Pending, Resolved ve Dismissed moderation durumlarını canonical filtre ile görüntüleme.

Şikâyet detayını görüntüleme.

Pending şikâyeti canonical NoAction veya uygun olduğunda RemovePost aksiyonuyla resolve etme.

Pending şikâyeti ayrı dismiss işlemiyle kapatma.

Moderasyon note alanını yönetme.

Loading, empty, error, conflict ve success durumlarını tutarlı biçimde ele alma.

Tüm endpoint, request alanı, response alanı, enum, authorization ve HTTP semantiği canonical docs/api-contract.md sözleşmesinden map edilir.

UI:

API kontratında olmayan güvenlik veya moderasyon endpoint'i üretmez.

API kontratında olmayan role, report reason, report status veya moderation action üretmez.

Integer resource id değerlerini string/UUID'ye dönüştürmez.

Block nedeniyle görünmeyen kaynağın neden görünmediğini 404 response'undan tahmin etmez.

Moderasyon response'unda bulunmayan hedef gönderi içeriği, kullanıcı profili veya policy metadata üretmez.

Standart kullanıcı post delete endpoint'ini moderasyon kaldırma aksiyonu olarak kullanmaz.

Canonical API mapping

Block

Engelle:

POST /api/v1/profiles/{username}/block

Request body yoktur.

Başarı response'u:

username

isBlocked=true

Engeli kaldır:

DELETE /api/v1/profiles/{username}/block

Request body yoktur.

Başarı 204 No Content döner.

Engellenen hesaplar:

GET /api/v1/blocks

Başarılı collection response:

items[].id

items[].username

items[].displayName

items[].avatarUrl

items[].blockedAt

Boş liste 200 + {"items":[]} semantiğidir; 404 değildir.

Report

Şikâyet oluştur:

POST /api/v1/reports

Canonical request alanları:

targetType

targetId

reason

details

Canonical ReportTargetType:

Post

User

Canonical ReportReason:

Spam

Harassment

HateSpeech

Violence

SexualContent

Impersonation

Other

Enum string'leri serializer tarafından yukarıdaki casing ile birebir gönderilir.

details isteğe bağlıdır ve maksimum 500 karakterdir.

Post report:

targetType = Post

targetId = post.id

User report:

targetType = User

targetId = profile.id

Alternatif postId, userId, reportType, categoryCode veya targetIdentifier request alanı üretilmez.

Moderation

Kuyruk:

GET /api/v1/moderation/reports

Query verilmezse backend varsayılanı Pending'dir.

Canonical optional status değerleri yalnız:

Pending

Resolved

Dismissed

Detay:

GET /api/v1/moderation/reports/{reportId}

Resolve:

POST /api/v1/moderation/reports/{reportId}/resolve

Canonical request:

action

optional note

Canonical ModerationAction:

NoAction

RemovePost

note maksimum 500 karakterdir.

Dismiss:

POST /api/v1/moderation/reports/{reportId}/dismiss

Canonical request:

optional note

Dismiss bir ModerationAction enum değeri değildir; ayrı endpoint davranışıdır.

Tüm /api/v1/moderation/** yüzeyleri geçerli Bearer token yanında Moderator rolü gerektirir.

User flows

Kullanıcı engelleme

Başka kullanıcı profili → güvenlik menüsü → “Kullanıcıyı Engelle”.

Kendi profilinde block aksiyonu gösterilmez.

Kullanıcı “Kullanıcıyı Engelle” seçtiğinde confirmation dialog açılır.

“İptal”:

Dialog kapanır.

Profil state'i değişmez.

Mutation gönderilmez.

“Engelle”:

POST /api/v1/profiles/{profile.username}/block.

Request body gönderilmez.

Mutation sırasında confirmation CTA tekrar tetiklenemez.

Başarı response'undaki username ve isBlocked canonical kaynak kabul edilir.

Başarı mesajı: “Kullanıcı engellendi.”

Backend block semantiği nedeniyle eski follow ilişkileri geri getirilebilir state olarak tutulmaz.

Profil/feed/list görünürlüğü backend sonucuyla yeniden senkronize edilir.

Self-block 400 normal empty state değildir.

Hedef bulunamazsa veya görünmezse 404 canonical görünürlük semantiği uygulanır.

Engel kaldırma

Engelli kullanıcıya ait mevcut güvenlik yüzeyi veya Engellenen Hesaplar listesi → “Engeli Kaldır”.

DELETE /api/v1/profiles/{username}/block.

Mutation sırasında yalnız ilgili unblock aksiyonu loading/disabled olur.

Başarı 204 response body beklemeden tamamlanır.

Başarı mesajı: “Engel kaldırıldı.”

Unblock eski follow ilişkilerini UI'da geri oluşturmaz.

Gerekli read state backend'den invalidate/refetch edilir.

Engellenen hesaplar

Kendi hesap/profil güvenlik yüzeyi → “Engellenen Hesaplar”.

BlockedUsersPage açılır.

Sayfa GET /api/v1/blocks kullanır.

Liste yalnız oturum sahibinin engellediği hesapları render eder.

Her satır canonical:

displayName

username

avatarUrl

blockedAt

alanlarını kullanır.

Satırdaki primary yönetim aksiyonu “Engeli Kaldır”dır.

Engel kaldırma mutation'ı sırasında yalnız ilgili satır aksiyonu disabled/loading olur.

Başarıdan sonra satır canonical read state'ten kaldırılır veya liste refetch edilir.

Son satır kaldırılırsa ekran başarılı empty state'e geçer.

Engellenen hesap listesindeki kullanıcıya normal ProfilePage açılabileceği varsayılmaz; block görünürlük semantiği profile erişimini 404 yapabileceğinden satırın zorunlu navigasyonu unblock yönetimidir.

Gönderi şikâyeti

Başkasının gönderisi → overflow → “Şikâyet Et”.

Kullanıcının kendi postunda report aksiyonu gösterilmez.

Report sheet:

targetType=Post

targetId=post.id

ile açılır.

Kullanıcı canonical reason seçer.

İsteğe bağlı details girebilir.

Reason seçilmeden submit aktif olmaz.

Submit:

POST /api/v1/reports

Başarı:

201 Created

report response canonical kaynak kabul edilir.

Başarı mesajı: “Şikâyetiniz alındı.”

Report oluşturulması hedef gönderiyi UI'da otomatik olarak silmez veya moderation-removed kabul etmez.

Kullanıcı şikâyeti

Başka kullanıcı profili → güvenlik menüsü → “Şikâyet Et”.

Kendi profilinde report aksiyonu gösterilmez.

Report sheet:

targetType=User

targetId=profile.id

ile açılır.

Reason/details davranışı gönderi şikâyetiyle aynı component'i reuse eder.

Başarı mesajı: “Şikâyetiniz alındı.”

Duplicate pending report

Aynı reporter-target için mevcut Pending report nedeniyle backend 409 döndürürse:

Sheet taslağı korunur.

Yeni başarılı report state'i üretilmez.

Hedef otomatik gizlenmez.

Kullanıcıya “Bu içerik veya hesap için bekleyen bir şikâyetin zaten var.” açıklaması gösterilir.

Kullanıcı sheet'i kapatabilir.

Moderasyon kuyruğu

Moderator → Moderasyon.

Default görünüm Pending kuyruktur.

Default Pending görünümü için status query göndermek zorunlu değildir; backend query yokluğunda Pending kullanır.

Kullanıcı canonical status görünümü seçerse yalnız aşağıdaki mapping kullanılır:

Pending → status=Pending

Resolved → status=Resolved

Dismissed → status=Dismissed

Başka status, casing veya alias üretilmez.

Status değiştiğinde eski isteğin geciken cevabı yeni status sonucunu overwrite etmez.

Liste öğesi yalnız canonical moderation response alanlarını gösterir:

id

reporterUserId

targetType

targetId

reason

details

status

createdAt

resolvedAt

resolvedByUserId

API response hedef post content veya hedef kullanıcı profile summary vermediği için queue kartında bu bilgiler uydurulmaz.

Kart tap → ModerationDetailPage(report.id).

Moderasyon detayı

Detay:

GET /api/v1/moderation/reports/{reportId}

Ekranda canonical report metadata gösterilir.

status=Pending ise moderation controls gösterilir.

status=Resolved veya status=Dismissed ise aynı transition aksiyonları tekrar gösterilmez.

Pending Post report:

“İşlem Yapma” → resolve NoAction

“Gönderiyi Kaldır” → resolve RemovePost

“Şikâyeti Reddet” → dismiss

Pending User report:

“İşlem Yapma” → resolve NoAction

“Şikâyeti Reddet” → dismiss

RemovePost gösterilmez.

Canonical kontratta kullanıcı hesabını kaldıran/suspend eden ModerationAction olmadığı için User report üzerinde böyle bir aksiyon üretilmez.

Resolve: NoAction

Moderator “İşlem Yapma” seçer.

Optional note girilebilir.

POST /api/v1/moderation/reports/{reportId}/resolve

Request:

{
  "action": "NoAction",
  "note": null
}

Note varsa canonical note alanına gönderilir.

Başarı response:

status=Resolved

action=NoAction

resolved metadata

canonical kaynak kabul edilir.

Resolve: RemovePost

Yalnız targetType=Post ve status=Pending durumunda gösterilir.

Destructive confirmation olmadan mutation gönderilmez.

POST /api/v1/moderation/reports/{reportId}/resolve

Request:

{
  "action": "RemovePost",
  "note": null
}

Başarılı RemovePost sonrasında UI standart owner delete endpoint'ine ikinci istek göndermez.

Hedef postun feed/profile/like/reply görünürlüğü server-side moderasyon semantiğine bırakılır.

Dismiss

Pending report → “Şikâyeti Reddet”.

Optional note girilebilir.

POST /api/v1/moderation/reports/{reportId}/dismiss

Request:

{
  "note": null
}

Dismiss request'inde action alanı gönderilmez.

Başarı response status=Dismissed olarak render edilir.

Dismiss hedef kaynağı client-side kaldırmaz.

Components

Engellenen kullanıcı liste satırı

Token: {components.social-graph-list-item}, {components.relationship-button}

Widget hierarchy:

BlockedUserListItem
└── ConstrainedBox(minHeight: 72)
    └── Padding
        └── Row
            ├── CircleAvatar
            ├── Expanded
            │   └── Column(crossAxis: start)
            │       ├── Text(displayName)
            │       ├── Text("@username")
            │       └── Text(blockedAt)
            └── OutlinedButton("Engeli Kaldır")

Kurallar:

Mevcut kullanıcı liste satırı görsel pattern'i reuse edilir.

Row içindeki kullanıcı verisi yalnız GET /api/v1/blocks response'undan gelir.

blockedAt metadata olarak ikincil tipografide gösterilir.

Unblock butonu minimum 44x44px dokunma alanına sahiptir.

Mutation sırasında tüm liste loading'e dönmez.

Şikâyet bottom sheet

Token: {components.report-sheet}, {components.input}, {components.primary-button}

Widget hierarchy:

showModalBottomSheet
└── SafeArea
    └── Form
        └── Column(mainAxisSize: min)
            ├── drag handle
            ├── Text("Şikâyet Et")
            ├── Text("Neden şikâyet ediyorsun?")
            ├── RadioGroup | RadioListTile[]
            │   ├── Spam
            │   ├── Harassment
            │   ├── HateSpeech
            │   ├── Violence
            │   ├── SexualContent
            │   ├── Impersonation
            │   └── Other
            ├── TextFormField
            │   ├── canonical field: details
            │   ├── multiline
            │   └── maxLength: 500
            └── FilledButton("Şikâyet Et")

Kurallar:

UI etiketleri kullanıcı dilinde açıklanabilir fakat serializer canonical enum string'ini değiştirmez.

Post ve User report aynı component'i kullanır.

Target type sheet tarafından tahmin edilmez; çağıran yüzey canonical target context'i verir.

targetId integer id'dir.

Reason seçimi zorunludur.

Details isteğe bağlıdır.

Loading sırasında submit tekrar tetiklenemez.

Network/5xx, validation veya 409 durumunda reason/details taslağı korunur.

Engelleme confirmation dialog

Token: {components.safety-action-menu}, {colors.error}

Widget hierarchy:

AlertDialog
├── title: Text("Kullanıcı engellensin mi?")
├── content: Text(
│       "Bu kullanıcıyla olan takip ilişkileri kaldırılır ve içerikleri görünürlük kurallarına göre sınırlandırılır."
│   )
└── actions
    ├── TextButton("İptal")
    └── FilledButton("Engelle")

Kurallar:

Engelleme confirmation olmadan başlamaz.

UI unblock işleminin eski follow ilişkilerini geri getireceğini söylemez.

Moderasyon status seçimi

Token: {typography.label-md}, {colors.primary-container}

Widget hierarchy:

ModerationStatusControl
└── SegmentedButton | single-select FilterChip group
    ├── Text("Bekleyen")
    ├── Text("Sonuçlandırılan")
    └── Text("Reddedilen")

Canonical mapping:

Bekleyen → Pending

Sonuçlandırılan → Resolved

Reddedilen → Dismissed

Kurallar:

Görsel label enum serializer değildir.

Seçim minimum 44x44px dokunma alanına sahiptir.

Stale response aktif filtre sonucunu overwrite etmez.

Moderasyon kuyruğu kartı

Token: {components.moderation-card}

Widget hierarchy:

Card
└── InkWell
    └── Padding
        └── Column(crossAxis: start)
            ├── Row
            │   ├── Text("#reportId")
            │   └── status badge
            ├── Text(targetType + " #" + targetId)
            ├── Text(reason)
            ├── optional Text(details)
            ├── Text(createdAt)
            └── optional resolved metadata

Kurallar:

Target summary yalnız canonical targetType ve targetId üzerinden oluşturulur.

Post body, user display name veya başka hedef metadata API response'ta yoksa render edilmez.

Status badge yalnız Pending, Resolved, Dismissed canonical değerlerinden map edilir.

Moderasyon detay aksiyon alanı

Token: {components.moderation-card}, {components.primary-button}, {colors.error}

Widget hierarchy:

ModerationActionArea
└── status == Pending ise Column
    ├── TextFormField
    │   ├── label: "Moderatör notu (isteğe bağlı)"
    │   ├── multiline
    │   └── maxLength: 500
    ├── OutlinedButton("İşlem Yapma")
    ├── targetType == Post ise FilledButton("Gönderiyi Kaldır")
    └── TextButton("Şikâyeti Reddet")

Kurallar:

Tek mutation sürerken tüm moderation transition CTA'ları disabled olur.

RemovePost User report'ta render edilmez.

Note 500 karakteri aşamaz.

Pending olmayan report için transition CTA gösterilmez.

Screen states

Engellenen Hesaplar

Loading:

AppBar görünür kalır.

Liste alanında mevcut skeleton/list loading pattern'i kullanılır.

Empty:

Başlık: “Engellediğin hesap yok”

Açıklama: “Engellediğin hesaplar burada görünür.”

CTA yoktur.

Yalnız 200 + boş items response empty state'tir.

Error:

Başlık: “Engellenen hesaplar yüklenemedi”

Açıklama: “Liste alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

401 merkezi login akışına gider.

Network/5xx empty state değildir.

Unblock success:

“Engel kaldırıldı.”

Şikâyet Formu

Initial:

Reason seçilmemiş başlangıç hali API empty state değildir.

Submit disabled'dır.

Validation:

Reason zorunludur.

Details 500 karakteri aşamaz.

400 field error ilgili input/reason alanına bağlanır.

409:

Başlık: “Şikâyet zaten beklemede”

Açıklama: “Bu içerik veya hesap için bekleyen bir şikâyetin zaten var.”

Taslak korunur.

404:

“Hedef artık kullanılamıyor.”

Şikâyetin başarıyla oluşturulduğu varsayılmaz.

401:

Merkezi login akışına gider.

Network/5xx:

“Şikâyet gönderilemedi. Tekrar deneyin.”

Reason ve details korunur.

Success:

“Şikâyetiniz alındı.”

Moderasyon Kuyruğu

Loading:

Status seçimi görünür kalır.

Aktif filtre anlaşılır kalır.

Empty:

Pending:

Başlık: “Bekleyen şikâyet yok”

Açıklama: “İncelenecek yeni şikâyet bulunmuyor.”

Resolved:

Başlık: “Sonuçlandırılmış şikâyet yok”

Dismissed:

Başlık: “Reddedilmiş şikâyet yok”

Empty state yalnız başarılı items=[] response için gösterilir.

Error:

Başlık: “Moderasyon kuyruğu yüklenemedi”

Açıklama: “Şikâyetler alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

401 merkezi login akışına gider.

403:

Empty state değildir.

Yetkisiz kullanıcının moderation destination'ı normalde render edilmez.

Role state stale/yanlış olduğu için endpoint 403 dönerse moderation içeriği gösterilmez ve yetki hatası olarak ele alınır.

Moderasyon Detayı

Loading:

Report id route bağlamı korunur.

Error 404:

Başlık: “Şikâyet bulunamadı”

Sahte detail state gösterilmez.

Error 401:

Merkezi login akışına gider.

Error 403:

Yetki hatasıdır; empty state değildir.

Mutation 400:

Canonical validation/action hatası gösterilir.

Özellikle RemovePost User target için local fallback aksiyonuna çevrilmez.

Mutation 409:

Başlık: “Şikâyet zaten sonuçlandırılmış”

Açıklama: “Güncel durumu görmek için şikâyeti yeniden yükle.”

CTA: “Yeniden Yükle”

Local Pending state kalıcı kaynak kabul edilmez.

Mutation network/5xx:

Note korunur.

Report detail kaybolmaz.

CTA yeniden kullanılabilir hale gelir.

Resolve success:

Backend response'taki Resolved state render edilir.

Kuyruk ilgili status read state'leri invalidate/refetch edilir.

Dismiss success:

Backend response'taki Dismissed state render edilir.

Kuyruk ilgili status read state'leri invalidate/refetch edilir.

Navigation

Başka kullanıcı profili → güvenlik menüsü → Engelle / Engel Kaldır / Şikâyet Et.

Başkasının gönderisi → overflow → Şikâyet Et.

Kendi hesap/profil güvenlik yüzeyi → Engellenen Hesaplar.

Engellenen Hesaplar → ilgili satır → Engeli Kaldır.

Moderator-only drawer/sidebar destination → Moderasyon Kuyruğu.

Moderasyon Kuyruğu → kart → Moderasyon Detayı.

Moderasyon status seçimi aynı Moderasyon route bağlamında kalır; yeni global destination oluşturmaz.

Resolve veya dismiss mutation route'u değiştirmek zorunda değildir; başarılı canonical state detail içinde gösterilebilir.

Back navigation önceki moderation filter seçimini ve mümkünse scroll konumunu korur.

Contract boundaries

Bu feature canonical API'de bulunmayan davranışları tasarım gereksinimi olarak tanımlamaz.

Özellikle:

Mute endpoint'i Priority 3 güvenlik davranışı olarak varsayılmaz.

Kullanıcı suspend/ban moderation action'ı üretilmez.

User report üzerinde RemovePost gösterilmez.

Dismiss isminde ModerationAction enum değeri oluşturulmaz.

Moderasyon hedef postunu almak için kontratta olmayan GET /api/v1/posts/{postId} endpoint'i üretilmez.

Moderasyon hedef kullanıcı detayını almak için kontratta olmayan alternatif admin/profile endpoint'i üretilmez.

Block nedeniyle görünmeyen 404 response'un gerçek missing mi block mu olduğu tahmin edilmez.

GET /api/v1/blocks boş sonucu 404 olarak yorumlanmaz.

GET /api/v1/moderation/reports boş sonucu 404 olarak yorumlanmaz.

Standart DELETE /api/v1/posts/{postId} moderasyon RemovePost yerine kullanılmaz.

Report oluşturulması otomatik moderation kararı gibi gösterilmez.

Unblock işlemi eski follow ilişkilerini geri getirmez.

Do's and Don'ts

Do

Canonical Post ve User target type değerlerini birebir serialize et.

Canonical report reason değerlerini tek serializer üzerinden birebir kullan.

Report için targetType, targetId, reason, details alanlarını kullan.

Post report target id için post.id kullan.

User report target id için profile.id kullan.

Engellemede path için profile.username kullan.

Engellenen hesaplar için GET /api/v1/blocks kullan.

Unblock başarı 204 olduğunda response body bekleme.

Moderasyon status filtresinde yalnız Pending, Resolved, Dismissed değerlerini kullan.

Default moderation kuyruğunun Pending olduğunu koru.

Resolve için yalnız NoAction ve uygun Post hedefinde RemovePost kullan.

Dismiss için ayrı dismiss endpoint'ini kullan.

Moderation note ve report details alanlarında 500 karakter sınırını koru.

401'i merkezi login akışına gönder.

403 moderation permission hatasını empty state yapma.

409 transition/report conflict durumlarında mevcut local state'i canonical başarı gibi değiştirme.

Minimum 44x44px dokunma alanını koru.

Dynamic text scaling'i destekle.

Don't

Report request'inde postId, userId, reportType, categoryCode veya targetIdentifier üretme.

Enum değerlerini lowercase veya camelCase alias ile serialize etme.

Self-report veya self-block aksiyonunu kendi profil/post yüzeyinde gösterme.

Block sonrası follow state'i local olarak geri yükleme.

Unblock sonrası eski follow ilişkisini geri oluşturma.

Duplicate pending report 409 sonucunu success olarak gösterme.

Moderasyon response'unda olmayan target content veya user metadata uydurma.

User report için “Gönderiyi Kaldır” aksiyonu gösterme.

Canonical contract'ta olmayan user ban/suspend/delete moderation aksiyonu üretme.

Dismiss'i ModerationAction enum değeri kabul etme.

Resolve request body içine reportId ekleme.

Dismiss request body içine reportId veya action ekleme.

Moderasyon kaldırması için normal owner post delete endpoint'ini çağırma.

403'ü boş moderasyon kuyruğu gibi gösterme.

404 block semantiğini client-side açıklamaya çalışma.

Yeni role, permission, report status veya moderation action üretme.

---

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
