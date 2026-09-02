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

# Feature: Engelleme ve şikâyet

## Scope
Güvenlik menüsü, şikâyet sheet ve engelleme dialogu.

## Components
Güvenlik aksiyon menüsü

Token: {components.safety-action-menu}

Widget hierarchy:

```
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
```

fluttertemplates kaynağı: Dialogs & Sheets / Menus — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Minimum dokunma alanı 44x44px'tir.

Kullanıcı kendi hesabını engelleyemez.

Engelleme destructive/security aksiyonudur.

UI block/report endpoint veya enum üretmez.

Şikâyet bottom sheet

Token: {components.report-sheet}, {components.input}, {components.primary-button}

Widget hierarchy:

```
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
```

fluttertemplates kaynağı: Dialogs & Sheets / Modal Bottom Sheet — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Gönderi ve kullanıcı şikâyeti aynı component'i kullanır.

Reason canonical API kontratından map edilir.

Reason seçilmeden submit aktif olmaz.

Açıklama en fazla 500 karakterdir.

Ağ hatasında reason ve açıklama korunur.

Başarı snackbar'ı: “Şikâyetiniz alındı”.

Engelleme onay dialogu

Token: {components.safety-action-menu}, {colors.error}

Widget hierarchy:

```
showDialog
└── AlertDialog
    ├── title: Text("Kullanıcı engellensin mi?")
    ├── content: Text(
    │       "Bu kullanıcının içerik ve etkileşimleri bloklama kurallarına göre sınırlandırılacak."
    │   )
    └── actions
        ├── TextButton("İptal")
        └── FilledButton("Engelle")
```

fluttertemplates kaynağı: Dialogs & Sheets / Alert Dialog — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Engelleme confirmation olmadan başlamaz.

Loading sırasında CTA tekrar tetiklenemez.

Başarı: “Kullanıcı engellendi.”

Engeli kaldırma: “Engel kaldırıldı.”

Backend görünürlük kuralları UI'da yeniden tanımlanmaz.

## Screen states
Şikâyet Formu

Empty state

Reason seçilmemiş başlangıç hali API empty state değildir.

Error state

"Şikâyet gönderilemedi. Tekrar deneyin."

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

## Navigation
Gönderi overflow veya profil güvenlik menüsünden.

---

# Feature: Moderasyon kuyruğu

## Scope
Moderator-only şikâyet inceleme ve aksiyonlar.

## Components
Moderasyon kuyruğu kartı

Token: {components.moderation-card}

Widget hierarchy:

```
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
```

fluttertemplates kaynağı: Core / Cards — https://fluttertemplates.dev/widgets

Kurallar:

Yalnız moderator kullanıcıya gösterilir.

Status ve action değerleri docs/api-contract.md ile map edilir.

UI yeni role/status/action üretmez.

İşlenen kayıt backend sonucuna göre yenilenir veya listeden çıkarılır.

## Screen states
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

Do's and Don'ts

Do

Material 3 semantik token'larını kullan.

Takipçiler ve Takip Edilenler için aynı SocialGraphListItem bileşenini kullan.

Profil sayaçlarını minimum 44x44px dokunma alanına sahip yap.

Kendi profilim ve başka profil için aynı Followers/Following ekranlarını yeniden kullan.

Followers route'una görüntülenen profilin username değerini geçir.

Following route'una görüntülenen profilin username değerini geçir.

Takipçiler için GET /api/v1/profiles/{username}/followers kullan.

Takip Edilenler için GET /api/v1/profiles/{username}/following kullan.

Liste satırından profile geçerken row.username kullan.

Profil A → sosyal graf → Profil B → Profil B sosyal graf zincirinde her route'un kendi username bağlamını koru.

Geri navigasyonda mümkünse sosyal graf scroll konumunu koru.

Follow/unfollow durumlarını backend ile senkronize et.

404 kayıt-yok durumunu empty state olarak ele al.

401'i login akışına gönder.

403'ü normal empty state gibi gösterme.

Moderator-only UI'ı role sonucuna göre gizle.

Minimum dokunma alanını 44x44px koru.

Don'ts

