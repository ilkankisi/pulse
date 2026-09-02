Feature: Öncelik 3 güvenlik ve yönetim deneyimi

Scope

Bu feature güvenlik ve yetkili moderasyon deneyimini tamamlar:

Başka kullanıcıyı engelleme.

Engeli kaldırma.

Oturum sahibinin engellediği hesapları görüntüleme.

Engellenen hesaplar listesinden engeli kaldırma.

Gönderiyi şikâyet etme.

Başka kullanıcı hesabını şikâyet etme.

Canonical report reason seçeneklerini kullanma.

Moderator kullanıcının şikâyet kuyruğunu görüntülemesi.

Moderasyon kuyruğunu canonical ReportStatus ile filtreleme.

Şikâyet detayını görüntüleme.

Pending şikâyeti NoAction veya uygun olduğunda RemovePost ile resolve etme.

Pending şikâyeti dismiss etme.

Moderasyon mutation sonuçlarını backend response ile senkronize etme.

Tüm endpoint, request alanı, enum, permission ve HTTP davranışları canonical docs/api-contract.md sözleşmesinden map edilir.

UI:

API kontratında olmayan güvenlik veya moderasyon endpoint'i üretmez.

ReportTargetType, ReportReason, ReportStatus ve ModerationAction değerlerini yeniden adlandırmaz.

Block ilişkisinin server-side görünürlük semantiğini client-side ikinci kez modellemez.

404 sonucundan block varlığını tahmin edip kullanıcıya açıklamaz.

Moderator olmayan kullanıcıya moderator navigation veya action göstermez.

Standart post silme endpoint'ini moderasyon kaldırması için kullanmaz.

Mutation sonrasında yalnız local optimistic state'i kalıcı doğruluk kaynağı kabul etmez.

User flows

Kullanıcı engelleme

Başka kullanıcı profili → güvenlik/overflow menüsü → “Kullanıcıyı Engelle”.

Kendi profilinde engelleme aksiyonu gösterilmez.

Kullanıcı aksiyonu seçtiğinde confirmation dialog açılır.

“İptal” → dialog kapanır, mutation yapılmaz.

“Engelle” → canonical POST /api/v1/profiles/{username}/block çağrılır.

Mutation sırasında destructive CTA loading/disabled olur ve tekrar tetiklenemez.

Başarı response'undaki canonical:

username

isBlocked=true

state'in doğruluk kaynağıdır.

Başarı sonrası:

“Kullanıcı engellendi.” geri bildirimi gösterilir.

Artık görünür olmaması gereken profil/feed/sosyal graf verisi invalidate/refetch edilir.

UI block nedeniyle kaldırılması gereken follow ilişkilerini client-side yeniden üretmez.

400 self-block UI tarafından normal akışta oluşturulmaz.

404 hedefin bulunamadığı veya görünmez olduğu canonical semantikle ele alınır; UI bunun block kaynaklı olduğunu tahmin etmez.

401 merkezi login akışına gider.

Network/5xx profil ekranını başarılı bir blocked state'e dönüştürmez.

Engeli kaldırma

Engellenen hesaplar ekranı veya doğrulanmış blocked-state yüzeyi → “Engeli Kaldır”.

Canonical DELETE /api/v1/profiles/{username}/block çağrılır.

Mutation sırasında yalnız ilgili satır/aksiyon loading/disabled olur.

Başarılı 204 No Content sonrası:

“Engel kaldırıldı.” geri bildirimi gösterilir.

İlgili blocked-users read state invalidate/refetch edilir.

Profil/feed/sosyal graf verisi gerektiğinde yeniden yüklenir.

Eski follow ilişkisi otomatik geri oluşturulmaz.

UI local olarak follow durumunu eski haline döndürmez.

Block kaydı zaten yoksa canonical idempotent 204 başarı olarak ele alınır.

401 merkezi login akışına gider.

Network/5xx durumunda önceki doğrulanmış blocked state korunur.

Engellenen hesapları görüntüleme

Ayarlar/güvenlik erişim noktası → Engellenen Hesaplar.

Canonical GET /api/v1/blocks çağrılır.

Başarı response'undaki items render edilir.

Her satır yalnız canonical alanları kullanır:

id

username

displayName

avatarUrl

blockedAt

items=[] başarılı empty state'tir.

Kayıt yokluğu 404 olarak yorumlanmaz.

