---
name: "Pulse"
description: "Açık kayıt, kronolojik kısa gönderi, tek seviyeli yanıt, beğeni, takip, kullanıcı profili, engelleme, şikâyet ve moderasyon özelliklerine sahip Material 3 mikroblog platformu."
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
- Kullanıcı profili ve gönderi listesi
- Başka kullanıcıyı engelleme ve engeli kaldırma
- Gönderi veya kullanıcı hesabını şikâyet etme
- Şikâyetlerin yetkili moderatör tarafından incelendiği moderasyon kuyruğu
- Architect API kontratında tanımlanan moderasyon aksiyonları

Özel mesaj, bildirim merkezi, anket, medya gönderisi, yer imi, yeniden paylaşım, alıntı paylaşım, hashtag trendleri ve çok seviyeli thread kapsam dışıdır.

Flutter uygulaması `ThemeData(useMaterial3: true)` ve semantik `ColorScheme` token'larıyla uygulanır.

UI katmanı API endpoint, role, report reason, moderation status veya moderation action değeri üretmez. Bu değerler canonical `docs/api-contract.md` sözleşmesinden map edilir.

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
- Kullanıcı adı, zaman, reason/status metadata `{typography.body-sm}` kullanır.
- Sayfa başlıkları `{typography.title-lg}` veya `{typography.headline-lg}` kullanır.
- Buton, chip ve navigation etiketleri `{typography.label-md}` kullanır.
- Dinamik metin ölçeklendirme desteklenir.
- Önemli içerikler sabit yükseklik nedeniyle kesilmez.

## Layout

- 600px altı: tek kolon, alt navigasyon ve gönderi oluşturma FAB'i.
- 600–1023px: NavigationRail veya drawer ve ortalanmış içerik.
- 1024px ve üzeri: solda kalıcı navigation drawer, ortada en fazla 720px içerik.
- Tüm ana ekranlarda `SafeArea` kullanılır.
- Minimum dokunma alanı 44x44px'tir.
- Akışlar `CustomScrollView` ve `SliverList` ile uygulanır.
- Klavye açıldığında form CTA'sı erişilebilir kalır.
- Bottom sheet ve dialog genişlikleri büyük ekranlarda içerik genişliğini gereksiz büyütmez.
- Moderasyon kuyruğu mobilde tek kolon, geniş ekranda yine maksimum içerik genişliği içinde tutulur.

## Elevation

- Gönderi kartları elevation 0 ve 1px outline kullanır.
- Modal bottom sheet elevation 3 kullanır.
- Floating snackbar elevation 6 kullanır.
- Dialog Material 3 varsayılan modal elevation davranışını kullanır.
- Aynı yüzeyde yoğun gölge ve border birlikte kullanılmaz.

## Shapes

- Kartlar `{rounded.md}` veya `{rounded.lg}` kullanır.
- Inputlar `{rounded.md}` kullanır.
- Avatarlar ve ana CTA'lar `{rounded.pill}` kullanır.
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
- Başka profil → Takip Et veya Takibi Bırak.
- Takip edilen hesap yoksa genel/public akış veya kullanıcının kendi gönderileri gösterilir.
- Aktif route yeniden navigation stack'e eklenmez.
- Gönderi → overflow güvenlik menüsü → “Şikâyet Et” → şikâyet bottom sheet → neden → opsiyonel açıklama → “Şikâyet Et”.
- Başka kullanıcı profili → güvenlik menüsü → “Şikâyet Et” → şikâyet bottom sheet.
- Başka kullanıcı profili → güvenlik menüsü → “Kullanıcıyı Engelle” → confirmation dialog → “Engelle”.
- Engellenmiş kullanıcı profili → “Engeli Kaldır” → engelleme durumu kaldırılır.
- Engelleme veya engeli kaldırma tamamlandığında ekran backend'in güncel sonucuna göre yenilenir.
- Şikâyet başarılı olduğunda mevcut içerik ekranı korunur ve başarı snackbar'ı gösterilir.
- Moderator yetkili kullanıcı → Moderasyon → Moderasyon Kuyruğu → Şikâyet Detayı → canonical kontratta izin verilen moderasyon aksiyonu.
- Moderator olmayan kullanıcıya moderation navigation destination veya moderation action gösterilmez.

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

