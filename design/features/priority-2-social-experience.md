Feature: Öncelik 2 sosyal deneyim akışları

Scope

Bu feature profil merkezli sosyal graf deneyimini tamamlar:

Profilde takipçi ve takip edilen sayılarını görüntüleme.

Takipçi listesini açma.

Takip edilenler listesini açma.

Sosyal graf listesinden kullanıcı profiline geçme.

Başka kullanıcıyı takip etme.

Başka kullanıcıyı takipten çıkarma.

Başka kullanıcı profillerinde ilişki durumuna göre doğru CTA'yı gösterme.

“Takip Ettiklerim” feed filtresi kabul yüzeyini contract-gated olarak tasarlama.

“Seni takip ediyor” ve “Karşılıklı takip” ilişki göstergelerini contract-gated olarak tasarlama.

Loading, empty, error ve mutation durumlarını tutarlı biçimde ele alma.

Tüm endpoint, response alanı ve permission davranışları canonical API sözleşmesinden map edilir.

UI hiçbir zaman sözleşmede bulunmayan endpoint, query parametresi, response alanı veya sosyal ilişki durumu üretmez.

“Takip Ettiklerim” ve ilişki göstergeleri kabul kapsamının zorunlu yüzeyleridir. Canonical contract desteğinin bulunmaması bu yüzeyleri tasarım kapsamından çıkarmaz; bunun yerine her yüzey için açık bir contract-unavailable durumu tanımlanır.

User flows

Profil → sosyal graf

Profil yüklenir.

followerCount ve followingCount canonical profile response'tan gösterilir.

“Takipçi” sayacına dokunma → FollowersPage(profile.username).

“Takip” sayacına dokunma → FollowingPage(profile.username).

Açılan sosyal graf ekranı kendi route username bağlamını korur.

Başka profil görüntülenirken endpoint current-user username ile değiştirilmez.

Sosyal graf listesindeki kullanıcı satırına dokunma → ProfilePage(row.username).

Takipçiler

FollowersPage(username) route parametresindeki profile ait takipçileri yükler.

Başlık: “Takipçiler”.

Liste canonical followers response'una göre render edilir.

Her satır canonical kullanıcı kimliği ve username değerini kullanır.

Satıra dokunulduğunda ilgili profil açılır.

Liste boşsa empty state gösterilir.

Network veya 5xx hatası empty state gibi gösterilmez.

401 merkezi login akışına gider.

403 normal empty state değildir.

Yeniden deneme mevcut route username bağlamını korur.

Takip edilenler

FollowingPage(username) route parametresindeki profile ait takip edilen hesapları yükler.

Başlık: “Takip Edilenler”.

Liste canonical following response'una göre render edilir.

Her satır canonical kullanıcı kimliği ve username değerini kullanır.

Satıra dokunulduğunda ilgili profil açılır.

Liste boşsa empty state gösterilir.

Network veya 5xx hatası empty state gibi gösterilmez.

401 merkezi login akışına gider.

403 normal empty state değildir.

Yeniden deneme mevcut route username bağlamını korur.

Profilde follow / unfollow

Başka profil:

isFollowedByCurrentUser=false → “Takip Et”.

isFollowedByCurrentUser=true → “Takibi Bırak”.

Kendi profilinde follow/unfollow CTA gösterilmez; mevcut profil düzenleme davranışı korunur.

Takip Et:

Canonical follow endpoint'i profile.username ile çağrılır.

Mutation süresince yalnız ilgili relationship CTA loading/disabled olur.

Aynı mutation tekrar tetiklenemez.

Başarı response'u canonical relationship state ile eşleşmelidir.

Başarı sonrası profil state'i backend sonucuyla senkronize edilir.

İlgili açık sosyal graf read state'i invalidate/refetch edilir.

Başarısız mutation'da önceki doğrulanmış relationship state korunur.

Takibi Bırak:

Canonical unfollow endpoint'i profile.username ile çağrılır.

