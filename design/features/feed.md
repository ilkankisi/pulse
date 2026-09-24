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
    ├── SliverToBoxAdapter
    │   └── Form(replyComposer)
    │       └── Row
    │           ├── Expanded
    │           │   └── TextFormField(
    │           │       labelText: "Yanıt yaz",
    │           │       keyboardType: text,
    │           │       validator: nonEmpty
    │           │   )
    │           └── FilledButton("Yanıtla")
    ├── replies collection
    │   ├── loading: SliverList(skeleton reply cards)
    │   ├── success: SliverList(oldest → newest)
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
Yanıt sayacı tap'i yeni PostDetail route'u oluşturmaz; mevcut Yanıtlar bölümünü görünür alana getirir. Canonical navigation hedefi bu aynı-route Yanıtlar koleksiyonudur.
Yanıt koleksiyonu yüklenirken ana gönderi görünür kalır. Loading yalnız Yanıtlar alt koleksiyonuna uygulanır.
Beğenenler koleksiyonundaki kullanıcı satırı profile gider. `likeCount` tap'inin canonical navigation hedefi AppBar başlığı "Beğenenler" olan bu koleksiyon route'udur.
Boş başarılı koleksiyon veya kayıt-yok semantiğindeki 404 empty state'tir; ağ/5xx error state'tir. Retry yalnız başarısız alt koleksiyonu yeniden yükler.
Alt koleksiyon hatası ana gönderiyi hata ekranıyla değiştirmez.
Empty durumda boş SliverList yerine state panel gösterilir.

Yanıtlar success sırası eskiden yeniye doğrudur: ilk öğe en eski, listenin son öğesi en yeni yanıttır. API farklı sırada dönerse sunum katmanı bu görünür sırayı normalize eder; ters kronolojik gösterim kullanılmaz.

Yanıtlar koleksiyonunda `replyCount > 0` iken ilk fetch'in boş liste dönmesi doğrudan empty state'e çevrilmez. Bu durum sayaç ile koleksiyonun tutarsızlığıdır; bir kez koleksiyon retry/refetch yapılır. Refetch sonrası gerçek başarılı boş sonuç veya kayıt-yok semantiğindeki 404 gelirse empty state gösterilir.

Beğenenler koleksiyonunda `likeCount > 0` iken ilk fetch'in boş liste dönmesi doğrudan "Henüz beğeni yok" empty state'ine çevrilmez. Bir kez koleksiyon retry/refetch yapılır; yalnız doğrulanmış başarılı boş sonuç veya kayıt-yok semantiğindeki 404 empty state'tir.

`replyCount == 0` için Yanıtlar, `likeCount == 0` için Beğenenler koleksiyonu ilk başarılı boş cevapta doğrudan kendi empty state'ini gösterebilir.

Yanıtlar için görünür içerik yapısı `SliverList`, Beğenenler için görünür içerik yapısı `ListView` olarak sabittir; loading placeholder'ları da aynı koleksiyon ailesinin scroll yapısını korur.

Success state'te mevcut koleksiyon öğeleri gösterilir; ayrıca genel başarı paneli veya success snackbar eklenmez. Mutation snackbar'ları koleksiyon fetch success state'inden ayrıdır.

Retry CTA metni her iki koleksiyon hata durumunda "Tekrar Dene"dir. Yanıtlar retry'si PostDetail route'unu yeniden açmaz; Beğenenler retry'si mevcut Beğenenler route'unda kalır.

Yanıt composer aynı PostDetail route'unda, ana gönderi ile Yanıtlar koleksiyonu arasında bulunur; ayrı compose route'u veya ikinci FAB oluşturulmaz.

"Yanıtla" CTA'sı yalnız geçerli, boş olmayan içerikte aktif olur; mutation sürerken disabled/loading olur ve ikinci kez gönderilemez.

Başarılı yanıt oluşturulduğunda composer temizlenir, Yanıtlar koleksiyonu güncellenir ve snackbar metni "Yanıtın paylaşıldı." olur.

Yanıtlar empty state:
- başlık: "Henüz yanıt yok"
- açıklama: "Bu gönderiye ilk yanıtı sen yazabilirsin."
- birincil CTA: yok; yazma aksiyonu üstteki reply composer'dır.

Yanıtlar error state:
- ağ/5xx başlık: "Yanıtlar yüklenemedi"
- açıklama: "Bağlantını kontrol edip tekrar deneyebilirsin."
- CTA: "Tekrar Dene"
- retry yalnız Yanıtlar koleksiyonunu yeniden yükler; ana gönderi ve composer görünür kalır.

Beğenenler empty state:
- başlık: "Henüz beğeni yok"
- açıklama: "Bu gönderiyi henüz kimse beğenmedi."
- birincil CTA: yok.

Beğenenler error state:
- ağ/5xx başlık: "Beğenenler yüklenemedi"
- açıklama: "Bağlantını kontrol edip tekrar deneyebilirsin."
- CTA: "Tekrar Dene"

Beğenenler success state kullanıcı satırlarından oluşur; ayrı success snackbar gösterilmez.

Yanıtlar ve Beğenenler için kayıt-yok anlamındaki 404 hata metni göstermeden ilgili empty state'e dönüşür.

401 durumunda koleksiyon empty/error metni kullanılmaz; mevcut auth akışı tetiklenir.

App bar vs body CTA:
- PostDetail AppBar içinde yanıt oluşturma CTA'sı bulunmaz.
- Yanıt oluşturmanın tek birincil aksiyonu body içindeki reply composer'da "Yanıtla" butonudur.
- Beğenenler route'unda oluşturma CTA'sı veya FAB bulunmaz.

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
