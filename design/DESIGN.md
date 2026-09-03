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
                            ├── IconButton(reply) + replyCount
                            └── IconButton(like) + likeCount
```

fluttertemplates kaynağı: Core / Card — https://fluttertemplates.dev/widgets

Kurallar:

Gönderi kartı Gönderi Detayı'nı açar.

Gönderinin sahibine silme aksiyonu gösterilebilir.

Başkasının gönderisinde “Şikâyet Et” güvenlik aksiyonu bulunabilir.

Like durumu API cevabıyla senkronize edilir.

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

Feature: Öncelik 1 ürün tamamlama deneyimi

Scope

Ürünün temel sosyal deneyimini tamamlayan yüzeyler:

Kullanıcı ve içerik araması

Gönderi oluştururken mention keşfi ve seçimi

Profilde sabitlenmiş gönderi gösterimi

Kullanıcıyı sessize alma ve sessizden çıkarma

Gönderi oluşturma taslağının korunması

Kullanıcının kendi gönderisini düzenlemesi

Tüm API, response, permission ve mutation davranışları canonical docs/api-contract.md sözleşmesinden map edilir.

UI:

API kontratında olmayan endpoint üretmez.

API kontratında olmayan query parametresi üretmez.

API kontratında olmayan role, status, enum veya action üretmez.

Backend'in desteklemediği davranışı yalnız local state ile kalıcı ürün özelliği gibi göstermez.

Canonical response field adlarını yeniden tanımlamaz.

User flows

Arama

Arama giriş noktası → Arama ekranı.

Kullanıcı sorgusunu girer.

Sonuçlar canonical backend response'una göre render edilir.

Kullanıcı sonucu → ProfilePage(result.username).

Gönderi sonucu → ilgili Gönderi Detayı.

Sonuç bulunmaması empty state'tir.

Ağ/5xx empty state değildir.

401 merkezi login akışına gider.

Yeni sorgu başladığında eski sorgunun geciken cevabı güncel sonucu overwrite etmez.

Mention

Composer içinde @ mention bağlamı başladığında suggestion yüzeyi açılır.

Suggestion verisi yalnız canonical API davranışından gelir.

Kullanıcı suggestion seçtiğinde canonical username composer'a eklenir.

Suggestion loading, empty veya error durumunda composer taslağı korunur.

Render edilmiş mention destekleniyorsa ProfilePage(username) açar.

UI backend'in tanımadığı mention identifier veya syntax üretmez.

Profil ve pinned post

Profil yüklenir.

Backend response sabitlenmiş gönderi içeriyorsa profil gönderilerinden önce pinned yüzeyi gösterilir.

Pinned gönderi mevcut post-card bileşenini yeniden kullanır.

Pinned karta dokunma → Gönderi Detayı.

Pinned state yalnız backend sonucundan gelir.

Pinned gönderi yoksa placeholder veya empty panel gösterilmez.

Mute / unmute

Başka kullanıcı profili → güvenlik/overflow menüsü.

Backend relationship state'e göre:

Sessize Al

Sessizden Çıkar

Kendi profilinde mute/unmute gösterilmez.

Mutation sırasında yalnız ilgili aksiyon loading/disabled olur.

Başarı sonrası state backend sonucuyla senkronize edilir.

Hata halinde önceki state korunur.

Feed görünürlük davranışı UI'da yeniden uygulanmaz.

Draft

Composer'daki yazılmış içerik gönderim tamamlanana veya kullanıcı açıkça silene kadar korunur.

Ağ hatası taslağı temizlemez.

Validation hatası taslağı temizlemez.

Mention lookup loading/error taslağı temizlemez.

Başarılı gönderim taslağı temizler.

İçerik bulunan composer kapatılırken discard confirmation gösterilir.

Vazgeç composer'a döner.

Taslağı Sil taslağı temizler ve composer'ı kapatır.

Backend desteği yoksa cross-device draft sync üretilmez.

Gönderi düzenleme

Kullanıcının kendi düzenlenebilir gönderisi → overflow → Gönderiyi Düzenle.

Edit ekranı mevcut içerikle açılır.

Kullanıcı canonical validation kuralları içinde içeriği günceller.

Başarılı mutation sonrası backend'in döndürdüğü güncel post render edilir.

Değişmiş fakat kaydedilmemiş içerikle çıkılırsa discard confirmation gösterilir.

Başkasının gönderisinde edit aksiyonu gösterilmez.

Backend izin vermiyorsa local edit kalıcılaştırılmaz.

Components

Arama alanı

Token: {components.input}

Widget hierarchy:

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

Canonical feed contract destekliyorsa “Takip Ettiklerim” feed görünümünü seçme.

Canonical profile/relationship response destekliyorsa “Seni takip ediyor” ve “Karşılıklı takip” ilişki göstergelerini görüntüleme.

Loading, empty, error ve mutation durumlarını tutarlı biçimde ele alma.

Tüm endpoint, response alanı ve permission davranışları canonical docs/api-contract.md sözleşmesinden map edilir.

UI:

API kontratında olmayan sosyal ilişki durumu üretmez.

“Takip Ettiklerim” feed yüzeyi contract-gated'tir; canonical feed contract bu davranışı tanımlıyorsa gösterilir ve yalnız sözleşmedeki request mapping'i kullanılır.

“Seni takip ediyor” ve “Karşılıklı takip” göstergeleri contract-gated'tir; yalnız canonical response gerekli ilişki bilgisini güvenilir biçimde sağladığında gösterilir.

Başka profil görüntülenirken current-user username kullanarak route bağlamını değiştirmez.

Takipçi ve takip edilen sayılarının kaynağı canonical profile response'tur.

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

Başlık kullanıcıya anlaşılır şekilde “Takipçiler” olarak gösterilir.

Liste canonical followers endpoint response'una göre render edilir.

Her satır canonical kullanıcı kimliği ve username değerini kullanır.

Satıra dokunulduğunda ilgili profil açılır.

Liste boşsa empty state gösterilir.

Network veya 5xx hatası empty state gibi gösterilmez.

401 merkezi login akışına gider.

403 normal empty state değildir.

Yeniden deneme mevcut route username bağlamını korur.

Takip edilenler

FollowingPage(username) route parametresindeki profile ait takip edilen hesapları yükler.

Başlık kullanıcıya anlaşılır şekilde “Takip Edilenler” olarak gösterilir.

Liste canonical following endpoint response'una göre render edilir.

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

Takip Ettiklerim feed filtresi — zorunlu contract-gated kabul yüzeyi

Bu yüzey Öncelik 2 görev kabul kapsamının zorunlu bir parçasıdır. Canonical feed contract desteğine bağlı olarak available veya contract-unavailable davranışıyla tasarlanır; contract desteğinin olmaması bu kabul kriterini kapsamdan çıkarmaz.

Available:

Canonical feed contract takip edilen hesaplarla sınırlı bir feed scope/filter tanımlıyorsa Ana Akış içinde “Takip Ettiklerim” seçimi render edilir.

Seçim mevcut feed route'u içinde kalır; yeni NavigationBar veya NavigationDrawer destination oluşturulmaz.

Request yalnız canonical contract'ta tanımlanan endpoint, parametre ve değer mapping'iyle oluşturulur.

UI kendi following, followedOnly, scope veya benzeri query parametresi/değeri üretmez.

Scope değiştiğinde eski isteğin geciken cevabı yeni seçimin sonucunu overwrite etmez.

Başarılı fakat boş canonical “Takip Ettiklerim” sonucu empty state'tir; network/5xx empty state değildir.

401 merkezi login akışına gider.

403 normal empty state değildir.

Contract-unavailable:

Canonical feed contract bu davranış için endpoint/request mapping'i tanımlamıyorsa seçim kontrolü render edilmez.

Placeholder, disabled kontrol veya client-side “Takip Ettiklerim” filtresi gösterilmez.

UI yeni endpoint, query parametresi, enum, scope değeri veya client-side kalıcı feed kaynağı üretmez.

Bu durum kabul yüzeyinin kapsamdan çıkarılması değil, zorunlu kabul yüzeyinin tasarlanmış contract-unavailable sonucudur.

Seni takip ediyor / Karşılıklı takip göstergeleri — zorunlu contract-gated kabul yüzeyleri

Bu iki gösterge Öncelik 2 görev kabul kapsamının zorunlu parçalarıdır. Her biri canonical profile/relationship response desteğine bağlı olarak available veya contract-unavailable davranışıyla ayrı ayrı değerlendirilir; canonical alanın bulunmaması kabul kriterini kapsamdan çıkarmaz.

Seni takip ediyor — available:

Canonical response görüntülenen kullanıcının current user'ı takip ettiğini açık ve güvenilir biçimde bildiriyorsa profil kimlik alanında ikincil “Seni takip ediyor” göstergesi render edilir.

Seni takip ediyor — contract-unavailable:

Canonical response bu yönlü ilişki bilgisini sağlamıyorsa gösterge render edilmez.

Local followers listesi, tahmin veya optimistic state bu ilişkiyi üretmek için kullanılmaz.

Karşılıklı takip — available:

Canonical response karşılıklı takip ilişkisini açıkça sağlıyorsa veya contract iki yönlü relationship alanlarının bu amaçla güvenilir biçimde birlikte değerlendirilmesini tanımlıyorsa “Karşılıklı takip” göstergesi render edilir.

Karşılıklı takip — contract-unavailable:

Canonical response karşılıklı ilişkiyi güvenilir biçimde belirlemeye izin vermiyorsa gösterge render edilmez.

Local followers/following listelerinin kesişiminden kalıcı ilişki durumu üretilmez.

Göstergeler follow/unfollow CTA değildir ve “Takip Et” / “Takibi Bırak” mutation davranışını değiştirmez.

“Karşılıklı takip” local followers/following liste üyeliği, liste uzunluğu veya optimistic state üzerinden kalıcı ilişki durumu olarak türetilmez.

Göstergeler ikincil metin/chip stilinde, dinamik metin ölçeklendirmeyi destekleyecek biçimde render edilir.

Contract-unavailable durumda tahmini, boş, skeleton veya disabled ilişki etiketi gösterilmez.

Components

Profil sosyal istatistikleri

Token: {components.profile-stats}

Widget hierarchy:

ProfileStats

└── Row

├── StatButton

│   ├── Text(followerCount)

│   └── Text("Takipçi")

└── StatButton

├── Text(followingCount)

└── Text("Takip")

Kurallar:

Değerler canonical profile response'tan gelir.

Sayaçlar local liste uzunluğundan türetilerek kalıcı kaynak kabul edilmez.

Her sayaç minimum 44x44px dokunma alanına sahiptir.

Dinamik metin ölçeklendirmede değer ve etiket okunabilir kalır.

Profil sahibi değiştiğinde sayaçların route bağlamı da yeni profile.username olur.

Sosyal graf liste öğesi

Token: {components.social-graph-list-item}

Widget hierarchy:

InkWell

└── Padding

└── Row

├── CircleAvatar

├── Expanded

│   └── Column

│       ├── Text(displayName)

│       └── Text("@username")

└── optional relationship action

Kurallar:

Avatar yoksa mevcut avatar fallback pattern'i reuse edilir.

Display name ve username canonical response'tan gelir.

Satıra dokunma → ProfilePage(row.username).

Tüm satırın minimum dokunma yüksekliği 44px'tir.

Uzun display name tek satırda uygun ellipsis davranışı kullanabilir.

Username görünür ve profile navigasyonunda canonical değer olarak kullanılır.

Block/report gibi farklı amaçlı aksiyonlar bu satıra duplicate edilmez.

Relationship CTA

Token: {components.relationship-button}

Durumlar:

Follow ediliyor değil → FilledButton veya mevcut primary relationship button: “Takip Et”.

Follow ediliyor → OutlinedButton veya mevcut secondary relationship button: “Takibi Bırak”.

Mutation → spinner/progress indicator + disabled state.

Kendi profilinde → relationship CTA yok.

Kurallar:

Buton etiketi backend relationship state'e göre belirlenir.

Optimistic görsel değişiklik kalıcı doğruluk kaynağı değildir.

Başarılı response sonrası canonical state kullanılır.

Hata durumunda kullanıcı tekrar deneyebilir.

Layout buton etiketinin iki durumu arasında gereksiz sıçrama üretmemelidir.

Takip Ettiklerim feed seçim kontrolü

Token: {typography.label-md}, {colors.primary-container}

Widget hierarchy:

FeedScopeControl

└── contract supports following feed ise

└── SegmentedButton | single-select FilterChip group

├── Text("Tümü")

└── Text("Takip Ettiklerim")

Kurallar:

Kontrol yalnız canonical feed contract ilgili davranışı desteklediğinde render edilir.

Görsel etiketler request parametresi değildir; seçimin backend mapping'i canonical contract'tan gelir.

Seçili durum Material 3 semantik token'larıyla anlaşılır biçimde gösterilir.

Her seçim minimum 44x44px dokunma alanına sahiptir.

Loading sırasında aktif seçim anlaşılır kalır.

Scope değişimi navigation stack'e yeni ana destination eklemez.

Profil ilişki göstergeleri

Token: {typography.body-sm}, {colors.text-secondary}

Widget hierarchy:

ProfileRelationshipContext

└── Wrap

├── canonical state varsa Text | AssistChip("Seni takip ediyor")

└── canonical state varsa Text | AssistChip("Karşılıklı takip")

Kurallar:

Her gösterge yalnız canonical response gerekli ilişki bilgisini sağladığında render edilir.

Göstergeler follow/unfollow CTA yerine kullanılmaz.

“Karşılıklı takip” local sosyal graf listelerinin kesişiminden kalıcı state olarak üretilmez.

Göstergeler profile route veya mutation davranışını değiştirmez.

Contract desteği yoksa boş chip, skeleton etiketi veya tahmini ilişki metni gösterilmez.

Screen states

FollowersPage

Initial/loading

AppBar ve route bağlamı korunur.

Liste alanında mevcut list skeleton/loading pattern'i kullanılır.

Sahte kullanıcı satırı gösterilmez.

Empty

Başlık: “Henüz takipçi yok”

Açıklama: “Bu hesabı henüz kimse takip etmiyor.”

Empty state yalnız başarılı fakat boş canonical response için gösterilir.

CTA zorunlu değildir.

Error

Başlık: “Takipçiler yüklenemedi”

Açıklama: “Takipçiler alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

401 merkezi login akışına gider.

403 empty state gibi gösterilmez.

Yeniden deneme aynı username route bağlamını kullanır.

FollowingPage

Initial/loading

AppBar ve route bağlamı korunur.

Liste alanında mevcut list skeleton/loading pattern'i kullanılır.

Sahte kullanıcı satırı gösterilmez.

Empty

Başlık: “Henüz kimseyi takip etmiyor”

Açıklama: “Bu hesabın takip ettiği kullanıcı bulunmuyor.”

Empty state yalnız başarılı fakat boş canonical response için gösterilir.

CTA zorunlu değildir.

Error

Başlık: “Takip edilenler yüklenemedi”

Açıklama: “Takip edilen hesaplar alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

401 merkezi login akışına gider.

403 empty state gibi gösterilmez.

Yeniden deneme aynı username route bağlamını kullanır.

Takip Ettiklerim feed filtresi

Contract unavailable

Canonical feed contract bu scope/filter davranışını tanımlamıyorsa seçim kontrolü render edilmez.

Bu durum kabul yüzeyinin kapsamdan kaldırılması değil, zorunlu kabul yüzeyinin tanımlı contract-unavailable state'idir.

Loading

Seçili scope görünür kalır.

Önceki scope sonucu yeni scope sonucu gibi gösterilmez.

Empty

Başlık: “Takip ettiklerinden henüz içerik yok”

Yalnız canonical “Takip Ettiklerim” isteği başarılı ve boş döndüğünde gösterilir.

Network/5xx sonucu bu empty state'e dönüştürülmez.

Error

Feed error/retry pattern'i reuse edilir.

Yeniden deneme aynı canonical feed scope mapping'ini kullanır.

401 merkezi login akışına gider.

403 empty state değildir.

İlişki göstergeleri

Available

Canonical response destekliyorsa “Seni takip ediyor” ve/veya “Karşılıklı takip” ikincil profil bağlamında render edilir.

Unavailable

Gerekli canonical alan bulunmadığında gösterge render edilmez.

Alan yokluğu profil veya sosyal graf error state'i değildir.

Bu contract-unavailable durum iki zorunlu kabul yüzeyinin kapsamdan çıkarıldığı anlamına gelmez; her gösterge için tasarlanmış sonuçtur.

Follow mutation

Loading

Relationship CTA disabled olur.

Sayfanın geri kalanı kullanılabilir kalır.

Full-screen loading kullanılmaz.

Success

Backend'in canonical relationship state'i render edilir.

Profile relationship state güncellenir.

Follower/following count gerekiyorsa canonical refetch sonucuyla güncellenir.

İlgili açık sosyal graf verisi invalidate/refetch edilir.

Error

Mutation öncesindeki doğrulanmış relationship state korunur.

CTA tekrar kullanılabilir hale gelir.

Network/5xx profil ekranını empty state'e dönüştürmez.

401 merkezi login akışına gider.

403 permission/error davranışı olarak gösterilir.

Unfollow mutation

Loading

Relationship CTA disabled olur.

Sayfanın geri kalanı kullanılabilir kalır.

Full-screen loading kullanılmaz.

Success

Backend'in canonical relationship state'i render edilir.

Profile relationship state güncellenir.

Follower/following count gerekiyorsa canonical refetch sonucuyla güncellenir.

İlgili açık sosyal graf verisi invalidate/refetch edilir.

Error

Mutation öncesindeki doğrulanmış relationship state korunur.

CTA tekrar kullanılabilir hale gelir.

Network/5xx profil ekranını empty state'e dönüştürmez.

401 merkezi login akışına gider.

403 permission/error davranışı olarak gösterilir.

Navigation

ProfilePage(username) → “Takipçi” → FollowersPage(username).

ProfilePage(username) → “Takip” → FollowingPage(username).

FollowersPage(username) → kullanıcı satırı → ProfilePage(row.username).

FollowingPage(username) → kullanıcı satırı → ProfilePage(row.username).

Canonical feed contract destekliyorsa Ana Akış içindeki “Tümü” ↔ “Takip Ettiklerim” seçimi aynı feed route'u içinde gerçekleşir; yeni global navigation destination oluşturmaz.

Follow/unfollow mutation route değiştirmez.

Başka profil görüntülenirken sosyal graf endpoint'i current user adına çevrilmez.

Back navigation önceki profil/list bağlamını korur.

Contract boundaries

Bu feature canonical API'de bulunmayan davranışları tasarım gereksinimi gibi tanımlamaz.

Özellikle:

“Takip Ettiklerim” feed filtresi kabul kapsamındaki zorunlu contract-gated bir yüzeydir; canonical feed contract ilgili scope/filter mapping'ini tanımlıyorsa available olarak gösterilir, tanımlamıyorsa contract-unavailable olarak kontrol render edilmez. Her iki durum da acceptance'ın tasarlanmış sonucudur.

“Seni takip ediyor” kabul kapsamındaki zorunlu contract-gated bir göstergedir; canonical profile veya relationship response bu ilişki bilgisini sağlıyorsa available olarak gösterilir, sağlamıyorsa contract-unavailable olur ve tahmin edilmez.

“Karşılıklı takip” kabul kapsamındaki zorunlu contract-gated bir göstergedir; canonical response karşılıklı ilişkiyi açıkça sağlıyor veya sözleşme iki yönlü alanların güvenilir biçimde birlikte değerlendirilmesine izin veriyorsa available olarak gösterilir; aksi halde contract-unavailable olur ve local listelerden türetilmez.

Yeni relationship endpoint'i veya query parametresi üretilmez.

Sosyal graf için client-side kalıcı ilişki kaynağı oluşturulmaz.

Profile count değerleri liste uzunluğundan canonical alan yerine türetilmez.

Do's and Don'ts

Do

Profil sayaçlarında canonical followerCount ve followingCount değerlerini kullan.

Sosyal graf ekranlarında route username bağlamını koru.

Satır navigasyonunda row.username kullan.

Follow/unfollow CTA'yı backend relationship state'e göre göster.

Canonical feed contract destekliyorsa “Takip Ettiklerim” seçimini mevcut Ana Akış içinde göster ve exact contract mapping'ini kullan.

Canonical relationship/profile response destekliyorsa “Seni takip ediyor” ve “Karşılıklı takip” göstergelerini ikincil profil bağlamında göster.

Contract desteğinin bulunmadığı durumda bu zorunlu contract-gated yüzeylerin tanımlı contract-unavailable davranışını uygula; tahmini veri veya placeholder üretme.

Mutation sırasında yalnız ilgili CTA'yı loading/disabled yap.

Başarı sonrası backend sonucunu doğruluk kaynağı kabul et.

Profil ve açık sosyal graf read state'ini gerektiğinde invalidate/refetch et.

401'i merkezi login akışına gönder.

403'ü empty state olarak gösterme.

Minimum 44x44px dokunma alanını koru.

Dinamik metin ölçeklendirmeyi destekle.

Don't

Başka profilin followers/following route'unda current-user username kullanma.

“Takip Ettiklerim” için canonical contract'ta bulunmayan endpoint, query parametresi, enum veya scope değeri üretme.

“Seni takip ediyor” bilgisini canonical response sağlamıyorsa local takip listelerinden veya tahminden üretme.

“Karşılıklı takip” bilgisini canonical response güvenilir biçimde desteklemiyorsa local followers/following kesişiminden kalıcı state olarak üretme.

Liste uzunluğunu canonical follower/following count yerine kalıcı kaynak kabul etme.

Başarısız follow/unfollow mutation sonrası local optimistic state'i kalıcılaştırma.

Sosyal graf satırlarına gereksiz block/report aksiyonları ekleme.

Network hatasını başarılı boş liste gibi gösterme.

Yeni role, permission, relationship status veya endpoint üretme.
