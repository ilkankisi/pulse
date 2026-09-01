# Feature: Öncelik 1 ürün tamamlama

## Scope

Bu feature ürünün Öncelik 1 tamamlama yüzeylerini kapsar:

- Kullanıcı ve gönderi arama
- Kullanıcı adına göre arama
- Gönderi metninde arama
- Gönderi ve yanıtlarda @mention
- Mention üzerinden profile geçiş
- Profil geliştirmeleri ve sabitlenmiş gönderi
- Kullanıcıyı sessize alma ve sessizden çıkarma
- Yerel gönderi ve yanıt taslağı
- Kullanıcının kendi gönderisini düzenlemesi
- Düzenlenen gönderinin "Düzenlendi" durumunun gösterimi

UI canonical `docs/api-contract.md` sözleşmesinde bulunmayan endpoint, query parametresi, request/response alanı, role, status veya action değeri üretmez.

Canonical kontratın henüz desteklemediği mutation veya veri davranışı UI tarafından mevcut API özelliği gibi sunulmaz.

Mevcut Material 3 semantik token'ları, minimum 44x44px dokunma alanı, merkezi 401 yönlendirmesi ve empty/error ayrımı bu feature için de geçerlidir.

---

# Feature: Arama

## Scope

Canonical sözleşmenin desteklediği kullanıcı ve gönderi arama sonuçlarını tek arama deneyiminde sunar.

UI yeni search scope, cursor, offset, filtre veya pagination query parametresi üretmez.

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

Önceki kullanıcıya veya başka sorguya ait stale sonuç yeni sonuç gibi gösterilmez.

Result type backend sonucundan gelir; UI yeni result türü üretmez.

Kullanıcı sonucuna dokunulduğunda result içindeki username ile profil açılır.

Gönderi sonucuna dokunulduğunda result içindeki canonical post kimliği ile gönderi detayı açılır.

Arama satırına duplicate block, mute veya report aksiyonu eklenmez.

401 merkezi login akışına gider.

Canonical kayıt-yok 404 sonucu empty state'tir.

Ağ/5xx empty state değildir.

Screen states

Başlangıç

Başlık: "Ara"

Arama yapılmadan API empty veya error state gösterilmez.

Loading

Aktif sorgu için progress veya skeleton gösterilir.

Arama input'u kullanılabilir kalır.

Empty state

Başlık: "Sonuç bulunamadı"

Açıklama: "Farklı bir arama terimi deneyebilirsin."

Birincil CTA yoktur.

Error state

Başlık: "Arama yapılamadı"

Açıklama: "Sonuçlar alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

Success

Sonuçların yalnız başarılı yüklenmesi snackbar üretmez.

Navigation

Kullanıcı sonucu → ProfilePage(result.username).

Gönderi sonucu → canonical Gönderi Detayı route'u.

Geri navigasyonda mümkünse sorgu ve scroll konumu korunur.

Feature: Mention

Scope

Gönderi ve yanıt içeriğindeki canonical mention bilgisini etkileşimli olarak sunar.

Mention parsing ve hedef eşlemesinin doğruluk kaynağı backend/canonical contract'tır.

Components

Mention içeren gönderi metni

Mevcut post-card ve post-detail içerik component'i yeniden kullanılır.

Widget hierarchy:

PostContent
└── Text.rich | selectable rich text
    └── spans
        ├── normal content span
        └── mention span
            └── @username

Kurallar:

Mention normal içerikten görsel olarak ayırt edilir.

Anlam yalnız renge bağlı bırakılmaz.

Mention dokunulduğunda mention'ın kendi username değeri kullanılır.

Post author username'i, parent route username'i veya current-user username'i mention hedefi yerine kullanılmaz.

UI metindeki her @ parçasını kendiliğinden canonical mention kabul etmez.

Mention edilen hesap bulunamadığında kaynak gönderi içeriği kaybolmaz.

Mention oluşturma sırasında kullanıcı seçimi gerekiyorsa yalnız canonical arama sonucundaki hesap kullanılır.

Screen states

Mention için bağımsız API empty ekranı yoktur.

Hedef profil bulunamıyorsa mevcut "Kullanıcı bulunamadı" profil durumu kullanılır.

Navigation

Mention → ProfilePage(mention.username).

Geri navigasyonunda kaynak feed veya post-detail bağlamı mümkün olduğunca korunur.

