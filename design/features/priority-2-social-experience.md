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