Mutation süresince yalnız ilgili relationship CTA loading/disabled olur.

Aynı mutation tekrar tetiklenemez.

Başarı sonrası profil state'i backend sonucuyla senkronize edilir.

İlgili açık sosyal graf read state'i invalidate/refetch edilir.

Başarısız mutation'da önceki doğrulanmış relationship state korunur.

Sosyal graf satırında relationship aksiyonu

Canonical response satır bazında ilişki aksiyonunu güvenilir biçimde destekliyorsa mevcut relationship CTA pattern'i reuse edilebilir.

Canonical response gerekli ilişki bilgisini vermiyorsa liste satırında tahmini follow/unfollow butonu üretilmez.

Satırın ana navigasyon davranışı her durumda ProfilePage(row.username) olur.

Mutation aksiyonu ile satır navigasyonu birbirine karıştırılmaz.

Components

Profil sosyal sayaçları

Token: {components.social-summary-card}

Widget hierarchy:

Card
└── Padding
    └── Row
        ├── InkWell
        │   └── Column
        │       ├── Text(followerCount)
        │       └── Text("Takipçi")
        └── InkWell
            └── Column
                ├── Text(followingCount)
                └── Text("Takip")

fluttertemplates: Social Profile — /widgets/social

Kurallar:

Sayaçlar canonical profile response değerlerinden gelir.

Takipçi sayacı → FollowersPage.

Takip sayacı → FollowingPage.

Sayaç varsa karşılık gelen liste ekranı ve empty/error state zorunludur.

Takipçiler / Takip Edilenler listesi

Token: {components.social-graph-list}

Widget hierarchy:

Scaffold
├── AppBar
│   └── Text("Takipçiler" | "Takip Edilenler")
└── body
    └── state
        ├── loading: ListView
        │   └── shimmer rows
        ├── success: ListView
        │   └── user row
        │       ├── CircleAvatar
        │       ├── Column
        │       │   ├── Text(displayName if available)
        │       │   └── Text("@username")
        │       └── optional canonical relationship action
        ├── empty: EmptyState
        └── error: ErrorState
            └── FilledButton("Yeniden Dene")

fluttertemplates: User Search / Social Profile — /widgets/social

Kurallar:

Satır tap → ProfilePage(row.username).

Relationship action yalnız canonical row state bunu destekliyorsa gösterilir.

404 veya canonical “kayıt yok” semantiği empty state'tir.

Network/5xx/403 empty olarak gösterilmez.

Takip Et / Takibi Bırak CTA

Token: {components.relationship-action}

Widget hierarchy:

FilledButton | OutlinedButton
├── state: idle
│   └── Text("Takip Et" | "Takibi Bırak")
└── state: loading
    └── SizedBox
        └── CircularProgressIndicator

fluttertemplates: Social Profile — /widgets/social

Kurallar:

Kendi profilinde gösterilmez.

Mutation sırasında disabled olur.

Başarısız mutation mevcut doğrulanmış state'i bozmaz.

CTA metni yalnız canonical relationship state'ten türetilir.

Takip Ettiklerim feed filtresi — zorunlu kabul yüzeyi

Token: {components.following-feed-filter}

Bu yüzey kabul kapsamının zorunlu parçasıdır ve iki contract durumuyla tasarlanır.

Contract available

Canonical feed contract takip edilen hesaplarla sınırlı bir feed scope/filter tanımlıyorsa Ana Akış içinde “Takip Ettiklerim” seçimi render edilir.

Widget hierarchy:

FeedPage
├── AppBar
└── body
    └── Column
        ├── feed filter region
        │   └── SegmentedButton | FilterChip row
        │       ├── canonical default feed option
        │       └── option: Text("Takip Ettiklerim")
        └── Expanded
            └── feed state
                ├── loading: feed skeleton
                ├── success: ListView
                │   └── PostCard*
                ├── empty: EmptyState
                └── error: ErrorState
                    └── FilledButton("Yeniden Dene")

