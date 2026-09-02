# Feature: Öncelik 1 ürün tamamlama deneyimi

## Scope

Ürünün temel sosyal deneyimini tamamlayan yüzeyler:

- Kullanıcı ve içerik araması
- Gönderi oluştururken mention keşfi ve seçimi
- Profilde sabitlenmiş gönderi gösterimi
- Kullanıcıyı sessize alma ve sessizden çıkarma
- Gönderi oluşturma taslağının korunması
- Kullanıcının kendi gönderisini düzenlemesi

Tüm API, response, permission ve mutation davranışları canonical `docs/api-contract.md` sözleşmesinden map edilir.

UI:

- API kontratında olmayan endpoint üretmez.
- API kontratında olmayan query parametresi üretmez.
- API kontratında olmayan role, status, enum veya action üretmez.
- Backend'in desteklemediği davranışı yalnız local state ile kalıcı ürün özelliği gibi göstermez.
- Canonical response field adlarını yeniden tanımlamaz.

## User flows

### Arama

- Arama giriş noktası → Arama ekranı.
- Kullanıcı sorgusunu girer.
- Sonuçlar canonical backend response'una göre render edilir.
- Kullanıcı sonucu → `ProfilePage(result.username)`.
- Gönderi sonucu → ilgili Gönderi Detayı.
- Sonuç bulunmaması empty state'tir.
- Ağ/5xx empty state değildir.
- 401 merkezi login akışına gider.
- Yeni sorgu başladığında eski sorgunun geciken cevabı güncel sonucu overwrite etmez.

### Mention

- Composer içinde `@` mention bağlamı başladığında suggestion yüzeyi açılır.
- Suggestion verisi yalnız canonical API davranışından gelir.
- Kullanıcı suggestion seçtiğinde canonical username composer'a eklenir.
- Suggestion loading, empty veya error durumunda composer taslağı korunur.
- Render edilmiş mention destekleniyorsa `ProfilePage(username)` açar.
- UI backend'in tanımadığı mention identifier veya syntax üretmez.

### Profil ve pinned post

- Profil yüklenir.
- Backend response sabitlenmiş gönderi içeriyorsa profil gönderilerinden önce pinned yüzeyi gösterilir.
- Pinned gönderi mevcut post-card bileşenini yeniden kullanır.
- Pinned karta dokunma → Gönderi Detayı.
- Pinned state yalnız backend sonucundan gelir.
- Pinned gönderi yoksa placeholder veya empty panel gösterilmez.

### Mute / unmute

- Başka kullanıcı profili → güvenlik/overflow menüsü.
- Backend relationship state'e göre:
  - Sessize Al
  - Sessizden Çıkar
- Kendi profilinde mute/unmute gösterilmez.
- Mutation sırasında yalnız ilgili aksiyon loading/disabled olur.
- Başarı sonrası state backend sonucuyla senkronize edilir.
- Hata halinde önceki state korunur.
- Feed görünürlük davranışı UI'da yeniden uygulanmaz.

### Draft

- Composer'daki yazılmış içerik gönderim tamamlanana veya kullanıcı açıkça silene kadar korunur.
- Ağ hatası taslağı temizlemez.
- Validation hatası taslağı temizlemez.
- Mention lookup loading/error taslağı temizlemez.
- Başarılı gönderim taslağı temizler.
- İçerik bulunan composer kapatılırken discard confirmation gösterilir.
- `Vazgeç` composer'a döner.
- `Taslağı Sil` taslağı temizler ve composer'ı kapatır.
- Backend desteği yoksa cross-device draft sync üretilmez.

### Gönderi düzenleme

- Kullanıcının kendi düzenlenebilir gönderisi → overflow → `Gönderiyi Düzenle`.
- Edit ekranı mevcut içerikle açılır.
- Kullanıcı canonical validation kuralları içinde içeriği günceller.
- Başarılı mutation sonrası backend'in döndürdüğü güncel post render edilir.
- Değişmiş fakat kaydedilmemiş içerikle çıkılırsa discard confirmation gösterilir.
- Başkasının gönderisinde edit aksiyonu gösterilmez.
- Backend izin vermiyorsa local edit kalıcılaştırılmaz.

## Components

### Arama alanı

Token: `{components.input}`

Widget hierarchy:

```text
SearchPage
└── Scaffold
    ├── AppBar
    │   └── Text("Ara")
    └── SafeArea
        └── Column
            ├── Padding
            │   └── SearchBar | TextField
            │       ├── leading: search icon
            │       ├── hintText
            │       └── optional clear action
            └── Expanded
                └── search state
                    ├── initial
                    ├── loading
                    ├── empty
                    ├── error
                    └── result list

Kurallar:

- Sorgu canonical arama parametresine map edilir.
- Contract dışında filter, sort, cursor veya pagination parametresi üretilmez.
- Sorgu temizlendiğinde önceki sonuçlar yeni sorguya aitmiş gibi gösterilmez.
- Stale request güncel sorgu sonucunu overwrite etmez.
- Sonuç satırları minimum 44x44px dokunma alanına sahiptir.
- Kullanıcı sonucuna giderken `result.username` kullanılır.

### Arama sonucu kullanıcı satırı

Token: `{components.social-graph-list-item}`

Widget hierarchy:

```text
InkWell
└── Padding
    └── Row
        ├── CircleAvatar
        ├── Expanded
        │   └── Column(crossAxis: start)
        │       ├── Text(displayName)
        │       └── Text("@username")
        └── optional relationship action

Kurallar:

- Mevcut kullanıcı satırı pattern'i reuse edilir.
- Satıra dokunma → `ProfilePage(result.username)`.
- Duplicate block/report aksiyonları eklenmez.

### Mention suggestion overlay

Token: `{components.input}`, `{components.social-graph-list-item}`

Widget hierarchy:

```text
Composer
└── Stack
    ├── TextFormField
    └── mention active ise
        └── suggestion surface
            └── ConstrainedBox
                └── ListView
                    └── suggestion row
                        ├── CircleAvatar
                        └── Column
                            ├── Text(displayName)
                            └── Text("@username")

Kurallar:

- Suggestion yüzeyi composer'ı kullanılmaz hale getirmez.
- Klavye açıkken erişilebilir kalır.
- Seçimde canonical username kullanılır.
- Suggestion error full-screen composer error'a dönüşmez.
- Empty suggestion taslağı etkilemez.
- Contract dışı mention endpoint'i üretilmez.

### Pinned post alanı

Token: `{components.post-card}`

Widget hierarchy:

```text
ProfilePage
└── profile content
    ├── ProfileSummary
    ├── pinned post varsa
    │   └── Column
    │       ├── Row
    │       │   ├── Icon(push_pin_outlined)
    │       │   └── Text("Sabitlenmiş")
    │       └── PostCard(pinnedPost)
    └── profile posts

Kurallar:

- Yalnız backend state varsa gösterilir.
- Yeni post-card varyantı üretilmez.
- Mevcut post navigation ve güvenlik davranışları korunur.
- Pinned metadata görsel olarak ikincildir.
- Pinned state yokluğu empty state değildir.

### Mute aksiyonu

Token: `{components.safety-action-menu}`

Widget hierarchy:

```text
MenuAnchor | PopupMenuButton
└── other profile actions
    └── MenuItemButton
        ├── Icon(volume_off_outlined | volume_up_outlined)
        └── Text("Sessize Al" | "Sessizden Çıkar")

Kurallar:

- Yalnız başka kullanıcı profillerinde gösterilir.
- Backend relationship state uygun aksiyonu belirler.
- Mutation sırasında tekrar tetiklenemez.
- Block/report ile mevcut security menu pattern'i reuse edilir.
- Mute, block davranışı gibi yorumlanmaz.

### Draft discard dialog

Token: `{colors.error}`

Widget hierarchy:

```text
AlertDialog
├── title: Text("Taslak silinsin mi?")
├── content: Text("Yazdığın değişiklikler kaybolacak.")
└── actions
    ├── TextButton("Vazgeç")
    └── TextButton | FilledButton("Taslağı Sil")

Kurallar:

- Boş composer kapanırken gösterilmez.
- Başarılı gönderim sonrası gösterilmez.
- Ağ hatası discard sayılmaz.
- Destructive aksiyon açık biçimde etiketlenir.

### Gönderi düzenleme ekranı

Token: `{components.composer}`, `{components.primary-button}`

Widget hierarchy:

```text
EditPostPage
└── Scaffold
    ├── AppBar
    │   ├── leading: back
    │   └── action: FilledButton("Kaydet")
    └── SafeArea
        └── Padding
            └── Form
                └── Column
                    ├── TextFormField
                    │   ├── current content
                    │   ├── multiline
                    │   └── canonical maxLength
                    ├── character counter
                    └── validation message

Kurallar:

- Edit alanı yalnız canonical editable content alanına map edilir.
- Composer validation kuralları reuse edilir.
- İçerik değişmemişse gereksiz mutation gönderilmez.
- Loading sırasında `Kaydet` tekrar tetiklenemez.
- Ağ hatasında düzenlenmiş local metin korunur.
- Başarılı backend response güncel post state'inin kaynağıdır.
- Başkasının gönderisine edit UI gösterilmez.

## Screen states

### Arama

#### Initial state

Başlık: "Ara"

Açıklama: "Kullanıcıları veya içerikleri bulmak için arama yap."

Bu durum API empty state değildir.

#### Loading state

- Arama input'u kullanılabilir kalır.
- Loading son aktif sorguya aittir.
- Önceki sorgunun sonuçları yeni sorguya ait gibi gösterilmez.

#### Empty state

Başlık: "Sonuç bulunamadı"

Açıklama: "Aramana uygun bir sonuç bulunamadı."

CTA yoktur.

#### Error state

Başlık: "Arama yapılamadı"

Açıklama: "Sonuçlar alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

401 login akışına gider.

### Mention suggestions

#### Initial state

Mention aktif değilse suggestion yüzeyi gösterilmez.

#### Empty state

- Eşleşme bulunamazsa inline durum gösterilebilir.
- Composer taslağı korunur.
- Full-screen empty state kullanılmaz.

#### Error state

- Suggestion yüzeyinde non-blocking hata gösterilebilir.
- Composer içeriği korunur.

### Pinned post

#### Empty state

- Pinned gönderi yoksa state panel gösterilmez.
- Profil normal şekilde devam eder.

#### Error state

- Pinned veri profil response'unun parçasıysa profil error semantiği canonical response'a göre uygulanır.
- Sahte pinned veri üretilmez.

### Mute / unmute

#### Success

- "Kullanıcı sessize alındı."
- "Kullanıcı sessizden çıkarıldı."

#### Error

- Profil state'i korunur.
- İlgili aksiyon tekrar kullanılabilir hale gelir.
- 401 login akışına gider.

### Draft

#### Success

- Başarılı gönderim sonrası composer taslağı temizlenir.
- Başarılı edit sonrası edit taslağı temizlenir.

#### Error

- Ağ/5xx taslağı temizlemez.
- Validation taslağı temizlemez.
- Mention lookup hatası taslağı temizlemez.

### Gönderi düzenleme

#### Error state

Validation:

- İlgili input altında gösterilir.

Ağ/5xx:

- Düzenlenmiş metin korunur.
- Kullanıcı tekrar deneyebilir.

401:

- Merkezi login akışına gider.

403:

- Empty veya validation state gibi gösterilmez.

404:

- Canonical semantiğe göre gönderinin artık bulunamadığı durum gösterilir.
- Form sahte local post ile devam etmez.

#### Success

- "Gönderi güncellendi."
- Backend'in döndürdüğü güncel post render edilir.

## Navigation

- Arama giriş noktası → Arama ekranı.
- Arama kullanıcı sonucu → `ProfilePage(result.username)`.
- Arama gönderi sonucu → ilgili Gönderi Detayı.
- Composer mention seçimi → composer içinde kalır.
- Render edilmiş mention → destekleniyorsa `ProfilePage(username)`.
- Profil pinned post → Gönderi Detayı.
- Başka profil güvenlik menüsü → mute/unmute; route değişmez.
- Kendi gönderisi overflow → `EditPostPage`.
- Edit başarı → önceki ekrana backend'in güncel post state'iyle dönülür.
- Draft discard → önceki route'a dönülür.

## Do's and Don'ts

### Do

- Arama sonucunda backend'den gelen gerçek kullanıcı/post kimliğini kullan.
- Mention seçiminde canonical username kullan.
- Pinned post için mevcut post-card bileşenini reuse et.
- Mute/unmute state'ini backend sonucuyla senkronize et.
- Composer ve edit taslaklarını ağ hatasında koru.
- Edit validation için composer kurallarını reuse et.
- Mutation sonrası backend response'u kaynak kabul et.
- 401'i merkezi login akışına gönder.
- 403'ü normal empty state gibi gösterme.
- Minimum 44x44px dokunma alanını koru.
- Dinamik metin ölçeklendirmeyi destekle.

### Don'ts

- API kontratında olmayan search, mention, mute, pin, draft veya edit endpoint'i varsayma.
- API kontratında olmayan query parametresi, cursor, filter veya sort üretme.
- Mention için backend'de bulunmayan kullanıcıyı local string üzerinden gerçek entity kabul etme.
- Pinned state'i yalnız local state ile kalıcılaştırma.
- Mute state'ini yalnız optimistic state ile kalıcı kaynak kabul etme.
- Backend desteği yokken cross-device draft sync sunma.
- Başkasının gönderisinde `Gönderiyi Düzenle` gösterme.
- Arama sonucu yokluğunu network error'a dönüştürme.
- Mention suggestion hatasında composer taslağını temizleme.
- Kullanıcının kendi profilinde mute aksiyonu gösterme.
- Yeni role, permission, moderation status veya sosyal davranış üretme.