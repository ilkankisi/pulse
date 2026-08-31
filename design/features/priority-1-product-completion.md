## Scope

Bu feature Pulse "Öncelik 1 — Ürünü tamamlayanlar" deneyimini kapsar:

- Kullanıcı adına göre kullanıcı arama.
- Gönderi metninde gönderi arama.
- Gönderi ve yanıtlarda `@username` mention yazma.
- Görüntülenen mention'a dokunarak ilgili profile gitme.
- Profil fotoğrafı, görünen ad, bio ve katılma tarihi.
- Kullanıcının en fazla bir gönderisini profilinin üstüne sabitleme.
- Kullanıcıyı engellemeden sessize alma ve gönderilerini ana akıştan gizleme.
- Composer'dan çıkarken boş olmayan metni yerel taslak olarak koruma.
- Kullanıcının kendi gönderisini yalnız ilk 5 dakika içinde düzenleyebilmesi.
- Düzenlenmiş gönderide `"Düzenlendi"` metadata etiketi.

Mevcut `{colors.*}`, `{typography.*}`, `{spacing.*}`, `{rounded.*}` ve ortak component token'ları kullanılır. UI canonical `docs/api-contract.md` dışında endpoint, query parametresi veya server alanı üretmez. Sunucu tarafından desteklenmeyen davranış başarılıymış gibi gösterilmez.

### Kabul kanıtı indeksi

- **Mute → unmute:** Unmuted ve muted durumları için idle/loading/success/error geçişleri iki yönlü tanımlıdır. Unmute success kullanıcıyı normal feed görünürlüğüne geri alır; mutation error önceki mute durumunu ve karşılık gelen menü etiketini korur; retry mümkündür ve follow/block state değişmez.
- **Draft restore/discard:** Draft yok/var başlangıcı, yerel restore, düzenlenen taslağın üzerine yazılması, explicit discard, submit loading/error sırasında metin ve taslağın korunması ve yalnız submit success sonrasında temizlenmesi tanımlıdır.
- **Edit state/ownership:** Own-post için eligible/expired ile edit loading/empty/error/success durumları tanımlıdır. Other-user için loading/empty/error/success durumlarının hiçbirinde edit CTA üretilmez. `"Düzenlendi"` metadata etiketi canonical 5 dakikalık düzenleme penceresini yeniden başlatmaz.

## Components

### Arama

Token: `{components.form-field}`, `{components.list-item-card}`, `{components.empty-state}`, `{components.loading-state}`, `{components.error-state}`

Widget hierarchy:

```text
Scaffold
├── AppBar
│   └── title: Text("Ara")
└── SafeArea
    └── Column
        ├── Padding
        │   └── SearchBar
        │       ├── leading: Icon(search)
        │       ├── hintText: "Kullanıcı veya gönderi ara"
        │       └── trailing: clear action
        ├── SegmentedButton | TabBar
        │   ├── "Kullanıcılar"
        │   └── "Gönderiler"
        └── Expanded
            └── state switch
                ├── initial: state-panel
                ├── loading: loading-state
                ├── empty: empty-state
                ├── error: error-state
                └── success: ListView | SliverList
                    ├── user item: ListTile
                    │   ├── CircleAvatar
                    │   ├── Text(displayName)
                    │   └── Text("@username")
                    └── post item: existing post-card

fluttertemplates kaynağı: Forms → Inputs; Lists; States & Errors — /widgets/forms, /widgets/lists, /widgets/states

Kurallar:

Boş sorgu API empty state değildir.

Kullanıcı sonucu satırına dokunulduğunda sonuçtaki username profiline gidilir.

Gönderi sonucu mevcut post-card görünümünü ve canonical etkileşimlerini kullanır.

Empty state'te boş ListView veya SliverList render edilmez.

UI kontrat dışında pagination veya query parametresi üretmez.

"Kullanıcılar" ve "Gönderiler" sekmeleri kendi sonuç state'lerini bağımsız taşır; bir sekmedeki loading, empty veya error diğer sekmenin başarılı sonucunu silmez.

Loading sırasında önceki sorgunun sonucu yeni sorgunun sonucuymuş gibi gösterilmez.

Kullanıcı araması success durumunda avatar, görünen ad ve @username satırı; gönderi araması success durumunda mevcut post-card listesi gösterilir.

Her iki arama türünde de sonuç bulunmaması empty state, ağ/5xx ise error state'tir. Retry aynı sorguyu ve seçili sekmeyi korur.

Mention

Token: {components.post-card}, {components.composer}, {components.list-item-card}

Widget hierarchy:

PostCard | ReplyCard

└── Column

├── author row

├── RichText

│   ├── normal text spans

│   └── tappable mention spans: @username

├── metadata row

└── action row

Composer

└── Column

├── TextField(maxLength: 280)

├── optional mention suggestions

│   └── ListTile

│       ├── CircleAvatar

│       ├── Text(displayName)

│       └── Text("@username")

└── primary submit action

fluttertemplates kaynağı: Core → Card; Forms → Inputs; Lists — /widgets/cards, /widgets/forms, /widgets/lists

Kurallar:

Mention {colors.primary} ile ayırt edilir; hardcoded renk kullanılmaz.

@username dokunulduğunda mention'ın gerçek kullanıcı adıyla ilgili profile gidilir.

Mention seçimi caret konumundaki mention parçasını tamamlar; kalan composer metnini silmez.

Çözümlenemeyen mention sahte profile bağlanmaz.

Mention davranışı hem yeni gönderi composer'ında hem yanıt composer'ında aynıdır.

Kullanıcı @ ve ardından kullanıcı adı karakterleri yazdığında aktif caret çevresindeki mention parçası suggestion aramasının girdisidir; composer'ın diğer metni sorguya dahil edilmez.

Suggestion loading durumunda öneri alanında progress gösterilir ve submit akışı bloke edilmez.

Suggestion empty durumunda sahte kullanıcı önerisi üretilmez; kullanıcı mevcut metni yazmaya devam edebilir.

Suggestion error durumunda composer metni korunur, mention metni silinmez ve öneri tekrar denenebilir; tüm composer error state'e dönüştürülmez.

Suggestion success durumunda eşleşen kullanıcı satırları avatar, görünen ad ve @username ile gösterilir.

Bir suggestion seçildiğinde yalnız caret'in içinde bulunduğu aktif @... parçası canonical @username ile değiştirilir; caret mention sonuna taşınır ve mention dışındaki metin aynen korunur.

Suggestion seçilmeden panel kapanırsa yazılmış mention parçası düz metin olarak korunur.

Gönderilmiş post veya yanıttaki çözümlenmiş mention span'ı ilgili profile gider; normal metin span'ları profile navigation tetiklemez.

Gelişmiş profil ve sabitlenmiş gönderi

Token: {components.profile-summary}, {components.profile-stats}, {components.post-card}

Widget hierarchy:

CustomScrollView

├── SliverAppBar

├── SliverToBoxAdapter

│   └── profile-summary

│       ├── CircleAvatar(80px)

│       ├── Text(displayName)

│       ├── Text("@username")

│       ├── optional Text(bio)

│       ├── Row

│       │   ├── Icon(calendar)

│       │   └── Text(joinedAt)

│       └── profile-stats

├── optional SliverToBoxAdapter

│   └── pinned section

│       ├── Row

│       │   ├── Icon(push_pin)

│       │   └── Text("Sabitlenmiş gönderi")

│       └── existing post-card

└── posts section

└── SliverList | empty-state

fluttertemplates kaynağı: Dashboard / Summary; Core → Card; Lists — /widgets/dashboard, /widgets/cards, /widgets/lists

Kurallar:

En fazla bir sabitlenmiş gönderi gösterilir.

Sabit gönderi normal gönderilerden önce yer alır.

Aynı gönderi sabit bölüm ve normal listede iki kez render edilmez.

Sabit gönderi yokluğu error değildir.

Bio yoksa boş alan ayrılmaz.

Avatar yoksa semantik placeholder kullanılır.

Gönderi sayacı varsa karşılık gelen gönderi listesi veya empty state de bulunur.

Sessize alma

Token: {components.safety-action-menu}, {components.snackbar-success}, {components.modal-bottom-sheet}

Widget hierarchy:

Profile | Post overflow

└── PopupMenuButton | ModalBottomSheet

└── ListTile

├── Icon(volume_off)

└── Text("Sessize Al" | "Sesi Aç")

fluttertemplates kaynağı: Dialogs & Sheets — /widgets/dialogs

Kurallar:

Sessize alma engelleme değildir ve destructive {colors.error} stili kullanılmaz.

Sessize alınan kullanıcının gönderileri ana akışta gizlenir.

Sessize alınan kullanıcının profiline doğrudan erişim devam eder.

Sessize alma nedeniyle akışta içerik kalmaması error state değildir.

Başarı snackbar'ı "Kullanıcı sessize alındı." veya "Kullanıcının sesi açıldı." olur.

Sessizde olmayan kullanıcı için aksiyon "Sessize Al"; sessizde olan kullanıcı için aynı konumda karşı aksiyon "Sesi Aç" olarak gösterilir.

Mute veya unmute isteği pending iken ilgili aksiyon disabled olur ve aynı işlem ikinci kez gönderilemez.

Mute success sonrasında menü durumu "Sesi Aç" olarak güncellenir ve kullanıcının gönderileri ana akıştan gizlenir.

Unmute success sonrasında menü durumu "Sessize Al" olarak güncellenir ve kullanıcı normal feed görünürlüğüne yeniden dahil edilir.

Mute veya unmute error durumunda önceki mute durumu korunur, menü etiketi rollback edilir ve retry yapılabilen non-destructive hata geri bildirimi gösterilir.

Mute/unmute profili, takip ilişkisini veya block durumunu değiştirmez.

Mute/unmute kabul durumları:

Unmuted + idle: aksiyon "Sessize Al"dır.

Unmuted + mute loading: "Sessize Al" disabled olur; ikinci mute isteği gönderilemez.

Unmuted + mute success: state muted olur, aksiyon "Sesi Aç" olur ve hedef kullanıcının gönderileri ana akıştan çıkarılır.

Unmuted + mute error: state unmuted kalır, aksiyon "Sessize Al" olarak kalır ve retry mümkündür.

Muted + idle: aksiyon "Sesi Aç"tır.

Muted + unmute loading: "Sesi Aç" disabled olur; ikinci unmute isteği gönderilemez.

Muted + unmute success: state unmuted olur, aksiyon "Sessize Al" olur ve hedef kullanıcı normal feed görünürlüğüne yeniden dahil edilir.

Muted + unmute error: state muted kalır, aksiyon "Sesi Aç" olarak kalır ve retry mümkündür.

Mute ve unmute success/error geçişlerinin hiçbiri follow veya block state'ini değiştirmez.

Yerel taslak

Token: {components.composer}, {components.primary-button}

Widget hierarchy:

Composer

└── PopScope

└── Column

├── optional Text("Taslak")

├── TextField(maxLength: 280)

└── FilledButton

fluttertemplates kaynağı: Forms → Inputs — /widgets/forms

Kurallar:

Boş olmayan gönderilmemiş metin composer'dan çıkarken yerelde saklanır.

Composer tekrar açıldığında taslak geri yüklenir.

Başarıyla gönderilen içerikten sonra ilgili taslak temizlenir.

Boş veya yalnız whitespace içerik taslak olarak saklanmaz.

Taslak bulunmaması API empty state değildir.

Composer açılışında ilgili yerel taslak varsa TextField başlangıç değeri taslak metnidir ve "Taslak" etiketi görünür; kullanıcı metni doğrudan düzenlemeye devam edebilir.

Taslak restore edilirken uzak API loading/empty/error state'i gösterilmez; restore yerel composer başlangıç durumudur.

Restore edilen taslak üzerinde yapılan yeni değişiklikler composer'dan yeniden çıkıldığında son metinle mevcut yerel taslağın üzerine yazılır.

Kullanıcı taslağı açıkça discard ederse yerel taslak temizlenir ve aynı composer sonraki açılışta boş başlar.

Restore edilmiş içerik başarıyla gönderilirse taslak yalnız gönderim success sonrasında temizlenir; gönderim error durumunda metin ve taslak korunarak retry mümkün kalır.

Whitespace'e indirgenen metin taslak olarak saklanmaz ve boş içerik restore edilmez.

Taslak restore/discard kabul durumları:

Draft yok: composer boş açılır; API empty state veya uzak loading state gösterilmez.

Draft var: composer açılır açılmaz kayıtlı metin TextField içine eksiksiz yüklenir ve "Taslak" etiketi görünür.

Restore success yerel başlangıç durumudur; kullanıcı restore edilen metni doğrudan düzenleyebilir.

Restore edilen metin değiştirildikten sonra composer gönderilmeden kapatılırsa son boş olmayan metin mevcut yerel taslağın üzerine yazılır.

Kullanıcı açık discard aksiyonunu seçerse yerel taslak silinir, restore edilmiş içerik yeniden kaydedilmez ve aynı composer sonraki açılışta boş başlar.

Restore edilmiş içerik için submit loading sırasında metin ve yerel taslak korunur.

Submit error durumunda composer'daki son metin ve yerel taslak korunur; retry mümkündür.

Submit success sonrasında ilgili yerel taslak temizlenir ve sonraki composer açılışı boş başlar.

Metin boş veya yalnız whitespace'e indirilmişse çıkışta taslak oluşturulmaz ve sonraki açılışta boş içerik restore edilmez.

Gönderi düzenleme

Token: {components.composer}, {components.primary-button}, {components.snackbar-success}

Widget hierarchy:

Own Post overflow

└── action: "Düzenle"

└── Edit Composer

├── TextField(existingText, maxLength: 280)

├── Text("Gönderiler ilk 5 dakika içinde düzenlenebilir.")

└── FilledButton("Değişiklikleri Kaydet")

fluttertemplates kaynağı: Forms → Inputs, Validation — /widgets/forms

Kurallar:

"Düzenle" yalnız kullanıcının kendi gönderisinde ve ilk 5 dakikalık canonical düzenleme penceresinde kullanılabilir.

Süre dolduğunda edit CTA gösterilmez.

Kaydet butonu loading, boş veya geçersiz içerikte disabled olur.

Başarılı düzenleme sonrası gönderi güncel metni gösterir.

"Düzenlendi" {typography.body-sm} ve {colors.text-secondary} ile timestamp metadata grubunda gösterilir.

Own-post success/eligible durumunda ilk 5 dakika boyunca overflow menüsünde "Düzenle" görünür; other-user gönderilerinde yaşından bağımsız olarak "Düzenle" hiçbir zaman gösterilmez.

Own-post için 5 dakikalık pencere dolmuşsa gönderi normal okunur durumda kalır ancak edit affordance kaldırılır; expired durum error değildir.

Edit composer açıldığında mevcut gönderi metni TextField içine eksiksiz yüklenir.

Edit loading durumunda "Değişiklikleri Kaydet" disabled olur, pending göstergesi verilir ve çift submit engellenir; yayınlanmış mevcut post metni optimistic olarak değiştirilmez.

Edit empty durumunda boş veya yalnız whitespace içerik geçersizdir; primary CTA disabled kalır ve form validation mesajı gösterilir. Bu durum API empty state değildir.

Edit error durumunda mevcut yayınlanmış gönderi değişmeden kalır, edit composer'daki kullanıcının son metni korunur, "Gönderi güncellenemedi. Tekrar deneyin." geri bildirimi gösterilir ve retry mümkündür.

Edit success durumunda edit composer kapanır, post-card yeni metni gösterir, "Gönderi güncellendi." snackbar'ı gösterilir ve timestamp metadata grubuna "Düzenlendi" etiketi eklenir.

Daha önce düzenlenmiş own-post tekrar açıldığında yalnız canonical 5 dakikalık pencere hâlâ geçerliyse edit CTA sunulur; "Düzenlendi" etiketi edit yetkisi oluşturmaz veya süreyi yeniden başlatmaz.

Other-user gönderisinin loading, empty, error veya success veri durumlarının hiçbirinde edit CTA üretilmez.

Edit state / ownership kabul matrisi:

Own-post + eligible + success: canonical oluşturulma zamanından itibaren ilk 5 dakika içinde overflow menüsünde "Düzenle" görünür.

Own-post + expired: "Düzenle" görünmez; post normal okunur durumda kalır ve bu durum empty/error değildir.

Other-user + loading: "Düzenle" hiçbir zaman gösterilmez.

Other-user + empty: "Düzenle" hiçbir zaman gösterilmez.

Other-user + error: "Düzenle" hiçbir zaman gösterilmez.

Other-user + success: "Düzenle" hiçbir zaman gösterilmez.

Own-post edit composer başlangıcı: mevcut yayınlanmış metin TextField içine eksiksiz yüklenir.

Own-post edit loading: "Değişiklikleri Kaydet" disabled + progress olur, çift submit engellenir ve yayınlanmış post optimistic değiştirilmez.

Own-post edit empty: boş/whitespace içerik validation state'tir, primary CTA disabled kalır ve API empty state gösterilmez.

Own-post edit error: yayınlanmış post değişmez; editörde kullanıcının son metni korunur, "Gönderi güncellenemedi. Tekrar deneyin." gösterilir ve retry mümkündür.

Own-post edit success: composer kapanır, post-card güncel metni gösterir, "Gönderi güncellendi." snackbar'ı çıkar ve timestamp metadata grubuna "Düzenlendi" eklenir.

Daha önce düzenlenmiş own-post için "Düzenlendi" metadata'sı yeni bir 5 dakikalık pencere oluşturmaz; yalnız özgün canonical düzenleme penceresi hâlâ geçerliyse tekrar edit edilebilir.

Screen states

Arama

Initial title: "Aramaya başla"

Initial description: "Kullanıcı adına veya gönderi metnine göre arama yap."

Initial CTA: ""

Empty title: "Sonuç bulunamadı"

Empty description: "Aramana uygun kullanıcı veya gönderi bulunamadı."

Empty CTA: ""

Error title: "Arama yapılamadı"

Error description: "Bağlantını kontrol edip tekrar dene."

Error CTA: "Tekrar Dene"

404 kayıt-yok semantiği taşıyorsa empty state olarak ele alınır.

Ağ/5xx empty state değildir.

403 normal empty state değildir.

401 genel error state olarak render edilmez; merkezi login akışına yönlendirilir.

"Tekrar Dene" body içinde gösterilir.

Profil

Empty title: "Henüz gönderi yok"

Empty description: "Bu kullanıcı henüz bir gönderi paylaşmadı."

Empty CTA: ""

Error title: "Profil yüklenemedi"

Error description: "Bağlantını kontrol edip tekrar dene."

Error CTA: "Tekrar Dene"

Success snackbar: "Profil güncellendi."

Sabitlenmiş gönderi bulunmaması ayrı error veya empty ekranı değildir.

Taslak ve düzenleme

Draft label: "Taslak"

Edit success snackbar: "Gönderi güncellendi."

Edit failure: "Gönderi güncellenemedi. Tekrar deneyin."

Taslak bulunmaması API empty state değildir.

Düzenleme primary CTA'sı composer body içindedir.

Edit loading: Kaydet CTA disabled + progress; mevcut yayınlanmış metin korunur.

Edit empty: Boş/whitespace içerik validation state'tir; API empty state değildir.

Edit error: Edit metni korunur, failure mesajı ve retry sunulur.

Edit success: Güncel metin + "Düzenlendi" metadata etiketi + success snackbar.

Edit ownership: own-post yalnız ilk 5 dakika eligible; other-user hiçbir durumda eligible değildir.

Draft restore: Yerel taslak varsa composer metni taslakla açılır ve "Taslak" etiketi görünür.

Draft discard: Kullanıcı discard ettiğinde yerel taslak temizlenir; sonraki açılış boş başlar.

Draft submit error: Restore edilen metin ve taslak korunur; retry mümkündür.

Draft submit success: Yerel taslak yalnız başarı sonrasında temizlenir.

Mute loading: Mevcut "Sessize Al" veya "Sesi Aç" aksiyonu disabled olur; duplicate mutation gönderilmez.

Mute success: "Sessize Al" → "Sesi Aç"; hedef kullanıcının gönderileri feed'den gizlenir.

Unmute success: "Sesi Aç" → "Sessize Al"; hedef kullanıcı normal feed görünürlüğüne geri döner.

Mute/unmute error: Mutation öncesi mute state ve karşılık gelen menü etiketi korunur; retry sunulur.

Other-user edit loading: Edit CTA yoktur.

Other-user edit empty: Edit CTA yoktur.

Other-user edit error: Edit CTA yoktur.

Other-user edit success: Edit CTA yoktur.

Navigation

Ana navigasyondaki arama aksiyonu → Arama.

Kullanıcı arama sonucu → sonuçtaki @username profili.

Gönderi arama sonucu → mevcut canonical gönderi etkileşim akışı.

Post veya yanıttaki @username → mention hedefinin profili.

Profilde sabitlenmiş gönderi → mevcut post-card etkileşimleri.

Profil/post overflow → "Sessize Al" veya "Sesi Aç".

Kendi gönderisi overflow → ilk 5 dakika içinde "Düzenle" → Edit Composer.

Composer'dan çıkış → yerel taslak kaydı.

Composer yeniden açılışı → varsa yerel taslağın geri yüklenmesi.

Restore edilmiş composer → discard → yerel taslağın temizlenmesi → sonraki açılışta boş composer.

Sessizde olmayan kullanıcı → "Sessize Al" success → aynı menüde "Sesi Aç".

Sessizde olan kullanıcı → "Sesi Aç" success → aynı menüde "Sessize Al".

Kabul kriterleri — doğrulanabilir state kanıtı

Bu bölüm yeni davranış veya API sözleşmesi tanımlamaz. Yukarıdaki mevcut tasarım kararlarını Manager kabul kontrolünde doğrudan görülebilecek tek bir kanıt alanında tekrarlar.

Mute → unmute

Başlangıçİşlem / sonuçGörünen aksiyonFeed sonucuFollow / block
Unmuted + idleişlem yok"Sessize Al"Normal görünürlükDeğişmez
Unmutedmute loading"Sessize Al" disabledBaşarılı mute olmuş gibi değiştirilmezDeğişmez
Unmutedmute success"Sesi Aç"Hedef kullanıcının gönderileri gizlenirDeğişmez
Unmutedmute error"Sessize Al" korunurÖnceki unmuted görünürlük korunur; retry mümkündürDeğişmez
Muted + idleişlem yok"Sesi Aç"Hedef kullanıcı muted kalırDeğişmez
Mutedunmute loading"Sesi Aç" disabledMevcut muted görünürlük korunurDeğişmez
Mutedunmute success"Sessize Al"Hedef kullanıcı normal feed görünürlüğüne geri dönerDeğişmez
Mutedunmute error"Sesi Aç" korunurÖnceki muted görünürlük korunur; retry mümkündürDeğişmez

Mute ve unmute loading durumunda aynı mutation ikinci kez gönderilemez.

Mute ve unmute error durumunda mutation öncesi state ile menü etiketi korunur ve non-destructive retry sunulur.

Unmute success kullanıcıyı engelden çıkarmaz, takip etmez veya takibi bırakmaz; yalnız mute görünürlüğünü normal duruma döndürür.

Draft restore / discard

DurumBeklenen davranış
Draft yokComposer boş açılır; API loading veya API empty state gösterilmez.
Draft varKayıtlı metin TextField içine eksiksiz restore edilir ve "Taslak" etiketi gösterilir.
Restore successYerel composer başlangıç durumudur; kullanıcı restore edilen metni doğrudan düzenleyebilir.
Restore edilen metin değiştirildiComposer gönderilmeden kapatılırsa son boş olmayan metin mevcut yerel taslağın üzerine yazılır.
Explicit discardYerel taslak silinir, restore edilmiş içerik yeniden kaydedilmez ve sonraki açılış boş başlar.
Submit loadingComposer metni ve yerel taslak korunur; duplicate submit engellenir.
Submit errorKullanıcının son metni ve yerel taslak korunur; retry mümkündür.
Submit successYerel taslak yalnız success sonrasında temizlenir; sonraki açılış boş başlar.
Metin boş / whitespaceTaslak oluşturulmaz ve sonraki açılışta boş içerik restore edilmez.

Draft restore uzak API isteği değildir; loading/empty/error API paneli üretmez.

Discard sonrasında aynı restore edilmiş metin çıkış lifecycle'ında tekrar taslak olarak yazılmaz.

Submit error taslağın silinme nedeni değildir. Taslak yalnız başarılı submit veya explicit discard ile temizlenir.

Edit state / ownership

Ownership / stateEdit davranışı
Own-post + eligible + successCanonical oluşturulma zamanından itibaren ilk 5 dakika içinde "Düzenle" görünür.
Own-post + expired"Düzenle" görünmez; gönderi normal okunur durumda kalır ve bu durum empty/error değildir.
Own-post edit başlangıcıMevcut yayınlanmış metin TextField içine eksiksiz yüklenir.
Own-post edit loadingKaydet disabled + progress olur, çift submit engellenir ve yayınlanmış post optimistic değiştirilmez.
Own-post edit emptyBoş/whitespace içerik form validation state'idir; CTA disabled kalır ve API empty state gösterilmez.
Own-post edit errorYayınlanmış post değişmez; son edit metni korunur, hata mesajı ve retry sunulur.
Own-post edit successComposer kapanır; post-card güncel metni, success snackbar'ı ve "Düzenlendi" metadata'sını gösterir.
Other-user + loading"Düzenle" CTA üretilmez.
Other-user + empty"Düzenle" CTA üretilmez.
Other-user + error"Düzenle" CTA üretilmez.
Other-user + success"Düzenle" CTA üretilmez.

Own-post edit error metni: "Gönderi güncellenemedi. Tekrar deneyin."

Own-post edit success snackbar'ı: "Gönderi güncellendi."

"Düzenlendi" etiketi {typography.body-sm} ve {colors.text-secondary} ile timestamp metadata grubunda gösterilir.

"Düzenlendi" metadata'sı düzenleme yetkisi oluşturmaz ve canonical 5 dakikalık pencereyi yeniden başlatmaz. Daha önce düzenlenmiş own-post yalnız özgün canonical pencere hâlâ geçerliyse tekrar düzenlenebilir.

Other-user gönderilerinin loading, empty, error ve success durumlarının tamamında ownership kuralı edit CTA üretimini engeller.