fluttertemplates: Activity Feed — /widgets/social

Kurallar:

Seçim mevcut feed route'u içinde kalır.

Yeni NavigationBar veya NavigationDrawer destination oluşturulmaz.

Request yalnız canonical contract'ta tanımlanan endpoint, parametre ve değer mapping'iyle oluşturulur.

UI kendi following, followedOnly, scope veya benzeri query parametresi/değeri üretmez.

Filtre değişiminde önceki liste yeni scope altında stale içerik olarak gösterilmez.

Loading yalnız feed gövdesini etkiler.

Empty state filtre bağlamını açıkça belirtir.

Retry aynı seçili filtreyi korur.

Contract unavailable

Canonical feed contract takip edilen hesaplarla sınırlı bir request mapping'i tanımlamıyorsa yüzey tasarımdan çıkarılmaz.

Widget hierarchy:

FeedPage
├── AppBar
└── body
    └── Column
        ├── feed filter region
        │   └── Tooltip / helper region
        │       └── disabled FilterChip
        │           └── Text("Takip Ettiklerim")
        ├── Text("Takip Ettiklerim görünümü şu anda kullanılamıyor.")
        └── Expanded
            └── canonical default feed

Kurallar:

Disabled yüzey herhangi bir HTTP isteği üretmez.

Kullanıcıya default feed gösterilmeye devam edilir.

“Takip Ettiklerim” seçilmiş gibi sahte state oluşturulmaz.

Yeni endpoint veya parametre icat edilmez.

Bu durum kabul yüzeyinin tasarlandığını kanıtlar; kriter kapsamdan çıkarılmış sayılmaz.

Profil ilişki göstergeleri — zorunlu kabul yüzeyi

Token: {components.relationship-indicators}

Bu yüzey “Seni takip ediyor” ve “Karşılıklı takip” durumlarını kapsar ve iki contract durumuyla tasarlanır.

Contract available

Canonical profile/relationship response gerekli ilişki bilgisini güvenilir biçimde sağlıyorsa başka kullanıcı profilinde relationship CTA yakınında gösterilir.

Widget hierarchy:

ProfileHeader
└── Column
    ├── identity row
    │   ├── CircleAvatar
    │   └── Column
    │       ├── Text(displayName)
    │       └── Text("@username")
    ├── relationship indicator region
    │   └── Wrap
    │       ├── optional AssistChip
    │       │   └── Text("Seni takip ediyor")
    │       └── optional AssistChip
    │           └── Text("Karşılıklı takip")
    └── relationship CTA
        └── FilledButton | OutlinedButton

fluttertemplates: Social Profile — /widgets/social

Kurallar:

“Seni takip ediyor” yalnız canonical response bunun doğru olduğunu açıkça gösteriyorsa görünür.

“Karşılıklı takip” yalnız canonical response iki yönlü ilişkiyi güvenilir biçimde belirlemeye izin veriyorsa görünür.

Göstergeler tahmin amacıyla follower/following count değerlerinden türetilmez.

CTA state'i ile indicator state'i farklı kaynaklardan geliyorsa biri diğerinden varsayılmaz.

Kendi profilinde bu relationship göstergeleri gösterilmez.

Mutation sonrasında canonical response/refetch ile yeniden hesaplanır.

Contract unavailable

Canonical response gerekli ilişki bilgisini sağlamıyorsa kabul yüzeyi tasarımdan çıkarılmaz; nötr bir unavailable durumu tanımlanır.

Widget hierarchy:

ProfileHeader
└── Column
    ├── identity row
    ├── relationship indicator region
    │   └── Text("İlişki bilgisi kullanılamıyor")
    └── canonical relationship CTA, available ise

Kurallar:

“Seni takip ediyor” veya “Karşılıklı takip” etiketi sahte olarak gösterilmez.

Nötr unavailable metni ilişki yönü iddia etmez.

Bu durum takip/follow CTA'sını canonical state destekliyorsa engellemez.