Küçük ekranda ana Bottom Navigation iki öğeli kalır; moderasyon route'u yetkili kullanıcı için drawer/menu üzerinden açılabilir.

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

Gönderi kartına dokunmak Gönderi Detayı'nı açar.

Gönderinin kendi sahibine silme aksiyonu gösterilebilir.

Başkasının gönderisinde güvenlik menüsünde “Şikâyet Et” aksiyonu bulunabilir.

Like durumu API cevabıyla senkronize edilir.

Empty state'te boş SliverList yerine state panel gösterilir.

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

İçerik alanı API kontratındaki content alanına map edilir.

description, title, text veya body alternatif post alanı olarak kullanılmaz.

Boş veya yalnızca whitespace içerik gönderilmez.

Maksimum 280 karakterdir.

Loading sırasında gönder CTA'sı disabled olur.

Ağ hatasında yazılmış taslak korunur.

Profil özeti

Token: {components.profile-summary}

Widget hierarchy:

```
Column
├── Row
│   ├── CircleAvatar(size: 80)
│   └── actions
│       ├── kendi profili: OutlinedButton("Profili Düzenle")
│       └── başka profil: FilledButton | OutlinedButton
│           └── "Takip Et" | "Takibi Bırak"
├── Text(displayName)
├── Text(@username)
├── Text(bio, optional)
├── Row
│   ├── Text(followingCount)
│   └── Text(followerCount)
└── Divider
```

fluttertemplates kaynağı: Profile / Profile Header — https://fluttertemplates.dev/widgets/profile

Kurallar:

Kullanıcının kendi profilinde follow ve block aksiyonu gösterilmez.

Başka kullanıcı profilinde güvenlik menüsü ayrıca bulunur.

Profil gönderileri mevcut gönderi kartı component'iyle listelenir.

Profil güncellendi. snackbar metni korunur.

Güvenlik aksiyon menüsü

Token: {components.safety-action-menu}

Widget hierarchy:

```
PopupMenuButton | MenuAnchor
└── menuChildren
    ├── gönderi bağlamı
    │   └── MenuItemButton
    │       ├── Icon(flag_outlined)
    │       └── Text("Şikâyet Et")
    └── başka kullanıcı profili
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

Engelleme destructive/security aksiyonu olarak görsel olarak ayrıştırılır.

Şikâyet ve engelleme, mevcut post/profile widget'larını çoğaltmadan eklenir.

UI kendi block/report endpoint veya enum değerini tanımlamaz.

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
                │   └── canonical API kontratındaki reason seçenekleri
                ├── TextFormField
                │   ├── label: "Açıklama (isteğe bağlı)"
                │   ├── multiline
                │   └── maxLength: 500
                └── FilledButton("Şikâyet Et")
```

fluttertemplates kaynağı: Dialogs & Sheets / Modal Bottom Sheet — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Gönderi ve kullanıcı şikâyeti aynı component'i kullanır.

Hedef türü component parametresidir; duplicate form oluşturulmaz.

Reason değerleri canonical API kontratından map edilir.

Kullanıcıya görünen reason etiketleri Türkçedir.

Reason seçilmeden submit aktif olmaz.

Opsiyonel açıklama en fazla 500 karakterdir.

Submit sırasında CTA disabled olur.

Ağ hatasında reason ve açıklama korunur.

Başarıda sheet kapanır ve “Şikâyetiniz alındı” snackbar'ı gösterilir.

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

Engelleme mutation'ı confirmation olmadan başlamaz.

Loading sırasında “Engelle” tekrar tetiklenemez.

İşlem başarılı olduğunda backend sonucu yeniden okunur.

Başarı snackbar'ı: “Kullanıcı engellendi.”

Engeli kaldırma başarı snackbar'ı: “Engel kaldırıldı.”

