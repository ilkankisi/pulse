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