Response alanı veya ikinci bir ilişki endpoint'i tasarım tarafından uydurulmaz.

Canonical destek eklendiğinde aynı region available hierarchy'ye geçer; navigation yapısı değişmez.

Screen states

FollowersPage

Empty state:

title: "Henüz takipçi yok"

description: "Bu profili takip eden hesaplar burada görünecek."

primaryCta: yok

Error state:

title: "Takipçiler yüklenemedi"

description: "Bağlantını kontrol edip yeniden deneyebilirsin."

primaryCta: "Yeniden Dene"

401:

merkezi login/session akışına yönlendir.

403:

title: "Bu listeye erişilemiyor"

empty state olarak gösterilmez.

FollowingPage

Empty state:

title: "Henüz takip edilen hesap yok"

description: "Bu profilin takip ettiği hesaplar burada görünecek."

primaryCta: yok

Error state:

title: "Takip edilenler yüklenemedi"

description: "Bağlantını kontrol edip yeniden deneyebilirsin."

primaryCta: "Yeniden Dene"

401:

merkezi login/session akışına yönlendir.

403:

title: "Bu listeye erişilemiyor"

empty state olarak gösterilmez.

Takip Ettiklerim feed filtresi

Available empty state:

title: "Takip ettiklerinden henüz gönderi yok"

description: "Takip ettiğin hesapların gönderileri burada görünecek."

primaryCta: yok

Available error state:

title: "Gönderiler yüklenemedi"

description: "Bağlantını kontrol edip yeniden deneyebilirsin."

primaryCta: "Yeniden Dene"

Contract-unavailable:

title: "Takip Ettiklerim"

description: "Takip Ettiklerim görünümü şu anda kullanılamıyor."

primaryCta: yok

default feed görünmeye devam eder.

İlişki göstergeleri

Available:

exact canonical state'e göre “Seni takip ediyor” ve/veya “Karşılıklı takip” gösterilir.

Contract-unavailable:

title: yok

description: "İlişki bilgisi kullanılamıyor."

ilişki yönü tahmin edilmez.

Follow / unfollow mutation

Success:

Takip sonrası snackbar: "Takip edildi."

Takipten çıkarma sonrası snackbar: "Takipten çıkarıldı."

Error:

title: yok

snackbar: "İşlem tamamlanamadı. Tekrar deneyin."

doğrulanmış önceki relationship state korunur.

Navigation

ProfilePage(username) → “Takipçi” sayacı → FollowersPage(username).

ProfilePage(username) → “Takip” sayacı → FollowingPage(username).

FollowersPage kullanıcı satırı → ProfilePage(row.username).

FollowingPage kullanıcı satırı → ProfilePage(row.username).

“Takip Ettiklerim” mevcut FeedPage içinde filtre yüzeyidir; yeni top-level destination değildir.

Relationship indicator kullanıcıyı yeni route'a götürmez; profil bağlamında salt-okunur durum göstergesidir.

Follow/unfollow CTA profil route'unu değiştirmez.

Route username hiçbir durumda current-user username ile sessizce değiştirilmez.

Do's and Don'ts

Do:

Canonical contract tarafından sağlanan relationship state'i kullan.

Feed filtresini contract available/unavailable olarak açık tasarla.

Relationship göstergelerini contract available/unavailable olarak açık tasarla.

Sayaçlardan gerçek liste ekranlarına navigasyon sağla.

404/kayıt-yok semantiğini empty state olarak ele al.

Retry sırasında mevcut route ve filtre bağlamını koru.

Don't:

“Takip Ettiklerim” kriterini canonical destek yok diye tasarım kapsamından çıkarma.

“Seni takip ediyor / Karşılıklı takip” kriterini canonical destek yok diye silme.

Canonical contract'ta olmayan query parametresi veya endpoint üretme.

Follower/following count üzerinden ilişki yönü tahmin etme.

Network/5xx/403 durumlarını empty state gibi gösterme.

Başka profil route'unu current-user username ile değiştirme.