Başka profilin “Takipçi” sayacına basınca current-user takipçilerini açma.

Başka profilin “Takip” sayacına basınca current-user takip listesini açma.

Profil A listesindeki Profil B satırından profile geçerken A'nın username'ini kullanma.

Followers ve Following ekranlarını ana NavigationBar/NavigationDrawer öğesi yapma.

API kontratında olmayan sosyal graf endpoint'i üretme.

API kontratında olmayan cursor, offset veya pagination query parametresi üretme.

Takipçi/takip sayaçlarını yalnız local optimistic değerle kalıcı kaynak kabul etme.

Kullanıcının kendi sosyal graf satırında “Takip Et” veya “Takibi Bırak” gösterme.

Followers ve Following için birbirinden farklı duplicate kullanıcı satırı tasarlama.

Sosyal graf satırına duplicate “Engelle” veya “Şikâyet Et” aksiyonu ekleme.

Kayıt yok durumunu "yüklenemedi" error state'e dönüştürme.

401'i normal retry paneli olarak gösterme.

Moderator olmayan kullanıcıya moderation action gösterme.

API kontratında olmayan role, status veya moderation action üretme.

Çok seviyeli thread, DM veya kapsam dışı yeni özellik ekleme.

## Navigation
Drawer Moderasyon destination (moderator rolü).

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

- Arama giriş noktası → Arama ekranı.
- Kullanıcı sorgusunu girer.
- Sonuçlar canonical backend response'una göre render edilir.
- Kullanıcı sonucu → `ProfilePage(result.username)`.
- Gönderi sonucu → ilgili Gönderi Detayı.
- Sonuç bulunmaması empty state'tir.
- Ağ/5xx empty state değildir.
- 401 merkezi login akışına gider.
- Yeni sorgu başladığında eski sorgunun geciken cevabı güncel sonucu overwrite etmez.

### Mention

- Composer içinde `@` mention bağlamı başladığında suggestion yüzeyi açılır.
- Suggestion verisi yalnız canonical API davranışından gelir.
- Kullanıcı suggestion seçtiğinde canonical username composer'a eklenir.
- Suggestion loading, empty veya error durumunda composer taslağı korunur.
- Render edilmiş mention destekleniyorsa `ProfilePage(username)` açar.
- UI backend'in tanımadığı mention identifier veya syntax üretmez.

### Profil ve pinned post

- Profil yüklenir.
- Backend response sabitlenmiş gönderi içeriyorsa profil gönderilerinden önce pinned yüzeyi gösterilir.
- Pinned gönderi mevcut post-card bileşenini yeniden kullanır.
- Pinned karta dokunma → Gönderi Detayı.
- Pinned state yalnız backend sonucundan gelir.
- Pinned gönderi yoksa placeholder veya empty panel gösterilmez.

### Mute / unmute

- Başka kullanıcı profili → güvenlik/overflow menüsü.
- Backend relationship state'e göre:
  - `Sessize Al`
  - `Sessizden Çıkar`
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
- `Vazgeç` composer'a döner.
- `Taslağı Sil` taslağı temizler ve composer'ı kapatır.
- Backend desteği yoksa cross-device draft sync üretilmez.

### Gönderi düzenleme

- Kullanıcının kendi düzenlenebilir gönderisi → overflow → `Gönderiyi Düzenle`.
- Edit ekranı mevcut içerikle açılır.
- Kullanıcı canonical validation kuralları içinde içeriği günceller.
- Başarılı mutation sonrası backend'in döndürdüğü güncel post render edilir.
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

Arama giriş noktası → SearchPage.

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

# Feature: Öncelik 2 sosyal deneyim akışları

## Scope

Bu feature mevcut canonical sosyal graf sözleşmesini daha tutarlı bir ürün deneyimine dönüştürür:

- Profil ile Takipçiler/Takip Edilenler ekranları arasında ilişki state sürekliliği
- Sosyal graf satırından takip etme ve takibi bırakma
- Kendi takipçi listesindeki bağlamsal ilişki bilgisinin gösterimi
- Follow/unfollow sonrasında profil sayaçları ve açık listelerin backend state ile yeniden senkronize edilmesi
- Feed'in canonical sözleşmede tanımlanan tek kronolojik akış olarak korunması
- Block nedeniyle görünmeyen kaynaklarda canonical 404 semantiğinin bilgi sızdırmadan gösterilmesi

