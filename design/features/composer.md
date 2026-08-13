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