API tarafından belirlenen görünürlük/etkileşim kuralları UI tarafından yeniden yorumlanmaz.

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
                    └── canonical API kontratındaki moderator actions
```

fluttertemplates kaynağı: Core / Cards — https://fluttertemplates.dev/widgets

Kurallar:

Yalnızca moderator yetkili kullanıcıya gösterilir.

Status ve action değerleri docs/api-contract.md ile birebir map edilir.

UI yeni role, status veya moderation action üretmez.

Şikâyet kaydı işlendiğinde backend'in güncel sonucuna göre kart güncellenir veya kuyruktan çıkarılır.

İçeriğin moderation sonrası görünürlüğü Architect mimarisi ve API kontratındaki kurala tabidir.

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

Ağ/5xx hatası empty state değildir.

Birincil oluşturma CTA'sı empty state body içinde bulunur; yalnız AppBar'a taşınmaz.

Loading state

Token: {components.state-panel}

Widget hierarchy:

```
Scaffold body
├── oturum kontrolü: Center(CircularProgressIndicator)
└── liste:
    CustomScrollView
    └── SliverList
        └── skeleton Card placeholders
```

fluttertemplates kaynağı: States & Errors / Loading State — https://fluttertemplates.dev/widgets/states

Kurallar:

Loading sırasında önceki kullanıcıya ait veri gösterilmez.

Mutation butonları loading sırasında tekrar tetiklenemez.

Form ekranlarında kullanıcının mevcut taslağı loading nedeniyle silinmez.

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

401 genel error state yerine oturum açma akışına yönlendirilir.

Kayıt yok anlamındaki 404 error state değildir.

Validation hataları ilgili input altında gösterilir.

Ağ hatasında form taslağı korunur.

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

Mobilde behavior: SnackBarBehavior.floating.

İşlem türüne özgü doğrulanabilir Türkçe mesaj kullanılır.

Başarı mesajı hata veya validation mesajı yerine kullanılmaz.

Screen States

Ana Akış

Empty state

Başlık: "Akış henüz boş"

Açıklama: "İlk gönderini paylaşarak konuşmayı başlat."

Birincil CTA: "Gönderi Oluştur"

Error state

Ağ veya 5xx: "Akış yüklenemedi"

CTA: "Tekrar Dene"

Kayıt yok anlamındaki 404 hata olarak gösterilmemelidir.

401 oturum açma akışına yönlendirilir.

Success

Gönderi oluşturma başarılı: "Gönderi paylaşıldı."

App bar vs body CTA

Empty durumda ana CTA body içinde "Gönderi Oluştur".

Normal durumda FAB kullanılabilir.

Aynı ekranda iki eşdeğer primary CTA kullanılmaz.

Gönderi Detayı ve Yanıtlar

Empty state

Başlık: "Henüz yanıt yok"

Açıklama: "İlk yanıtı sen yaz."

CTA: "Yanıtla"

Error state

Ana gönderi bulunamazsa: "Gönderi bulunamadı"

Ağ hatasında: "Gönderi yüklenemedi"

CTA: "Tekrar Dene"

Yanıt listesinin boş olması error değildir.

Success

Yanıt başarılı: "Yanıt gönderildi."

App bar vs body CTA

"Yanıtla" aksiyonu body içinde gönderi/yanıt bağlamında bulunur.

Profil

Empty state

Başlık: "Henüz gönderi yok"

Açıklama: "Bu kullanıcının henüz gönderisi yok."

Kendi profilinde CTA: "Gönderi Oluştur"

Başka profilde zorunlu primary empty CTA yoktur.

Error state

Ağ/5xx: "Profil yüklenemedi"

Kullanıcı bulunamazsa: "Kullanıcı bulunamadı"

CTA: "Tekrar Dene"

401 login akışına yönlendirilir.

Success

Profil güncelleme: "Profil güncellendi."

Takip başarılı: "Takip edildi."

Takibi bırakma başarılı: "Takip bırakıldı."

App bar vs body CTA

"Profili Düzenle" profil header içinde secondary aksiyondur.

Follow aksiyonu başka kullanıcı profil header'ında bulunur.

Gönderi Oluşturma

Empty state

Form başlangıcı ayrı API empty state değildir.

Error state

Validation hataları ilgili input altında gösterilir.

Ağ hatasında taslak korunur.

401 login akışına yönlendirilir.

Success

Snackbar: "Gönderi paylaşıldı."

App bar vs body CTA

Gönder CTA'sı tek primary aksiyondur.

Loading veya invalid durumda disabled olur.

Şikâyet Formu

Empty state

Formun başlangıçta reason seçilmemiş olması API empty state değildir.

Error state

Ağ/5xx: "Şikâyet gönderilemedi. Tekrar deneyin."

Validation reason alanına yakın gösterilir.

401 login akışına yönlendirilir.

Hata halinde seçili reason ve açıklama korunur.

Success

Snackbar: "Şikâyetiniz alındı"

App bar vs body CTA

Birincil CTA bottom sheet body içinde "Şikâyet Et".

AppBar üzerinde duplicate CTA bulunmaz.

Kullanıcı Engelleme

Empty state

Uygulanmaz; engellenmemiş durum normal profil state'idir.

Error state

Ağ veya sunucu hatasında mevcut profil korunur.

İşlem tekrar denenebilir.

401 login akışına yönlendirilir.

Success

Engelleme: "Kullanıcı engellendi."

Engeli kaldırma: "Engel kaldırıldı."

App bar vs body CTA

Engelleme profilin primary CTA'sı değildir.

Güvenlik/overflow menüsünden başlatılır.

Moderasyon Kuyruğu

Empty state

Başlık: "Bekleyen şikâyet yok"

Açıklama: "İncelenecek yeni şikâyet bulunmuyor."

Birincil CTA yoktur.

Error state

Ağ/5xx başlığı: "Moderasyon kuyruğu yüklenemedi"

Açıklama: "Şikâyetler alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

Kayıt bulunmaması error değildir.

401 login akışına yönlendirilir.

Moderator yetkisi olmayan kullanıcıya moderation içeriği render edilmez.

403 normal empty state gibi gösterilmez.

Success

Moderasyon aksiyonu sonrası kayıt backend'in güncel status/action sonucuna göre yenilenir.

Kullanıcıya gösterilecek aksiyon başarı metni canonical action'ın Türkçe karşılığıdır.

Design katmanı yeni moderation status veya action değeri üretmez.

App bar vs body CTA

AppBar yalnız sayfa başlığı ve ikincil yenileme kontrolünü taşıyabilir.

Moderasyon kararları ilgili şikâyet kartı veya detay body alanında gösterilir.

Do's and Don'ts

Do

Material 3 semantik token'larını kullan.

Feed, profile ve moderation listelerinde mevcut reusable kart/state bileşenlerini paylaş.

404 kayıt-yok durumunu ilgili ekranda empty state olarak ele al.

401 durumunu merkezi login akışına gönder.

Kullanıcı taslaklarını ağ hatasında koru.

Engelleme gibi etkili mutation'larda confirmation kullan.

Moderator-only UI'ı role/authorization sonucuna göre gizle.

Report reason, moderation status ve moderation action değerlerini canonical API kontratından map et.

Başarı, hata ve empty metinlerini QA'nın birebir assert edebileceği biçimde sabit tut.

Minimum 44x44px dokunma alanını koru.

Don'ts

API kontratında bulunmayan endpoint, enum, status, role veya moderation action üretme.

Engelleme davranışının backend business rule'larını UI içinde yeniden tanımlama.

Kayıt yok durumunu "yüklenemedi" error state'e dönüştürme.

401'i normal retry paneli olarak gösterme.

Moderator olmayan kullanıcıya moderation navigation veya action gösterme.

Kullanıcının kendi profilinde "Kullanıcıyı Engelle" gösterme.

Aynı şikâyet formunu gönderi ve kullanıcı için ayrı ayrı kopyalama.

Gönderi alanını description, title, text veya body adıyla yeniden adlandırma.

Çok seviyeli thread, DM, medya gönderisi veya kapsam dışı yeni özellik ekleme.
