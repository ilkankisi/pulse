---
name: "Pulse"
description: "Açık kayıt, kronolojik kısa gönderi, tek seviyeli yanıt, beğeni, takip ve kullanıcı profili özelliklerine sahip Material 3 mikroblog platformu."
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
---

## Overview

Pulse, herkesin davet kodu, e-posta domain kısıtı veya yönetici onayı olmadan kayıt olabildiği açık bir mikroblog platformudur.

MVP kapsamında:

- Kayıt olma ve JWT ile oturum açma
- Kronolojik ana akış
- En fazla 280 karakterlik gönderi
- Kullanıcının kendi gönderisini silmesi
- Beğeni
- Tek seviyeli yanıt
- Takip etme ve takibi bırakma
- Kullanıcı profili ve gönderi listesi

Özel mesaj, bildirim merkezi, anket, medya gönderisi, yer imi, yeniden paylaşım, alıntı paylaşım, hashtag trendleri ve çok seviyeli thread MVP kapsamına dahil değildir.

Flutter uygulaması `ThemeData(useMaterial3: true)` ve semantik `ColorScheme` token'larıyla uygulanır.

## Colors

- Birincil CTA ve seçili navigasyon için `{colors.primary}` kullanılır.
- Seçili navigasyon arka planı `{colors.primary-container}` kullanır.
- Beğeninin seçili durumu `{colors.tertiary}` kullanır.
- Silme ve kritik hatalar `{colors.error}` kullanır.
- Başarı mesajları `{colors.success}` kullanır.
- Gövde metni `{colors.text-primary}`, metadata `{colors.text-secondary}` kullanır.
- Bileşen kodunda sabit renk yazılmaz.
- Dark mode aynı semantik token adlarıyla ayrı `ColorScheme` üretir.

## Typography

- Gönderi metni `{typography.body-md}` kullanır.
- Görünen ad `{typography.title-md}` kullanır.
- Kullanıcı adı ve zaman `{typography.body-sm}` kullanır.
- Sayfa başlıkları `{typography.title-lg}` veya `{typography.headline-lg}` kullanır.
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

## Elevation

- Gönderi kartları elevation 0 ve 1px outline kullanır.
- Modal bottom sheet elevation 3 kullanır.
- Floating snackbar elevation 6 kullanır.
- Aynı yüzeyde yoğun gölge ve border birlikte kullanılmaz.

## Shapes

- Kartlar `{rounded.md}` veya `{rounded.lg}` kullanır.
- Inputlar `{rounded.md}` kullanır.
- Avatarlar ve ana CTA'lar `{rounded.pill}` kullanır.
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
│   │   └── NavigationDrawerDestination ("Profil")
│   └── footer: ListTile (logout, "Çıkış yap")
├── bottomNavigationBar: NavigationBar
│   └── destinations: "Ana Akış", "Profil"
├── floatingActionButton: FloatingActionButton.extended
│   └── icon: edit + label: "Gönder"
└── body: aktif ekran
```

fluttertemplates kaynağı: Navigation Drawer — https://fluttertemplates.dev/widgets/navigation

Kurallar:

Drawer, kalıcı sidebar ve alt navigasyon aynı destination modelini kullanır.

Yalnızca bir destination seçili olabilir.

Geniş ekranda alt navigasyon gizlenir.

401 genel error state yerine oturum açma akışına yönlendirilir.

Çıkış işleminde navigation stack temizlenir.

Gönderi kartı

Token: {components.post-card}

Widget hierarchy:

```
SliverList
└── item: Card
    └── InkWell
        └── Row (crossAxisAlignment: start)
            ├── CircleAvatar
            └── Expanded
                └── Column (crossAxisAlignment: start)
                    ├── Row
                    │   ├── Text (görünen ad)
                    │   ├── Text (@kullanıcı · zaman)
                    │   └── kendi gönderisiyse IconButton (more)
                    ├── Text (gönderi içeriği)
                    └── Row
                        ├── IconButton + count (yanıt)
                        ├── IconButton + count (beğeni)
                        └── Spacer
```

fluttertemplates kaynağı: Core Card / Social Feed — https://fluttertemplates.dev/widgets/social

Kurallar:

Kartın boş alanı Gönderi Detayı'nı açar.

Gönderi metni en fazla 280 karakterdir.

Beğeni optimistic uygulanabilir; hata halinde geri alınır.

Silme yalnızca gönderi sahibinde görünür.

Silme işlemi onay dialog'u gerektirir.

Yanıta yanıt ve iç içe thread oluşturulmaz.

Gönderi oluşturucu

Token: {components.composer}, {components.primary-button}

Widget hierarchy:

```
Form (key: _formKey)
└── Column
    ├── Row
    │   ├── CircleAvatar
    │   └── Expanded
    │       └── TextFormField
    │           ├── maxLength: 280
    │           ├── minLines: 3
    │           └── maxLines: null
    └── Row
        ├── Text ("Herkese açık")
        ├── Spacer
        ├── Text (kalan/280)
        └── FilledButton ("Yayınla")