Tüm API, response, permission ve mutation davranışları canonical `docs/api-contract.md` sözleşmesinden map edilir.

Canonical veri kaynakları:

- Profil: `GET /api/v1/profiles/{username}`
- Profil gönderileri: `GET /api/v1/profiles/{username}/posts`
- Takipçiler: `GET /api/v1/profiles/{username}/followers`
- Takip Edilenler: `GET /api/v1/profiles/{username}/following`
- Takip Et: `POST /api/v1/profiles/{username}/follow`
- Takibi Bırak: `DELETE /api/v1/profiles/{username}/follow`
- Ana Akış: `GET /api/v1/feed`

UI:

- API kontratında olmayan endpoint üretmez.
- Feed için API kontratında olmayan query, filter, mode veya cursor üretmez.
- Profil response'unda bulunmayan ters yönlü follow state'i varmış gibi davranmaz.
- `isFollowedByCurrentUser` alanını yalnız canonical anlamıyla kullanır.
- Follow/unfollow mutation response'undaki `isFollowing` alanını `SocialGraphUserResponse.isFollowedByCurrentUser` için yeni alias olarak modellemez.
- Sayaçları mutation sonrası yalnız local `+1/-1` hesabıyla kalıcı gerçek kabul etmez.
- 404 sonucundan block ilişkisinin varlığını çıkarmaya veya kullanıcıya açıklamaya çalışmaz.

## Contract-gated yüzeyler

### “Takip Ettiklerim” feed filtresi

Canonical sözleşmede yalnız:

`GET /api/v1/feed`

bulunur.

Bu endpoint için feed mode, following-only query veya ikinci feed endpoint'i tanımlı değildir.

Bu nedenle mevcut tasarım:

- “Takip Ettiklerim” tab/chip/filter göstermez.
- Global feed response'unu istemci tarafında following collection ile filtreleyip canonical feed gibi sunmaz.
- `/feed?filter=following`, `/following/feed` veya benzeri route üretmez.
- Boş “Takip Ettiklerim” placeholder'ı göstermez.

Canonical kontrata following-only feed semantiği eklenirse bu yüzey ayrı bir contract-aligned revizyonda açılır.

### Profilde “Seni takip ediyor / Karşılıklı takip”

Canonical profile response yalnız:

`isFollowedByCurrentUser`

alanını sağlar.

Bu alan oturum sahibinin görüntülenen kullanıcıyı takip edip etmediğini belirtir.

Başka profil header'ında hedef kullanıcının oturum sahibini takip edip etmediğini kanıtlayan ikinci bir alan yoktur.

Bu nedenle başka profil header'ında:

- “Seni takip ediyor”
- “Karşılıklı takip”

etiketleri gösterilmez.

UI ters yönlü ilişkiyi `followerCount`, `followingCount`, username eşleşmesi veya local cache üzerinden tahmin etmez.

## User flows

### Profil → sosyal graf

- Profil yüklenir.
- `followerCount` ve `followingCount` canonical profile response'tan gösterilir.
- “Takipçi” → `FollowersPage(profile.username)`.
- “Takip” → `FollowingPage(profile.username)`.
- Açılan sayfa kendi route `username` bağlamını taşır.
- Başka profil görüntülenirken current-user username ile endpoint değiştirilmez.
- Sosyal graf satırına dokunma → `ProfilePage(row.username)`.

### Profilde follow / unfollow

Başka profil:

- `isFollowedByCurrentUser=false` → “Takip Et”.
- `isFollowedByCurrentUser=true` → “Takibi Bırak”.

Takip Et:

- `POST /api/v1/profiles/{profile.username}/follow`
- Başarı response'u `isFollowing=true` olmalıdır.
- İlgili relationship CTA mutation süresince disabled/loading olur.
- Başarı sonrası profil ve ilgili açık sosyal graf read state'i invalidate/refetch edilir.