Satırdaki “Engeli Kaldır” aksiyonu ilgili username için canonical unblock endpoint'ini kullanır.

Block nedeniyle normal profil görünürlüğünün 404 olabilmesi nedeniyle blocked-users satırında profile navigation zorunlu kabul edilmez.

UI blocked-users listesine follow CTA eklemez.

Gönderi şikâyeti

Başkasına ait görünür gönderi → overflow → “Şikâyet Et”.

Kullanıcının kendi gönderisinde report aksiyonu gösterilmez.

Şikâyet bottom sheet açılır.

Gönderi için request mapping:

targetType = "Post"

targetId = post.id

reason = seçilen canonical ReportReason

details = kullanıcı açıklaması veya null

targetId integer'dır.

Reason seçilmeden submit aktif olmaz.

details en fazla 500 karakterdir.

Submit → canonical POST /api/v1/reports.

Başarı 201 Created sonrası backend report response kabul edilir ve:

“Şikâyetiniz alındı” geri bildirimi gösterilir.

sheet kapanır.

Rapor oluşturulması hedef gönderiyi otomatik olarak UI'dan kaldırılmış kabul ettirmez.

409 duplicate pending report:

form state korunur,

başarılı report olarak gösterilmez,

kullanıcıya bu hedef için bekleyen bir şikâyet bulunduğunu anlatan non-destructive hata gösterilir.

404 hedefin artık bulunamadığı/görünmediği durumdur.

400 validation/enum hatası canonical error semantiğiyle gösterilir.

401 merkezi login akışına gider.

Network/5xx reason ve details alanlarını temizlemez.

Kullanıcı hesabını şikâyet etme

Başka kullanıcı profili → güvenlik menüsü → “Şikâyet Et”.

Kendi profilinde report aksiyonu gösterilmez.

Kullanıcı için request mapping:

targetType = "User"

targetId = profile.id

reason = seçilen canonical ReportReason

details = kullanıcı açıklaması veya null

Submit ve hata davranışı gönderi şikâyetiyle aynı report component'ini reuse eder.

UI username değerini targetId yerine göndermez.

UI postId, userId, reportType, categoryCode veya targetIdentifier request alanı üretmez.

Moderasyon kuyruğu

Moderator navigation → Moderasyon.

İlk yüklemede canonical GET /api/v1/moderation/reports çağrılır.

Query verilmediğinde backend varsayılan Pending semantiği kullanılır.

Filtre kontrolü yalnız canonical ReportStatus değerlerini sunar:

Pending

Resolved

Dismissed

Filtre seçildiğinde yalnız canonical status query parametresi ve exact enum string'i kullanılır.

UI open, closed, all, reviewing veya benzeri yeni status üretmez.

Yeni filtre isteği başladığında eski filtrenin geciken cevabı güncel listeyi overwrite etmez.

Liste öğeleri canonical moderation report alanlarını kullanır:

id

reporterUserId

targetType

targetId

reason

details

status

createdAt

resolvedAt

resolvedByUserId

Satıra dokunma → ModerationDetailPage(report.id).

items=[] başarılı empty state'tir.

401 merkezi login akışına gider.

403 moderator olmayan kullanıcı için yetki durumudur; empty state değildir.

Network/5xx retry state'tir; başarılı boş kuyruk gibi gösterilmez.

Moderasyon şikâyet detayı

ModerationDetailPage(reportId) → canonical GET /api/v1/moderation/reports/{reportId}.

Detay canonical response alanlarını render eder.

Pending report:

resolve aksiyonları gösterilir,

dismiss aksiyonu gösterilir.

Resolved veya Dismissed report:

geçmiş durum ve resolution metadata gösterilir,

tekrar transition başlatan aksiyonlar gösterilmez.

404 report artık bulunamadı durumudur.

401 merkezi login akışına gider.

403 moderator yetkisi hatasıdır.

Report resolve

Yalnız status="Pending" report için resolve aksiyonları gösterilir.

Canonical ModerationAction seçenekleri:

NoAction

RemovePost

NoAction:

Post veya User target için kullanılabilir.

Target kaynağını değiştirmez.

RemovePost:

yalnız targetType="Post" olduğunda gösterilir,

targetType="User" report için render edilmez,

destructive/moderation confirmation sonrasında submit edilir,

standart DELETE /api/v1/posts/{postId} çağrılmaz.

Resolve request:

action = seçilen exact canonical ModerationAction

note = moderator notu veya null

note en fazla 500 karakterdir.

Submit → POST /api/v1/moderation/reports/{reportId}/resolve.

Mutation sırasında ilgili CTA'lar disabled olur ve ikinci transition gönderilemez.

Başarılı backend response:

id

status="Resolved"

action

resolvedAt

resolvedByUserId

detay ve kuyruk state'inin doğruluk kaynağıdır.

Başarı sonrası detay state güncellenir ve ilgili moderation queue invalidate/refetch edilir.

409 report artık Pending değilse:

başarılı mutation gibi gösterilmez,

form/not state korunur,

report canonical detay endpoint'inden yeniden yüklenir.

400 geçersiz action veya RemovePost + User target kombinasyonu normal success'e dönüştürülmez.

404 kayıp report state'idir.

401 merkezi login akışına gider.

403 yetki hatasıdır.

Network/5xx moderator notunu temizlemez.

Report dismiss

Yalnız status="Pending" report için “Reddet” aksiyonu gösterilir.

Dismiss request:

note = moderator notu veya null

note en fazla 500 karakterdir.

Destructive/state-transition confirmation sonrasında canonical:

POST /api/v1/moderation/reports/{reportId}/dismiss

çağrılır.

Başarılı backend response:

id

status="Dismissed"

resolvedAt

resolvedByUserId

state'in doğruluk kaynağıdır.

Dismiss target kaynağını kaldırmaz.

409 report artık Pending değilse mevcut form state korunur ve canonical report yeniden yüklenir.

401 merkezi login akışına gider.

403 yetki hatasıdır.

404 report bulunamadı durumudur.

Network/5xx moderator notunu temizlemez.

Components

Engellenen hesap listesi öğesi

Token: {components.social-graph-list-item}, {components.relationship-button}

Widget hierarchy:

BlockedUserListItem
└── Padding
    └── Row
        ├── CircleAvatar
        ├── Expanded
        │   └── Column(crossAxis: start)
        │       ├── Text(displayName)
        │       ├── Text("@username")
        │       └── Text(blockedAt, secondary metadata)
        └── OutlinedButton("Engeli Kaldır")

Kurallar:

Canonical GET /api/v1/blocks alanlarını kullanır.

Follow/unfollow CTA göstermez.

Unblock mutation sırasında yalnız ilgili satır CTA'sı disabled/loading olur.

Minimum dokunma alanı 44x44px'tir.

Uzun display name uygun ellipsis davranışı kullanabilir.

blockedAt ikincil metadata'dır.

Güvenlik aksiyon menüsü

Token: {components.safety-action-menu}

Widget hierarchy:

MenuAnchor | PopupMenuButton
└── context actions
    ├── başka kullanıcı postu:
    │   └── MenuItemButton
    │       ├── Icon(flag_outlined)
    │       └── Text("Şikâyet Et")
    └── başka kullanıcı profili:
        ├── MenuItemButton
        │   ├── Icon(flag_outlined)
        │   └── Text("Şikâyet Et")
        └── MenuItemButton
            ├── Icon(block)
            └── Text("Kullanıcıyı Engelle")

Kurallar:

Kendi profilinde block/report gösterilmez.

Kendi postunda report gösterilmez.

Menü yalnız mevcut canonical aksiyonları başlatır.

Menu item minimum 44x44px dokunma alanına sahiptir.

Engelleme onay dialogu

Token: {components.safety-action-menu}, {colors.error}

Widget hierarchy:

AlertDialog
├── title: Text("Kullanıcı engellensin mi?")
├── content: Text("Bu kullanıcıyla olan görünürlük ve takip ilişkileri değişebilir.")
└── actions
    ├── TextButton("İptal")
    └── FilledButton("Engelle")

Kurallar:

Confirmation olmadan block mutation başlamaz.

CTA loading sırasında tekrar tetiklenemez.

UI follow ilişkilerinin kaldırılma ayrıntısını client-side mutation zinciri olarak uygulamaz; canonical block endpoint sonucu ve sonraki read state kullanılır.

Şikâyet bottom sheet

Token: {components.report-sheet}, {components.input}, {components.primary-button}

Widget hierarchy:

ReportSheet
└── SafeArea
    └── Form
        └── Column(mainAxisSize: min)
            ├── drag handle
            ├── Text("Şikâyet Et")
            ├── Text("Neden şikâyet ediyorsun?")
            ├── RadioGroup | RadioListTile[]
            │   ├── Spam
            │   ├── Harassment
            │   ├── HateSpeech
            │   ├── Violence
            │   ├── SexualContent
            │   ├── Impersonation
            │   └── Other
            ├── TextFormField
            │   ├── label: "Açıklama (isteğe bağlı)"
            │   ├── multiline
            │   └── maxLength: 500
            └── FilledButton("Şikâyet Et")

Kurallar:

Görsel etiketler lokalize edilebilir; serializer canonical enum string'ini birebir üretir.

Post ve User report aynı component'i reuse eder.

Reason seçilmeden submit aktif olmaz.

Klavye açıkken submit erişilebilir kalır.

Ağ/5xx ve 409 durumunda form içeriği korunur.

targetType yalnız "Post" veya "User" olur.

targetId integer canonical resource id'dir.

Moderasyon durum filtresi

Token: {typography.label-md}, {colors.primary-container}

Widget hierarchy:

ModerationStatusFilter
└── SegmentedButton | single-select FilterChip group
    ├── Text("Bekleyen")
    ├── Text("Sonuçlandırılan")
    └── Text("Reddedilen")

Canonical mapping:

“Bekleyen” → Pending

“Sonuçlandırılan” → Resolved

“Reddedilen” → Dismissed

Kurallar:

UI başka status üretmez.

Seçim yalnız canonical status query parametresine map edilir.

Her seçim minimum 44x44px dokunma alanına sahiptir.

Loading sırasında aktif filtre görünür kalır.

Moderasyon kuyruğu kartı

Token: {components.moderation-card}

Widget hierarchy:

ModerationReportCard
└── Card
    └── InkWell
        └── Padding
            └── Column(crossAxis: start)
                ├── Row
                │   ├── Text(targetType)
                │   └── status badge
                ├── Text(reason)
                ├── optional Text(details)
                ├── Text("Hedef #targetId")
                ├── Text(createdAt)
                └── optional resolution metadata

Kurallar:

Card navigation hedefi report.id kullanır.

Target veya reporter için canonical response'ta bulunmayan displayName/username uydurulmaz.

reporterUserId, targetId ve tarih metadata'sı ikincil görsel ağırlıktadır.

Status badge yalnız canonical ReportStatus değerine map edilir.

Moderasyon detay paneli

Token: {components.moderation-card}, {components.input}, {components.primary-button}

Widget hierarchy:

ModerationDetailPage
└── Scaffold
    ├── AppBar
    │   └── Text("Şikâyet Detayı")
    └── SafeArea
        └── CustomScrollView
            └── SliverToBoxAdapter
                └── Column
                    ├── report summary
                    ├── target metadata
                    ├── reporter metadata
                    ├── reason
                    ├── optional details
                    ├── status
                    ├── createdAt
                    ├── optional resolvedAt / resolvedByUserId
                    └── Pending ise moderation action area

Kurallar:

Detay canonical report response'tan gelir.

UI target içeriğinin contract'ta verilmeyen preview bilgisini uydurmaz.

Pending olmayan report'ta transition CTA gösterilmez.

Resolve formu

Token: {components.input}, {components.primary-button}, {colors.error}

Widget hierarchy:

ResolveReportForm
└── Form
    └── Column
        ├── action selector
        │   ├── NoAction
        │   └── targetType == Post ise RemovePost
        ├── TextFormField
        │   ├── label: "Moderasyon notu (isteğe bağlı)"
        │   ├── multiline
        │   └── maxLength: 500
        └── FilledButton("Sonuçlandır")

Kurallar:

RemovePost User report için gösterilmez.

Action exact canonical serializer değeriyle gönderilir.

Note 500 karakteri aşamaz.

Mutation failure note'u temizlemez.

RemovePost seçildiğinde destructive confirmation gösterilir.

Dismiss onay dialogu

Token: {colors.error}, {components.primary-button}

Widget hierarchy:

AlertDialog
├── title: Text("Şikâyet reddedilsin mi?")
├── content: Text("Bu işlem şikâyeti Dismissed durumuna geçirir; hedef içeriği kaldırmaz.")
└── actions
    ├── TextButton("Vazgeç")
    └── FilledButton("Reddet")

Kurallar:

Yalnız Pending report için kullanılabilir.

Confirmation olmadan dismiss mutation başlamaz.