```

fluttertemplates kaynağı: Forms / Inputs / Validation — https://fluttertemplates.dev/widgets/forms

Kurallar:

Trim uygulanmış metin boşken “Yayınla” devre dışıdır.

Loading sırasında butonun onPressed değeri null olur.

Sayaç her zaman gösterilir.

Hata halinde taslak korunur.

Başarılı gönderimden sonra form temizlenir.

Yanıt oluştururken ana gönderi özeti salt okunur gösterilir.

Profil başlığı

Token: {components.profile-summary}

Widget hierarchy:

```
CustomScrollView
├── SliverAppBar
│   ├── title: Text (profil adı)
│   ├── leading: back veya drawer
│   └── actions: kendi profilinde edit
├── SliverToBoxAdapter
│   └── Padding
│       └── Column
│           ├── Row
│           │   ├── CircleAvatar (large)
│           │   ├── Spacer
│           │   └── FilledButton
│           │       └── "Takip Et" | "Takibi Bırak" | "Profili Düzenle"
│           ├── Text (ad)
│           ├── Text (@kullanıcı)
│           ├── Text (bio)
│           ├── Row (takip edilen + takipçi)
│           └── Divider
└── SliverList (post-card)
```

fluttertemplates kaynağı: Profile / Dashboard Cards — https://fluttertemplates.dev/widgets/profile

Kurallar:

Kendi profilinde takip butonu gösterilmez.

Takip işlemi optimistic uygulanabilir ve hata halinde geri alınır.

Avatar URL boşsa veya yüklenemezse baş harfler gösterilir.

Bio boşsa gereksiz boş alan ayrılmaz.

Gönderiler kronolojik sıralanır.

Auth formu

Token: {components.input}, {components.primary-button}

Widget hierarchy:

```
Scaffold
└── SafeArea
    └── Center
        └── SingleChildScrollView
            └── Form (key: _formKey)
                └── Column
                    ├── Text ("Pulse")
                    ├── TextFormField (e-posta)
                    ├── TextFormField (kullanıcı adı — kayıt)
                    ├── TextFormField (ad — kayıt)
                    ├── TextFormField (şifre, obscureText)
                    ├── FilledButton
                    │   └── "Oturum Aç" | "Hesap Oluştur"
                    └── TextButton
                        └── "Hesabın yok mu? Kayıt ol"
                            | "Zaten hesabın var mı? Oturum aç"
```

fluttertemplates kaynağı: Forms / Inputs / Validation — https://fluttertemplates.dev/widgets/forms

Kurallar:

Kayıt ekranında davet kodu veya yönetici onayı alanı bulunmaz.

Form CTA'sı body içinde tam genişliktedir.

Validator mesajı ilgili alanın altında gösterilir.

Genel ağ hatası alan validation hatası gibi gösterilmez.

Şifre yalnızca kullanıcı eylemiyle görünür yapılır.

Empty state

Token: {components.state-panel}

Widget hierarchy:

```
Center
└── ConstrainedBox (maxWidth: 360)
    └── Column (mainAxisSize: min)
        ├── Icon
        ├── Text (başlık)
        ├── Text (açıklama)
        └── FilledButton.tonal (birincil CTA)
```

fluttertemplates kaynağı: States & Errors / Empty State — https://fluttertemplates.dev/widgets/states

Kurallar:

Kayıt yok anlamındaki 404 empty state olarak ele alınır.

Kayıt yokken hata olarak gösterilmemelidir.

Birincil CTA body içinde bulunur.

Empty, loading ve error aynı anda gösterilmez.

Loading state

Token: {components.state-panel}

Widget hierarchy:

```
Scaffold body
├── oturum kontrolü: Center
│   └── CircularProgressIndicator
└── liste yükleme: ListView
    └── skeleton Card placeholders
```

fluttertemplates kaynağı: States & Errors / Loading State — https://fluttertemplates.dev/widgets/states

Kurallar:

Oturum kontrolü tamamlanmadan login veya feed gösterilmez.

Kullanıcı değiştiğinde önceki kullanıcı verisi gösterilmez.

İlk yüklemede skeleton kullanılır.

Submit loading yalnızca ilgili formu kilitler.

Error state

Token: {components.state-panel}

Widget hierarchy:

```
Center
└── ConstrainedBox
    └── Column
        ├── Icon (error_outline)
        ├── Text (başlık)
        ├── Text (açıklama)
        └── OutlinedButton ("Tekrar Dene")