Takibi Bırak:

- `DELETE /api/v1/profiles/{profile.username}/follow`
- Başarı response'u `isFollowing=false` olmalıdır.
- İlgili relationship CTA mutation süresince disabled/loading olur.
- Başarı sonrası profil ve ilgili açık sosyal graf read state'i invalidate/refetch edilir.

Kendi profilinde follow/unfollow CTA gösterilmez.

### Sosyal graf satırında follow / unfollow

Her `SocialGraphUserResponse` satırında:

- `row.id`
- `row.username`
- `row.displayName`
- `row.avatarUrl`
- `row.isFollowedByCurrentUser`

canonical alanları kullanılır.

Başka kullanıcı satırı:

- `isFollowedByCurrentUser=false` → “Takip Et”.
- `isFollowedByCurrentUser=true` → “Takibi Bırak”.

Oturum sahibinin kendi satırında relationship CTA gösterilmez.

Mutation path her zaman:

`row.username`

ile oluşturulur.

Satırdaki ilişki aksiyonu loading iken yalnız o satırın CTA'sı disabled olur; listenin geri kalanı kullanılabilir kalır.

Başarı sonrası mutation response geçici etkileşim sonucunu doğrular, ardından kaynak liste canonical GET endpoint'inden yeniden senkronize edilir.

### Kendi takipçilerimde ilişki bağlamı

Yalnız:

`FollowersPage(myUsername)`

bağlamında listedeki her öğenin oturum sahibini takip ettiği collection üyeliğinin kendisinden bellidir.

Bu nedenle ek backend field üretmeden bağlamsal metadata gösterilebilir:

- `row.isFollowedByCurrentUser=false`
  - ikincil metin: “Seni takip ediyor”
  - CTA: “Takip Et”
- `row.isFollowedByCurrentUser=true`
  - ikincil metin: “Karşılıklı takip”
  - CTA: “Takibi Bırak”

“Karşılıklı takip” burada iki canonical gerçeğin birleşimidir:

1. Satır kullanıcısı `FollowersPage(myUsername)` collection'ında bulunduğu için oturum sahibini takip eder.
2. `isFollowedByCurrentUser=true` olduğu için oturum sahibi de satır kullanıcısını takip eder.

Bu türetme yalnız kendi takipçilerim ekranında yapılır.

Aşağıdaki bağlamlarda aynı etiketler gösterilmez:

- Başka kullanıcının Followers ekranı
- Başka kullanıcının Following ekranı
- Kendi Following ekranı
- Profil header'ı
- Feed post kartı

### Başka profilin sosyal grafı

`FollowersPage(profile.username)` ve `FollowingPage(profile.username)` aynı liste component'ini kullanır.

Burada `isFollowedByCurrentUser` yalnız oturum sahibinin satırdaki kullanıcıyı takip edip etmediğini belirler.

Collection üyeliği hedef profile göre olduğundan:

- “Seni takip ediyor”
- “Karşılıklı takip”

etiketleri üretilmez.

Satır aksiyonu yine “Takip Et / Takibi Bırak” olarak kullanılabilir.

### Follow mutation sonrası sayaç senkronizasyonu

Follow/unfollow response'u follower/following count döndürmez.

Bu nedenle UI:

- `followerCount` veya `followingCount` için local artış/azalışı kalıcı kaynak kabul etmez.
- İlgili profil read state'ini yeniden yükler.
- Açık Followers/Following collection'ını gerektiğinde canonical endpoint'ten yeniden yükler.
- Refetch tamamlandığında backend'in döndürdüğü count ve collection sonucu kaynak kabul edilir.

Optimistic animasyon kullanılırsa yalnız geçici görsel feedback'tir; hata halinde geri alınır.

### Feed

Ana Akış:

- yalnız `GET /api/v1/feed` sonucunu gösterir,
- `createdAt DESC`, eşitlikte `id DESC` canonical sırasını bozmaz,
- istemci tarafında “takip edilenler” alt kümesi üretmez,
- block görünürlüğünü yeniden hesaplamaz,
- moderasyon görünürlüğünü yeniden hesaplamaz.

