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