Loading sırasında tekrar tetiklenemez.

Screen states

Engellenen Hesaplar

Loading

AppBar görünür kalır.

Liste alanında mevcut skeleton/loading pattern'i kullanılır.

Sahte blocked-user satırı gösterilmez.

Empty

Başlık: “Engellenen hesap yok”

Açıklama: “Engellediğin bir hesap bulunmuyor.”

Yalnız başarılı 200 + items=[] için gösterilir.

CTA zorunlu değildir.

Error

Başlık: “Engellenen hesaplar yüklenemedi”

Açıklama: “Liste alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

401 merkezi login akışına gider.

Network/5xx empty state değildir.

Block mutation

Loading

Yalnız confirmation CTA loading/disabled olur.

Profilin geri kalanı kullanılabilir kalır.

Success

“Kullanıcı engellendi.”

Backend sonucu ve sonraki canonical reads render edilir.

Error

Önceki doğrulanmış profil state'i korunur.

CTA tekrar kullanılabilir hale gelir.

401 login akışına gider.

404 block nedenini açıklayan özel mesaj üretmez.

Unblock mutation

Loading

Yalnız ilgili aksiyon disabled/loading olur.

Success

“Engel kaldırıldı.”

Eski follow ilişkisi geri getirilmez.

Error

Önceki doğrulanmış blocked state korunur.

Şikâyet formu

Initial

Reason seçilmemiş olması API empty state değildir.

Submit disabled olur.

Loading

Form değerleri görünür kalır.

Submit tekrar tetiklenemez.

Success

“Şikâyetiniz alındı”

Backend report response kabul edilir.

Conflict

409 duplicate pending report:

Başlık/mesaj: “Bu içerik için bekleyen bir şikâyetin zaten var.”

Form state korunur.

Success state gösterilmez.

Error

Başlık/mesaj: “Şikâyet gönderilemedi. Tekrar deneyin.”

Reason ve details korunur.

401 login akışına gider.

404 hedef artık erişilebilir değil olarak ele alınır.

400 field error ilgili alana bağlanabilir.

Moderasyon Kuyruğu

Loading

AppBar ve seçili status filtresi görünür kalır.

Sahte report kartı gösterilmez.

Empty

Pending filtresi:

Başlık: “Bekleyen şikâyet yok”

Açıklama: “İncelenecek yeni şikâyet bulunmuyor.”

Resolved filtresi:

Başlık: “Sonuçlandırılmış şikâyet yok”

Dismissed filtresi:

Başlık: “Reddedilmiş şikâyet yok”

Empty state yalnız başarılı canonical items=[] response için gösterilir.

Error

Başlık: “Moderasyon kuyruğu yüklenemedi”

Açıklama: “Şikâyetler alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

401 merkezi login akışına gider.

403:

empty state değildir,

moderator UI yetkisinin artık geçerli olmadığı permission state olarak ele alınır,

moderator navigation yeniden yetki state'iyle senkronize edilir.

Moderasyon Detayı

Loading

AppBar görünür kalır.

Detail skeleton/loading pattern'i kullanılır.

Error

404:

Başlık: “Şikâyet bulunamadı”

Form sahte local report ile devam etmez.

401 merkezi login akışına gider.

403 permission state'tir.

Network/5xx:

Başlık: “Şikâyet yüklenemedi”

CTA: “Tekrar Dene”

Pending

Resolve ve dismiss aksiyonları gösterilir.

Resolved

Canonical resolution metadata gösterilir.

Transition CTA gösterilmez.

Dismissed

Canonical resolution metadata gösterilir.

Transition CTA gösterilmez.

Resolve mutation

Loading

Resolve/dismiss transition CTA'ları tekrar tetiklenemez.

Note ve action görünür kalır.

Success

Backend'in canonical Resolved response'u render edilir.

Kuyruk invalidate/refetch edilir.

Conflict

409:

Başlık/mesaj: “Bu şikâyetin durumu değişti.”

Kullanıcının note içeriği mutation sonucu kesinleşene kadar korunur.

Canonical detail yeniden yüklenir.

Artık Pending değilse action formu kaldırılır.

Error

400:

Canonical action/target validation hatasıdır; success gibi gösterilmez.

401 login akışına gider.

403 permission state'tir.

404 report bulunamadı state'idir.

Network/5xx note'u temizlemez.

Dismiss mutation

Loading

