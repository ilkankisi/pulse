# Feature: Gönderi oluşturma

## Media composer state contract

Composer en az tek görsel attachment destekler.

State ve görünür UI davranışı:

-
empty
: Görsel seçili değildir; media picker kullanılabilir.
-
selected
: Seçilen görsel local preview olarak görünür; kullanıcı kaldırabilir veya upload başlatabilir.
-
uploading
: Preview korunur, attachment üzerinde progress/loading görünür; aynı görsel tekrar upload edilemez ve media içeren submit tamamlanmaz.
-
uploaded
: Canonical media kimliği alınmıştır; gönderi submit edilebilir.
-
uploadError
: Preview ve gönderi metni korunur; item-level hata ile
Tekrar Dene
ve kaldırma aksiyonları görünür.
-
removing
: Yalnız attachment üzerinde removing/loading gösterilir.

Geçişler:

- Görsel seç:
empty → selected
.
- Upload:
selected → uploading → uploaded|uploadError
.
- Retry:
uploadError → uploading → uploaded|uploadError
.
- Kaldır:
selected|uploaded|uploadError → removing → empty
.
- Remove başarısızsa mevcut preview/state korunur ve attachment seviyesinde hata gösterilir.
- Submit başarısızsa text ve başarılı media attachment state'i korunur; Composer sıfırlanmaz.

Başarılı normal gönderim canonical post sonucunu oluşturduktan sonra mevcut Composer akışı kapanır ve kullanıcı kaynak Feed bağlamına döner; Feed kartındaki görsel
text → media preview → action bar
hiyerarşisinde görünür.

## Quote Composer

Quote Composer mevcut Composer state contract'ını kullanır ancak original gönderi referansını sabit
OriginalPostCard
olarak ayrıca gösterir.

- Quote text/media original gönderi içeriğine flatten edilmez.
- Quote attachment yalnız yeni quote gönderisine aittir; original post media ile birleştirilmez.
- Başarılı submit kaynak Feed/Post Detail bağlamına canonical quote sonucu ile döner.
- Submit başarısızsa Composer açık kalır; quote text, seçili/yüklenmiş media ve
OriginalPostCard
korunur.
- İptal/back yeni quote oluşturmadan onu açan Feed/Post Detail bağlamına döner.

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
