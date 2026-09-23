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