Yalnız transition CTA'ları disabled olur.

Success

Backend'in canonical Dismissed response'u render edilir.

Kuyruk invalidate/refetch edilir.

Conflict

409 sonrası canonical detail yeniden yüklenir.

Error

401/403/404 ve network semantiği resolve ile aynı state pattern'ini reuse eder.

Navigation

Başka kullanıcı profili → güvenlik menüsü → “Kullanıcıyı Engelle”.

Başka kullanıcı profili → güvenlik menüsü → “Şikâyet Et”.

Başkasının gönderisi → overflow → “Şikâyet Et”.

Ayarlar/Güvenlik → Engellenen Hesaplar.

Engellenen Hesaplar → satır aksiyonu → “Engeli Kaldır”; route değişmez.

Moderator rolü → Drawer/uygun app-shell destination → Moderasyon.

Moderasyon → report satırı → ModerationDetailPage(report.id).

Moderasyon detail resolve/dismiss mutation route değiştirmez.

Moderator olmayan kullanıcıya Moderasyon destination render edilmez.

401 tüm korumalı güvenlik/moderasyon yüzeylerinden merkezi login akışına gider.

Contract boundaries

Bu feature canonical API'de bulunmayan davranışları tasarım gereksinimi gibi tanımlamaz.

Özellikle:

Block state'i profile response'a yeni isBlocked alanı eklenerek varsayılmaz.

GET /api/v1/blocks dışındaki blocked-user collection route'u üretilmez.

Block nedeniyle gelen 404 başka bir hata biçiminden client-side ayrıştırılmaz.

Unblock eski follow ilişkisini geri getirmez.

Report request yalnız targetType, targetId, reason, details alanlarını kullanır.

Report enum casing birebir canonical değerleri kullanır.

Moderation listesi yalnız canonical status query parametresini kullanabilir.

Pending, Resolved, Dismissed dışında moderation status üretilmez.

NoAction, RemovePost dışında moderation action üretilmez.

RemovePost User report için sunulmaz.

RemovePost için normal post DELETE endpoint'i kullanılmaz.

Dismiss target kaynağını değiştirmez.

Report oluşturmak hedefi otomatik olarak kaldırmaz.

Moderasyon response'ta bulunmayan target preview, kullanıcı adı, policy category veya audit detail uydurulmaz.

Yeni admin role veya permission modeli üretilmez.

Do's and Don'ts

Do

Engellenen hesaplar için GET /api/v1/blocks kullan.

Block için POST /api/v1/profiles/{username}/block kullan.

Unblock için DELETE /api/v1/profiles/{username}/block kullan.

Report için exact canonical ReportTargetType ve ReportReason değerlerini kullan.

targetId için gerçek integer resource id kullan.

Report details ve moderation note alanlarında 500 karakter sınırını koru.

409 duplicate pending report'u success olarak gösterme.

Moderation listesini yalnız moderator rolünde göster.

Moderation status filtresinde canonical enum mapping'ini kullan.

RemovePost aksiyonunu yalnız Post target için göster.

Moderasyon mutation sonrası backend response'u doğruluk kaynağı kabul et.

401'i merkezi login akışına gönder.

403'ü empty state gibi gösterme.

404'ten block varlığı çıkarmaya çalışma.

Network/5xx hatasında form taslağını koru.

Minimum 44x44px dokunma alanını koru.

Dinamik metin ölçeklendirmeyi destekle.

Don'ts

/api/v1/users/... güvenlik route'u üretme.

Block için request body'ye username veya id ekleme.

Unblock sonrasında follow ilişkisini client-side geri kurma.

Report request'te postId, userId, reportType, categoryCode veya targetIdentifier kullanma.

Canonical olmayan report reason alias'ı üretme.

all, open, closed, reviewing gibi moderation status üretme.

remove_post, removePost gibi action alias'ı kullanma.

User report için RemovePost gösterme.

Moderasyon kaldırması için standart post DELETE endpoint'ini çağırma.

Moderator olmayan kullanıcıya queue/detail/action UI gösterme.

403'ü “Bekleyen şikâyet yok” state'ine dönüştürme.

409 transition conflict sonrasında stale local status'u kalıcılaştırma.

Network hatasını başarılı empty collection gibi gösterme.

Contract'ta olmayan admin dashboard, kullanıcı ban/suspend, role edit veya toplu moderasyon aksiyonu ekleme.