```

fluttertemplates kaynağı: States & Errors / Error State — https://fluttertemplates.dev/widgets/states

Kurallar:

Ağ, zaman aşımı veya beklenmeyen sunucu hatasında gösterilir.

401 merkezi login akışına gider.

Kayıt yok anlamındaki 404 error state değildir.

Retry duplicate route oluşturmaz.

Silme onayı

Token: {components.primary-button}

Widget hierarchy:

```
showDialog
└── AlertDialog
    ├── title: Text ("Gönderi silinsin mi?")
    ├── content: Text ("Bu işlem geri alınamaz.")
    └── actions
        ├── TextButton ("İptal")
        └── FilledButton ("Sil")
```

fluttertemplates kaynağı: Dialogs & Sheets / Alert Dialog — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Yalnızca gönderi sahibi açabilir.

Silme sürerken aksiyonlar devre dışıdır.

Başarısız işlemde gönderi kartı korunur.

“Sil” destructive renkte gösterilir.

Success snackbar

Token: {components.state-panel}

Widget hierarchy:

```
ScaffoldMessenger.showSnackBar
└── SnackBar
    ├── content: Text
    └── behavior: floating
```

fluttertemplates kaynağı: Dialogs & Sheets / Snackbars — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Aynı işlem için birden fazla snackbar eklenmez.

Başarı mesajları kısa ve işlem odaklıdır.

Beğeni değişiminde sürekli snackbar gösterilmez.

Screen states

Ana Akış

Empty state: Başlık: "Akış henüz boş". Açıklama: "İlk gönderini paylaşarak konuşmayı başlat." CTA: "Gönderi Oluştur".

Fallback: Takip edilen kullanıcı yoksa public akış veya kendi gönderileri gösterilir.

Error state: "Akış yüklenemedi". CTA: "Tekrar Dene".

Success: Yeni gönderi: "Gönderin yayınlandı." Silme: "Gönderi silindi."

CTA konumu: FAB ve empty-state body CTA.

Gönderi Detayı

Empty state: Başlık: "Henüz yanıt yok". Açıklama: "İlk yanıtı sen yaz." CTA: "Yanıtla".

Error state: Ana gönderi bulunamazsa "Gönderi bulunamadı". Yanıt listesi boşsa hata gösterilmez.

Success: "Yanıtın yayınlandı."

CTA konumu: Gönderi içeriğinin altında body içinde.

Profil

Kendi profilim empty: "Henüz gönderin yok". CTA: "Gönderi Oluştur".

Başka profil empty: "Henüz gönderi yok". CTA: "Ana Akışa Dön".

Error state: "Profil yüklenemedi". Kullanıcı bulunamazsa "Kullanıcı bulunamadı".

Success: "Kullanıcı takip edildi.", "Takip bırakıldı.", "Profil güncellendi."

CTA konumu: Profil başlığı body alanı.

Oturum Aç ve Kayıt Ol

Error state: Alan validation hataları ilgili input altında gösterilir.

Login 401: "E-posta veya şifre hatalı."

Login success: "Oturum açıldı."

Register success, JWT varsa: "Hesabın oluşturuldu." ve Ana Akış.

Register success, JWT yoksa: "Hesabın oluşturuldu. Oturum açabilirsin." ve Login.

CTA konumu: Form body içinde tam genişlikte.

Gönderi Oluştur

Empty: Ayrı empty ekranı yoktur; buton devre dışıdır.

Validation: "Gönderi boş olamaz." veya "Gönderi en fazla 280 karakter olabilir."

Error state: Ağ hatasında taslak korunur.

Success: "Gönderin yayınlandı."

CTA konumu: Composer body alanı.

Do's and Don'ts

Do

Material 3 ColorScheme, TextTheme, NavigationBar, NavigationDrawer, FilledButton ve Card kullan.

Her veri durumu için yalnızca bir loading, empty veya error görünümü göster.

Optimistic aksiyonları hata halinde geri al.

İkon butonlarına tooltip ve semantic label ekle.

Dokunma alanlarını en az 44x44px tut.

Avatar URL hatasında baş harf fallback'i göster.

Don't

Başka bir sosyal ağın logosunu veya birebir görsel kimliğini kullanma.

MVP dışı mesaj, bildirim, trend, medya, anket, yer imi veya yeniden paylaşım ekleme.

Başkasının gönderisinde silme aksiyonu gösterme.

404 kayıt yok durumunu ağ hatası gibi gösterme.

401 sonrasında eski kullanıcı verisini ekranda tutma.

Ana CTA'yı yalnızca app bar ikonuna dönüştürme.

280 karakter sınırını yalnızca backend validation'a bırakma.