Feature: Profil geliştirmeleri ve sabitlenmiş gönderi

Scope

Profil yüzeyinde canonical olarak sunulan:

Profil fotoğrafı

Görünen ad

Bio

Kullanıcı adı

Katılma tarihi

Takip/takipçi sayaçları

Sabitlenmiş gönderi

bilgilerini gösterir.

Components

Geliştirilmiş profil özeti

Token: {components.profile-summary}, {components.profile-stats}

Widget hierarchy:

Column
├── Row
│   ├── CircleAvatar
│   │   └── canonical profile image | fallback
│   └── profile actions
├── Text(displayName)
├── Text(@username)
├── optional Text(bio)
├── optional Text(joinedAt)
├── profile stats
└── Divider

Kurallar:

Profil fotoğrafı mevcutsa canonical URL/veri kullanılır.

Fotoğraf yokluğu kırık image state olarak gösterilmez; nötr fallback avatar kullanılır.

Görünen ad ve bio uzun metinde layout taşmasına neden olmaz.

Katılma tarihi backend/canonical değerinden okunur; UI tahmini tarih üretmez.

Kendi profil güncelleme alanları yalnız canonical update sözleşmesinin desteklediği alanları sunar.

Başka kullanıcının profil bilgileri düzenlenemez.

Sabitlenmiş gönderi alanı

Token: {components.post-card}, {components.profile-summary}

Widget hierarchy:

ProfilePage(username)
└── CustomScrollView
    ├── profile header
    ├── optional pinned section
    │   ├── Row
    │   │   ├── Icon(push_pin)
    │   │   └── Text("Sabitlendi")
    │   └── PostCard(pinnedPost)
    └── chronological profile posts

Kurallar:

Sabitlenmiş gönderi yalnız canonical profil/backend sonucunda varsa gösterilir.

UI ilk gönderiyi veya en yeni gönderiyi kendiliğinden pinned kabul etmez.

Sabitlenmiş gönderi mevcut post-card component'ini yeniden kullanır.

Pinned post tap → canonical Gönderi Detayı.

Kullanıcının aynı anda en fazla bir pinned-post görünümü vardır.

Pin/unpin mutation aksiyonu yalnız canonical contract destekliyorsa gösterilir.

Canonical contract aksiyon sağlamıyorsa UI pin/unpin endpoint veya butonu üretmez.

Başka profil için yönetim aksiyonu gösterilmez.

Pinned-post bulunamaması tüm profil ekranını error'a çevirmek zorunda değildir.

Screen states

Pinned-post olmaması profil empty state değildir.

Profil gönderileri boşsa mevcut "Henüz gönderi yok" state'i uygulanır.

Ağ/5xx profil empty state'e dönüştürülmez.

401 login akışına gider.

Navigation

Pinned post → Gönderi Detayı.

Profil sayaçları ve diğer profil navigasyonları mevcut kuralları kullanır.

Feature: Sessize alma ve sessizden çıkarma

Scope

Başka kullanıcıyı engellemeden, canonical mute davranışına göre içeriklerinin akış görünürlüğünü değiştiren kullanıcı aksiyonunu sunar.

Mute ve block farklı güvenlik/ilişki state'leridir.

Components

Profil güvenlik menüsü mute aksiyonu

Token: {components.safety-action-menu}

Widget hierarchy:

PopupMenuButton | MenuAnchor
└── menuChildren
    ├── report action
    ├── block/unblock action
    └── canonical mute destekleniyorsa
        └── MenuItemButton
            ├── Icon(volume_off | volume_up)
            └── Text("Sessize Al" | "Sessizden Çıkar")

Kurallar:

Mute/unmute yalnız başka kullanıcı profili için gösterilir.

Kullanıcı kendi profilini sessize alamaz.

Muted state backend sonucundan gelir.

Muted değilse "Sessize Al", muted ise "Sessizden Çıkar" gösterilir.

Mutation sırasında yalnız ilgili aksiyon loading/disabled olur.

Mutation tekrar tetiklenemez.

Optimistic update uygulanırsa hata durumunda eski state geri alınır.

Başarılı mutation sonrası backend sonucu authoritative state'tir.

UI mute nedeniyle uygulanacak feed filtreleme algoritmasını yeniden tanımlamaz.

Mute, block confirmation dialog'unu zorunlu olarak tekrar kullanmaz.