Follow/unfollow sonrasında kullanıcı Ana Akış'a döndüğünde istenirse canonical feed yeniden yüklenebilir; istemci hangi postların görünmesi gerektiğini ayrıca hesaplamaz.

### Block nedeniyle görünmeyen sosyal kaynak

Profile veya profile bağlı collection isteği `404` dönerse UI:

- gerçek kullanıcı yokluğu ile block nedeniyle görünmezliği ayırt etmeye çalışmaz,
- “Bu kullanıcı seni engelledi” benzeri açıklama göstermez,
- canonical “Kullanıcı bulunamadı / içerik kullanılamıyor” deneyimini kullanır.

Sosyal graf satırındaki follow mutation `404` dönerse:

- “engellendin” sonucu çıkarılmaz,
- mutation loading kapanır,
- kaynak liste canonical endpoint'ten yenilenebilir,
- kullanıcıya genel olarak ilişkinin güncellenemediği belirtilir.

## Components

### Sosyal graf ilişki satırı

Token: `{components.social-graph-list-item}`, `{components.relationship-button}`

Widget hierarchy:

```text
InkWell
└── Padding
    └── Row
        ├── CircleAvatar
        ├── Expanded
        │   └── Column(crossAxis: start)
        │       ├── Text(displayName)
        │       ├── Text("@username")
        │       └── own FollowersPage ise optional relationship context
        │           └── Text(
        │               "Seni takip ediyor" |
        │               "Karşılıklı takip"
        │           )
        └── row.id currentUser.id değilse relationship action
            └── FilledButton | OutlinedButton
                └── loading |
                    "Takip Et" |
                    "Takibi Bırak"

Kurallar:

Tüm satır minimum 72px yüksekliği korur.

Satır ve CTA minimum 44x44px dokunma alanına sahiptir.

CTA ile satır navigation gesture'ı çakışmaz.

CTA tap profile navigation başlatmaz.

Avatar, görünen ad ve username uzun metinde CTA'yı ekran dışına itmez.

İlişki metadata'sı {typography.body-sm} ve {colors.text-secondary} kullanır.

“Karşılıklı takip” primary CTA değildir.

Relationship action state yalnız isFollowedByCurrentUser ile belirlenir.

Profil relationship alanı

Token: {components.relationship-button}

Widget hierarchy:

ProfileSummary
└── actions
    ├── own profile
    │   └── OutlinedButton("Profili Düzenle")
    └── other profile
        └── FilledButton | OutlinedButton
            └── loading |
                "Takip Et" |
                "Takibi Bırak"

Kurallar:

Profil header ters yönlü follow etiketi üretmez.

isFollowedByCurrentUser yalnız CTA state'ini belirler.

Follow mutation sırasında CTA tekrar tetiklenemez.

Başarı sonrası profile read state canonical endpoint'ten yenilenir.

Canonical feed header

Widget hierarchy:

FeedPage
└── Scaffold
    ├── AppBar
    │   └── Text("Ana Akış")
    └── body
        └── canonical feed states

Kurallar:

AppBar altında “Takip Ettiklerim” filter chip/tab gösterilmez.

UI ikinci feed mode'u varmış gibi segmented control üretmez.

Feed empty state tüm canonical feed sonucunun empty state'idir.

Screen states

Takipçiler

Loading state:

Liste skeleton'ı kullanılır.

Önceki başka profile ait satırlar yeni route bağlamında gösterilmez.

Empty state:

Başlık: “Henüz takipçi yok”

Açıklama: “Bu kullanıcıyı henüz kimse takip etmiyor.”

CTA zorunlu değildir.

items=[] empty state'tir; 404 değildir.

Error state:

Ağ/5xx:

Başlık: “Takipçiler yüklenemedi”

CTA: “Tekrar Dene”

404:

Başlık: “Kullanıcı bulunamadı”

Block nedeniyle mi yoksa gerçekten bulunamadığı mı açıklanmaz.

401 merkezi login akışına gider.

Takip Edilenler

Loading state:

Liste skeleton'ı kullanılır.

Route username bağlamı korunur.

Empty state:

Başlık: “Henüz kimseyi takip etmiyor”

Açıklama: “Bu kullanıcının takip ettiği hesap bulunmuyor.”

CTA zorunlu değildir.

items=[] empty state'tir; 404 değildir.

Error state:

Ağ/5xx:

Başlık: “Takip edilenler yüklenemedi”

CTA: “Tekrar Dene”

404:

Başlık: “Kullanıcı bulunamadı”

401 merkezi login akışına gider.

Follow / unfollow

Loading:

Yalnız ilgili relationship CTA loading/disabled olur.

Aynı mutation tekrar tetiklenmez.

Success:

Profil aksiyonu:

Follow: “Takip edildi.”

Unfollow: “Takip bırakıldı.”

Liste satırında hızlı mutationlarda snackbar zorunlu değildir; ilişki CTA'sının backend sonucuna göre güncellenmesi yeterlidir.

Error:

Mevcut canonical state korunur.

Optimistic state varsa geri alınır.

CTA yeniden kullanılabilir hale gelir.

401 login akışına gider.

404 block bilgisi olarak açıklanmaz.

Ana Akış

Empty state:

Başlık: “Akış henüz boş”

Açıklama: “İlk gönderini paylaşarak konuşmayı başlat.”

CTA: “Gönderi Oluştur”

Bu state “Takip Ettiklerim boş” anlamında kullanılmaz.

Navigation

Profil “Takipçi” → FollowersPage(profile.username).

Profil “Takip” → FollowingPage(profile.username).

Followers satırı → ProfilePage(row.username).

Following satırı → ProfilePage(row.username).

Relationship CTA → route değiştirmez.

Sosyal graf listesinden profile gidip geri dönüldüğünde kaynak route username'i korunur.

Mümkün olduğunda scroll konumu korunur.

Profil B üzerinden yeni sosyal graf ekranına geçildiğinde yeni route B'nin username'ini taşır.

Ana Akış tek canonical feed route'u olarak kalır.

Do's and Don'ts

Do

Profile ve sosyal graf endpoint'lerinde ekranda görüntülenen profilin gerçek username değerini kullan.

Liste satırlarında canonical SocialGraphUserResponse alanlarını kullan.

Follow/unfollow path'inde row.username veya profile.username kullan.

isFollowedByCurrentUser alanını oturum sahibinin hedef kullanıcıyı takip etmesi olarak yorumla.

Kendi Followers ekranındaki collection membership bilgisini yalnız o bağlamda inbound relationship kanıtı olarak kullan.

Kendi Followers ekranında iki yön de kanıtlandığında “Karşılıklı takip” gösterebilirsin.

Mutation sonrası profil sayaçlarını canonical profile GET ile yeniden senkronize et.

Mutation sonrası açık sosyal graf listesini gerektiğinde canonical collection GET ile yeniden senkronize et.

items=[] ile 404 semantiğini ayır.

401'i merkezi login akışına gönder.

404 sonucunda block varlığını açıklama.

Minimum 44x44px dokunma alanını koru.

Dinamik metin ölçeklendirmeyi destekle.

Don'ts

/api/v1/feed için following, forYou, mode, filter, tab veya benzeri query parametresi üretme.

“Takip Ettiklerim” feed'ini global feed'i local following listesiyle filtreleyerek canonical özellik gibi gösterme.

Başka profil header'ında “Seni takip ediyor” veya “Karşılıklı takip” bilgisini tahmin etme.

followerCount > 0 değerini current-user relationship kanıtı olarak kullanma.

Başka kullanıcının Followers collection üyeliğini “beni takip ediyor” şeklinde yorumlama.

isFollowing mutation response alanını profile/social-graph response şemasına yeni canonical alan olarak ekleme.

Sayaçları yalnız local +1/-1 ile kalıcılaştırma.

Follow/unfollow sırasında tüm listeyi gereksiz yere bloke etme.

404'ü “Seni engelledi” mesajına dönüştürme.

Sosyal graf ekranlarını global bottom navigation veya drawer destination yapma.

Contract dışında yeni social role, relationship status veya endpoint üretme.
