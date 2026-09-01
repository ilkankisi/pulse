# Feature: Öncelik 1 ürün tamamlama

## Scope

Bu feature ürünün Öncelik 1 tamamlama yüzeylerini kapsar:

- Kullanıcı ve gönderi arama
- Gönderi metnindeki mention etkileşimleri
- Profilde sabitlenmiş gönderi
- Kullanıcıyı sessize alma ve sessizden çıkarma
- Gönderi taslağını koruma
- Kullanıcının kendi gönderisini düzenlemesi

UI canonical `docs/api-contract.md` sözleşmesinde bulunmayan endpoint, request alanı, response alanı, role, status veya action değeri üretmez.

Canonical kontratta desteklenmeyen bir davranış UI tarafından varsayılmaz veya local-only kalıcı ürün davranışına dönüştürülmez.

Mevcut Material 3 token'ları, navigation kuralları, post component'i, loading/empty/error state ilkeleri ve minimum 44x44px dokunma alanı kuralları bu feature için de geçerlidir.

---

# Feature: Arama

## Scope

Canonical sözleşmenin desteklediği arama yüzeylerini tek bir arama deneyiminde sunar.

Aranabilen result türleri yalnız backend/canonical contract tarafından döndürülen türlerdir.

UI yeni search scope, filtre, cursor, offset veya query parametresi üretmez.

## Components

### Arama giriş alanı

Token: `{components.input}`, `{components.state-panel}`

Widget hierarchy:

```text
Scaffold
├── AppBar
│   └── Text("Ara")
└── SafeArea
    └── CustomScrollView
        ├── SliverToBoxAdapter
        │   └── Padding
        │       └── SearchBar | TextField
        │           ├── leading: Icon(search)
        │           ├── hintText
        │           └── optional trailing clear action
        └── state/results
            ├── idle
            ├── loading
            ├── empty
            ├── error
            └── SliverList
                └── canonical search result items

Kurallar:

Arama metni canonical request alanına map edilir.

Boş veya yalnız whitespace sorgusu ağ isteği üretmez.

Yeni sorgu başladığında önceki sorgunun geç sonucu aktif sorgunun sonucunu ezmez.

Arama sırasında önceki kullanıcıya ait veya başka sorguya ait stale sonuçlar yeni sonuç gibi gösterilmez.

Result item türü backend sonucundan gelir; UI yeni result type üretmez.

Kullanıcı sonucu profile, gönderi sonucu gönderi detayına navigasyon yapar.

Kullanıcı sonucuna giderken result içindeki username kullanılır.

Gönderi sonucuna giderken result içindeki canonical post kimliği kullanılır.

Arama sonucu listesine mute, block veya report için duplicate inline aksiyon eklenmez; ilgili profil/gönderi güvenlik yüzeyi kullanılır.

401 merkezi login akışına gider.

404 canonical olarak kayıt-yok anlamına geliyorsa empty state'tir.

Ağ/5xx empty state değildir.

Screen states

Başlangıç

Başlık: "Ara"

Arama yapılmadan API empty/error state gösterilmez.

Loading

Aktif sorgu için progress/skeleton gösterilir.

Input erişilebilir kalır.

Empty state

Başlık: "Sonuç bulunamadı"

Açıklama: "Farklı bir arama terimi deneyebilirsin."

Zorunlu primary CTA yoktur.

Error state

Başlık: "Arama yapılamadı"

Açıklama: "Sonuçlar alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

Success

Sonuçların başarıyla yüklenmesi snackbar üretmez.

Navigation

Arama sonucu kullanıcı → ProfilePage(result.username).

Arama sonucu gönderi → canonical gönderi detay route'u.

Geri navigasyonunda mümkünse arama metni ve scroll konumu korunur.

Feature: Mention

Scope

Canonical backend sonucunda gönderi içeriğinde tanımlanmış mention'ların okunabilir ve etkileşimli gösterimidir.

Mention oluşturma ve parsing kuralının doğruluk kaynağı backend/canonical contract'tır.

Components

Mention içeren gönderi metni

Mevcut post-card ve post-detail metin bileşeni yeniden kullanılır.

Widget hierarchy:

PostContent
└── Text.rich | selectable rich text
    └── spans
        ├── normal content span
        └── mention span
            └── @username

Kurallar:

Mention görünümü normal metinden ayırt edilebilir ancak okunabilirlik yalnız renge bağlı bırakılmaz.

Mention dokunma alanı erişilebilir olmalıdır.

Mention tap → mention'ın kendi username değeriyle profil açılır.

Parent post author username'i veya current-user username'i mention hedefi yerine kullanılmaz.

UI canonical sonucunda bulunmayan mention üretmez.

UI metin içinde @ gördüğü her parçayı canonical mention kabul ederek yeni backend semantiği üretmez.

Mention edilen kullanıcı bulunamadığında mevcut gönderi içeriği kaybolmaz.

401 gerekiyorsa merkezi login akışına gider.

Screen states

Mention için bağımsız loading veya empty ekranı yoktur.

Mention profile navigasyonunun hedefi bulunamazsa hedef profil ekranının mevcut "Kullanıcı bulunamadı" durumu kullanılır.

Navigation

Mention tap → ProfilePage(mention.username).

Geri → kaynak feed/post-detail konumu mümkün olduğunca korunur.

Feature: Profil ve sabitlenmiş gönderi

Scope

Mevcut profil header ve profil gönderileri deneyimine canonical pinned-post bilgisini ekler.

Components

Sabitlenmiş gönderi alanı

Token: {components.post-card}, {components.profile-summary}

Widget hierarchy:

ProfilePage(username)
└── CustomScrollView
    ├── profile header
    ├── optional pinned section
    │   ├── section metadata
    │   │   └── Icon(push_pin) + Text("Sabitlendi")
    │   └── PostCard(pinnedPost)
    └── chronological profile posts

Kurallar:

Pinned-post yalnız canonical profil/backend sonucunda mevcutsa gösterilir.

UI local olarak ilk gönderiyi pinned kabul etmez.

Pinned gönderi mevcut post-card component'ini yeniden kullanır.

Pinned gönderi tap → canonical gönderi detayı.

Pinned gönderi profilin normal kronolojik gönderi listesinin sıralamasını UI tarafında yeniden tanımlamaz.

Backend aynı gönderiyi hem pinned alanında hem normal listede döndürüyorsa duplicate gösterim davranışı canonical response semantics'e göre ele alınır; UI yeni veri sözleşmesi üretmez.

Pinned gönderi silinmiş veya bulunamıyor sonucu dönerse profil tamamı error'a çevrilmez.

Kendi profilinde pin/unpin mutation aksiyonu yalnız canonical contract destekliyorsa gösterilir.

Canonical contract aksiyon sağlamıyorsa UI pin/unpin butonu üretmez.

Başka kullanıcı profilinde yönetim aksiyonu gösterilmez.

Screen states

Pinned gönderinin olmaması profil empty state'i değildir.

Profilin gönderisi yoksa mevcut profil empty state kuralları geçerlidir.

Pinned alanı ayrı endpoint üzerinden yükleniyorsa hata halinde mevcut profil içeriği korunur.

Navigation

Pinned gönderi → Gönderi Detayı.

Pinned gönderideki author ve mention navigasyonları mevcut post component davranışını kullanır.

Feature: Sessize alma ve sessizden çıkarma

Scope

Başka kullanıcı profili güvenlik/ilişki yüzeyinden canonical mute/unmute davranışına erişim sağlar.

Mute block değildir; UI bu iki state'i aynı davranış gibi sunmaz.

Components

Profil güvenlik menüsü mute aksiyonu

Token: {components.safety-action-menu}

Widget hierarchy:

PopupMenuButton | MenuAnchor
└── menuChildren
    ├── canonical report action
    ├── canonical block/unblock action
    └── canonical mute state destekleniyorsa
        └── MenuItemButton
            ├── Icon(volume_off | volume_up)
            └── Text("Sessize Al" | "Sessizden Çıkar")

Kurallar:

Mute/unmute yalnız başka kullanıcı için gösterilir.

Kullanıcının kendi profilinde mute/unmute gösterilmez.

Gösterilen state canonical backend sonucundan gelir.

Muted değilse yalnız "Sessize Al" gösterilir.

Muted ise yalnız "Sessizden Çıkar" gösterilir.

Mutation loading sırasında aynı aksiyon tekrar tetiklenemez.

Optimistic state uygulanırsa failure halinde önceki state geri alınır.

Mutation sonrasında state backend sonucuyla senkronize edilir.

UI mute nedeniyle feed görünürlük algoritmasını yeniden tanımlamaz.

Mute ile block aynı confirmation, renk veya açıklama zorunluluğuna sahip kabul edilmez.

Canonical contract confirmation gerektirmiyorsa destructive block confirmation dialog'u mute için kopyalanmaz.

Başarı mesajı:

Mute: "Kullanıcı sessize alındı."

Unmute: "Kullanıcı sessizden çıkarıldı."

Ağ hatasında profil mevcut haliyle korunur.

401 login akışına gider.

403 normal empty state değildir.

Navigation

Başka kullanıcı profili → güvenlik menüsü → mute/unmute.

Mutation sonrası kullanıcı aynı profil yüzeyinde kalır.

Feature: Gönderi taslağı

Scope

Yeni gönderi ve yanıt composer'ında kullanıcının henüz göndermediği metnin istemsiz kaybolmasını önler.

Taslak davranışı canonical API gerektirmiyorsa local UI state olabilir; ancak backend'de olmayan cross-device draft sync özelliği gibi sunulmaz.

Components

Composer draft state

Token: {components.composer}

Widget hierarchy:

ComposerPage
└── Form
    └── Column
        ├── TextFormField(controller: draft)
        ├── character counter
        └── submit action

Kurallar:

Network loading draft metnini temizlemez.

Validation failure draft metnini temizlemez.

Network/5xx failure draft metnini temizlemez.

Başarılı gönderimden sonra ilgili composer draft'ı temizlenir.

Yeni gönderi draft'ı ile farklı postlara ait reply draft'ları birbirinin metnini ezmez.

Bir reply draft'ı varsa hangi parent gönderiye ait olduğu route/context ile ayrıştırılır.

Kullanıcı composer'dan metin varken çıkmak istediğinde uygulanacak discard confirmation davranışı proje genelindeki mevcut navigation politikasına uygun olur.

Discard confirmation kullanılıyorsa:

AlertDialog
├── title: Text("Taslak silinsin mi?")
├── content: Text("Yazdığın içerik kaybolacak.")
└── actions
    ├── TextButton("Devam Et")
    └── FilledButton | TextButton("Taslağı Sil")

Boş veya whitespace taslak için gereksiz confirmation gösterilmez.

UI taslağı gönderilmiş içerik gibi feed'e eklemez.

Draft state başka kullanıcı oturumu açıldığında önceki kullanıcıdan taşınmaz.

Logout/session değişiminde önceki kullanıcıya ait draft görünür kalmaz.

Screen states

Draft'ın varlığı API empty state değildir.

Error sonrası aynı composer ve mevcut draft korunur.

Success sonrası draft temizlenir ve ilgili feed/detail backend sonucu ile yenilenir.

Navigation

FAB → yeni gönderi draft bağlamı.

Post Detail → Yanıtla → parent post'a özel reply draft bağlamı.

Back/close → gerekiyorsa discard confirmation.

Feature: Gönderi düzenleme

Scope

Kullanıcının yalnız canonical contract tarafından düzenlenebilir kabul edilen kendi gönderisini düzenlemesini sağlar.

Components

Gönderi overflow düzenleme aksiyonu

Mevcut post-card/post-detail overflow menüsü kullanılır.

Widget hierarchy:

PopupMenuButton | MenuAnchor
└── own-post actions
    ├── canonical edit destekleniyorsa MenuItemButton("Düzenle")
    └── existing delete action

Kurallar:

"Düzenle" yalnız kullanıcının kendi ve canonical olarak editlenebilir gönderisinde gösterilir.

Başka kullanıcının gönderisinde edit aksiyonu gösterilmez.

UI ownership bilgisini username metin karşılaştırmasıyla güvenlik sınırı olarak kabul etmez; canonical session/backend state kullanılır.

Gönderi düzenleme formu

Token: {components.composer}, {components.primary-button}

Widget hierarchy:

Scaffold
├── AppBar
│   ├── leading: back/close
│   └── action: FilledButton("Kaydet")
└── SafeArea
    └── Padding
        └── Form
            └── Column
                ├── TextFormField
                │   ├── initialValue: canonical existing content
                │   ├── multiline
                │   └── maxLength: canonical limit
                ├── character counter
                └── validation message

Kurallar:

Form mevcut canonical content ile açılır.

Boş veya yalnız whitespace içerik kaydedilmez.

Maksimum uzunluk mevcut gönderi composer sınırı/canonical contract ile aynıdır; UI yeni limit üretmez.

Kaydet sırasında CTA disabled/loading olur.

Mutation tekrar tetiklenemez.

Ağ/5xx hatasında kullanıcının düzenlediği metin korunur.

401 login akışına gider.

403/404 başarı gibi gösterilmez.

Başarılı edit sonrası post/detail/profile/feed görünümü backend'in güncel sonucu ile senkronize edilir.

Başarılı edit mesajı: "Gönderi güncellendi."

Kullanıcı değişiklik yaptıktan sonra çıkmak isterse draft/discard davranışı yeni gönderi composer'ıyla tutarlı olur.

Edit formu, reply/create composer ile aynı temel input ve validation bileşenlerini yeniden kullanır.

Screen states

Loading

Mevcut içerik okunmadan boş form authoritative content gibi gösterilmez.

Error

Gönderi bulunamazsa: "Gönderi bulunamadı"

Düzenleme yüklenemezse: "Gönderi yüklenemedi"

Kaydetme başarısızsa form ve düzenlenmiş metin korunur.

CTA gerekiyorsa: "Tekrar Dene"

Success

"Gönderi güncellendi."

Navigation

Own post overflow → Düzenle.

Başarı → kaynak ekran veya gönderi detayı backend'in güncel gönderisiyle yenilenir.

Geri/close → değişiklik varsa mevcut discard-draft davranışı uygulanır.

Shared screen-state rules

401

401 hiçbir Öncelik 1 yüzeyinde normal retry/empty panel değildir.

Merkezi login/session akışına yönlendirilir.

403

403 normal empty state olarak gösterilmez.

Yetkisiz aksiyon UI'da başarıya çevrilmez.

404

Canonical bağlamda kayıt-yok anlamı taşıyan liste aramalarında empty state olabilir.

Tekil profil/gönderi hedefinin bulunamaması ilgili "bulunamadı" durumudur.

Network / 5xx

Empty state değildir.

Retry sunulabilir.

Composer/edit draft metni korunur.

Mutation loading

Yalnız mutation ile ilgili CTA disabled/loading olur.

Bütün ekran gereksiz şekilde initial loading state'e dönmez.

Success

Liste yalnız başarılı yüklendi diye snackbar göstermez.

Kullanıcı mutation'larında kısa, işleme özgü Türkçe success mesajı kullanılabilir.

Backend sonucu UI state'in kalıcı doğruluk kaynağıdır.

Do's and Don'ts

Do

Mevcut Material 3 semantik token'larını kullan.

Arama sonucundan profile giderken result.username kullan.

Mention tap'te mention.username kullan.

Pinned post için mevcut post-card bileşenini kullan.

Mute ve block state'lerini ayrı anlamlar olarak koru.

Mute/unmute state'ini backend sonucuyla senkronize et.

Create/reply/edit sırasında kullanıcı metnini ağ hatasında koru.

Edit ekranını mevcut composer görsel diliyle hizala.

Mutation sırasında yalnız ilgili aksiyonu loading/disabled yap.

401'i merkezi login akışına yönlendir.

403'ü empty state'e dönüştürme.

Canonical kayıt-yok 404 semantiğini uygun liste ekranında empty state olarak göster.

Backend'in döndürdüğü güncel sonucu mutation sonrası render et.

Minimum 44x44px dokunma alanını koru.

Don'ts

API kontratında olmayan search scope üretme.

API kontratında olmayan query parametresi, cursor veya pagination alanı üretme.

Metindeki her @ token'ını canonical mention kabul etme.

Mention tap'te post author veya current-user username kullanma.

İlk profil gönderisini local olarak pinned kabul etme.

Canonical contract desteklemiyorsa pin/unpin aksiyonu ekleme.

Mute ile block'u aynı state veya aynı backend davranışı gibi gösterme.

Kullanıcının kendi profilinde mute aksiyonu gösterme.

Başka kullanıcının gönderisinde edit aksiyonu gösterme.

Edit ownership kontrolünü yalnız görünen username karşılaştırmasına bırakma.

Ağ hatasında create/reply/edit draft'ını temizleme.

Başarısız optimistic mutation state'ini kalıcı bırakma.

Önceki oturumun draft veya arama sonucunu yeni kullanıcıya gösterme.

Kapsam dışı DM, medya, bookmark, repost, quote veya trend özelliği ekleme.