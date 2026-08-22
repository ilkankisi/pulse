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