Başarı mesajları:

"Kullanıcı sessize alındı."

"Kullanıcı sessizden çıkarıldı."

401 login akışına gider.

403 normal empty state değildir.

Ağ hatasında açık profil korunur.

Navigation

Başka profil → güvenlik menüsü → mute/unmute.

İşlem sonrası kullanıcı aynı profil yüzeyinde kalır.

Feature: Taslak gönderi ve yanıt

Scope

Yeni gönderi veya yanıt yazılırken kullanıcı composer'dan çıkarsa metnin yerel olarak korunmasını sağlar.

Bu özellik local UI state olabilir; backend cross-device draft sync özelliği varmış gibi sunulmaz.

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

Yeni gönderi draft'ı yerel olarak saklanabilir.

Yanıt draft'ları parent post bağlamına göre birbirinden ayrılır.

Yeni gönderi draft'ı reply draft'ını ezmez.

Farklı gönderilere ait reply draft'ları birbirini ezmez.

Network loading draft'ı temizlemez.

Validation hatası draft'ı temizlemez.

Ağ/5xx hatası draft'ı temizlemez.

Başarılı gönderim ilgili draft'ı temizler.

Boş veya yalnız whitespace draft saklama/confirmation için anlamlı içerik sayılmaz.

Logout veya kullanıcı değişiminde önceki kullanıcıya ait draft yeni oturumda görünmez.

Taslak local saklanıyorsa kullanıcı/route bağlamı ile izole edilir.

Composer'dan çıkış

Metin varsa ürün politikasına göre otomatik yerel saklama yapılır.

Kullanıcı yeniden aynı composer bağlamını açtığında saklanan metin geri yüklenir.

Discard aksiyonu sunuluyorsa:

AlertDialog
├── title: Text("Taslak silinsin mi?")
├── content: Text("Yazdığın içerik kaybolacak.")
└── actions
    ├── TextButton("Vazgeç")
    └── TextButton("Taslağı Sil")

Kurallar:

Kullanıcı açıkça "Taslağı Sil" seçmedikçe saklanmış metin istemsiz kaybolmaz.

Screen states

Taslak varlığı API empty state değildir.

Composer başlangıç hali error değildir.

Başarısız submit sonrası mevcut metin korunur.

Success sonrası ilgili draft temizlenir.

Navigation

FAB → yeni gönderi draft bağlamı.

Gönderi Detayı → Yanıtla → parent post'a özel reply draft bağlamı.

Geri/close → metin yerel olarak korunur.

Feature: Gönderi düzenleme

Scope

Canonical contract'ın düzenlenebilir kabul ettiği kullanıcının kendi gönderisini düzenleme deneyimini sunar.

Ürün kuralı örneğin ilk beş dakikada düzenlemeye izin veriyorsa kullanılabilir süre backend/canonical state'ten belirlenir; UI istemci saatine güvenerek tek başına authorization kararı vermez.

Components

Gönderi overflow düzenleme aksiyonu

Mevcut post-card ve post-detail overflow menüsü kullanılır.

Widget hierarchy:

PopupMenuButton | MenuAnchor
└── own-post actions
    ├── canonical edit destekleniyorsa MenuItemButton("Düzenle")
    └── existing delete action

Kurallar:

"Düzenle" yalnız kullanıcının kendi ve canonical olarak editlenebilir gönderisinde görünür.

Başka kullanıcı gönderisinde edit aksiyonu gösterilmez.

Edit süresi dolmuşsa aksiyon canonical state'e göre gizlenir veya disabled açıklamayla sunulur.

UI yalnız görünen username karşılaştırmasını authorization kaynağı kabul etmez.

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

Form canonical mevcut içerikle açılır.

Boş veya yalnız whitespace içerik kaydedilmez.

Maksimum karakter sınırı composer/canonical contract ile aynıdır.

Kaydet sırasında CTA loading/disabled olur.

Mutation tekrar gönderilemez.

Ağ/5xx hatasında düzenlenen metin korunur.

401 login akışına gider.

403 normal empty state değildir.

404 başarı gibi gösterilmez.

Başarılı edit sonrası feed, detail ve profil backend'in güncel post sonucuyla senkronize edilir.

Başarı mesajı: "Gönderi güncellendi."

Düzenlendi etiketi

Canonical post sonucu gönderinin düzenlendiğini bildiriyorsa post component metadata satırında:

metadata row
├── createdAt
└── optional Text("Düzenlendi")

gösterilir.

Kurallar:

"Düzenlendi" etiketi yalnız backend/canonical state gönderinin gerçekten düzenlendiğini gösteriyorsa render edilir.

UI content farkını local karşılaştırarak kalıcı edited state üretmez.

Etiket post-card ve post-detail yüzeylerinde tutarlı gösterilir.

Etiket primary CTA gibi görünmez; metadata stilini kullanır.

Screen states

Loading

Mevcut içerik yüklenmeden boş form authoritative içerik gibi gösterilmez.

Error

Gönderi bulunamazsa: "Gönderi bulunamadı"

Yükleme hatasında: "Gönderi yüklenemedi"

Kaydetme hatasında düzenlenen metin korunur.

Gerekirse CTA: "Tekrar Dene"

Success

"Gönderi güncellendi."

Navigation

Own post overflow → Düzenle.

Başarı → kaynak ekran veya Gönderi Detayı backend'in güncel sonucu ile yenilenir.

Geri/close → değişiklik varsa draft koruma davranışı uygulanır.

Shared screen-state rules

401

401 hiçbir Öncelik 1 yüzeyinde normal retry veya empty panel değildir.

Merkezi login/session akışına yönlendirilir.

403

403 normal empty state değildir.

Yetkisiz mutation başarı gibi gösterilmez.

404

Canonical kayıt-yok semantiği taşıyan liste/aramanın 404 sonucu empty state olabilir.

Tekil profil veya gönderinin bulunamaması ilgili "bulunamadı" state'idir.

Network / 5xx

Empty state değildir.

"Tekrar Dene" aksiyonu sunulabilir.

Composer ve edit metni korunur.

Mutation loading

Yalnız ilgili mutation CTA'sı disabled/loading olur.

Bütün ekran gereksiz şekilde initial loading state'e dönmez.

Success

Liste yalnız başarılı yüklendi diye snackbar göstermez.

Kullanıcı mutation'larında kısa ve işleme özgü Türkçe success mesajı kullanılabilir.

Backend sonucu remote state için kalıcı doğruluk kaynağıdır.

Do's and Don'ts

Do

Material 3 semantik token'larını kullan.

Minimum 44x44px dokunma alanını koru.

Arama sonucu kullanıcıdan profile geçerken result.username kullan.

Mention tap'te mention.username kullan.

Profil fotoğrafı yoksa nötr fallback göster.

Bio, görünen ad ve katılma tarihini canonical profil alanlarından göster.

Pinned-post için mevcut post-card component'ini kullan.

Mute ve block anlamlarını ayrı tut.

Mute/unmute state'ini backend ile senkronize et.

Gönderi ve reply taslağını yerel route/kullanıcı bağlamıyla izole et.

Composer'dan çıkışta yazılmış metni koru.

Edit ekranını mevcut composer görsel diliyle tutarlı yap.

Edit süresi ve edit yetkisini canonical/backend state'e göre belirle.

Canonical edited state varsa "Düzenlendi" metadata etiketini göster.

401'i merkezi login akışına yönlendir.

403'ü empty state'e dönüştürme.

Canonical kayıt-yok 404'ü uygun liste/arama ekranında empty state olarak göster.

Mutation sonrası backend'in güncel sonucunu render et.

Don'ts

API kontratında olmayan search endpoint, scope veya query parametresi üretme.

Metindeki her @ token'ını canonical mention kabul etme.

Mention hedefinde author veya current-user username kullanma.

İlk veya en yeni profil gönderisini local olarak pinned kabul etme.

Canonical contract desteklemiyorsa pin/unpin endpoint veya aksiyonu üretme.

Mute ile block'u aynı state gibi gösterme.

Kullanıcının kendi profilinde mute aksiyonu gösterme.

Mute görünürlüğünü UI içinde yeni bir feed algoritmasıyla tanımlama.

Taslağı ağ/validation hatasında temizleme.

Önceki kullanıcının draft'ını yeni oturumda gösterme.

Başka kullanıcının gönderisinde edit aksiyonu gösterme.

Edit authorization kararını yalnız client username veya client saatine bırakma.

Backend belirtmeden local content farkından kalıcı "Düzenlendi" state'i üretme.

Kapsam dışı DM, medya, bookmark, repost, quote veya trend özelliği ekleme.