Feature: Öncelik 3 güvenlik ve yönetim deneyimi

Scope

Bu feature mevcut güvenlik ve moderasyon sözleşmesini tamamlanmış bir ürün deneyimine dönüştürür:

Kullanıcının engellediği hesapları görüntülemesi

Engellenen kullanıcı listesinden engeli kaldırması

Profil üzerinden block/unblock akışının sosyal state ile güvenli biçimde senkronize edilmesi

Gönderi ve kullanıcı şikâyetlerinde canonical validation ve duplicate pending-report durumlarının gösterilmesi

Moderator kullanıcının Pending, Resolved ve Dismissed raporları canonical status filtresiyle incelemesi

Moderasyon rapor detayının açılması

Pending raporun canonical NoAction veya RemovePost aksiyonuyla resolve edilmesi

Pending raporun dismiss edilmesi

Moderasyon mutation'larında stale/çakışan state'in 409 sonrası canonical backend state ile yeniden yüklenmesi

Tüm endpoint, response, enum, permission ve mutation davranışları canonical docs/api-contract.md sözleşmesinden map edilir.

Canonical veri kaynakları:

Engellenen kullanıcılar: GET /api/v1/blocks

Kullanıcı engelleme: POST /api/v1/profiles/{username}/block

Engel kaldırma: DELETE /api/v1/profiles/{username}/block

Şikâyet gönderme: POST /api/v1/reports

Moderasyon kuyruğu: GET /api/v1/moderation/reports

Status filtreli moderasyon kuyruğu: GET /api/v1/moderation/reports?status={ReportStatus}

Moderasyon rapor detayı: GET /api/v1/moderation/reports/{reportId}

Raporu sonuçlandırma: POST /api/v1/moderation/reports/{reportId}/resolve

Raporu reddetme: POST /api/v1/moderation/reports/{reportId}/dismiss

Canonical enum değerleri:

ReportTargetType

Post

User

ReportReason

Spam

Harassment

HateSpeech

Violence

SexualContent

Impersonation

Other

ReportStatus

Pending

Resolved

Dismissed

ModerationAction

NoAction

RemovePost

UI:

API kontratında olmayan endpoint üretmez.

API kontratında olmayan role veya permission üretmez.

Enum değerlerinin casing'ini değiştirmez.

GET /api/v1/blocks için pagination, cursor, search veya sort parametresi üretmez.

Moderasyon kuyruğunda canonical status dışında query parametresi üretmez.

Block ve moderasyon görünürlük kurallarını client tarafında yeniden hesaplamaz.

404 sonucundan block ilişkisinin yönünü veya nedenini çıkarmaya çalışmaz.

Normal kullanıcıya moderator navigation veya moderator mutation aksiyonu göstermez.

Moderatöre canonical olmayan kullanıcı yaptırımı, hesap kapatma veya kullanıcı silme aksiyonu üretmez.

User flows

Engellenen kullanıcıları görüntüleme

Güvenlik/Ayarlar giriş noktası → BlockedUsersPage.

Sayfa GET /api/v1/blocks çağrısını yapar.

Response items sırası backend'in döndürdüğü biçimde korunur.

Her satır canonical response içindeki id, username, displayName, avatarUrl ve blockedAt alanlarını kullanır.

items=[] normal empty state'tir.

Boş liste 404 gibi yorumlanmaz.

401 merkezi login akışına gider.

Ağ/5xx retry error state'tir.

Engellenen kullanıcı listesinden engeli kaldırma

Satırdaki “Engeli Kaldır” aksiyonu seçilir.

Mutation path her zaman row.username ile oluşturulur.

DELETE /api/v1/profiles/{row.username}/block çağrılır.

Mutation sırasında yalnız ilgili satır aksiyonu disabled/loading olur.

Başarılı 204 sonrasında:

liste canonical GET /api/v1/blocks sonucuyla yeniden senkronize edilir,

eski follow ilişkisi geri yüklenmiş gibi gösterilmez,

başarı mesajı “Engel kaldırıldı.” olur.

UI relationship state'i tahmin etmez.

Profil üzerinden kullanıcı engelleme

Başka profil → güvenlik menüsü → “Kullanıcıyı Engelle”.

Confirmation dialog gösterilir.

Onay sonrası POST /api/v1/profiles/{profile.username}/block çağrılır.

Request body gönderilmez.

Başarı response'undaki username ve isBlocked=true canonical kaynak kabul edilir.

Block mevcut follow ilişkilerini backend tarafında kaldırdığından:

cached relationship state kalıcı gerçek kabul edilmez,

ilgili profil ve sosyal graf read state invalidate edilir,

feed gerekiyorsa canonical endpoint'ten yeniden yüklenir.

Block sonrası hedef profil erişilemez duruma gelirse stale profil detayı gösterilmeye devam etmez.

Güvenli önceki route'a dönülür.

Başarı mesajı “Kullanıcı engellendi.” olur.

UI hangi postların veya kullanıcıların gizleneceğini ayrıca hesaplamaz.

Profil üzerinden engeli kaldırma

Canonical state kullanıcı için “Engeli Kaldır” aksiyonunu kanıtlı biçimde sağlayabiliyorsa:

DELETE /api/v1/profiles/{username}/block

Başarılı 204 → “Engel kaldırıldı.”

Eski follow ilişkileri geri getirilmez.

Follow state canonical profile/social-graph read sonucundan yeniden edinilir.

Canonical state mevcut değilse UI yalnız local tahminle “Engeli Kaldır” görünürlüğü üretmez; unblock yönetimi GET /api/v1/blocks tabanlı BlockedUsersPage üzerinden sağlanır.

Gönderi şikâyeti

Başkasının gönderisi → overflow → “Şikâyet Et”.

Bottom sheet:

targetType="Post"

targetId=post.id

Reason yalnız canonical ReportReason listesinden seçilir.

Opsiyonel details maksimum 500 karakterdir.

Reason seçilmeden submit yapılamaz.

Başarı 201:

backend response canonical kaynak kabul edilir,

sheet kapanır,

“Şikâyetiniz alındı” gösterilir.

400:

canonical validation mesajı ilgili form bağlamında gösterilir.

409:

yeni report oluşturulmuş gibi success gösterilmez,

“Bu içerik için zaten bekleyen bir şikâyetin var.” mesajı gösterilir.

Ağ/5xx:

seçilmiş reason ve details korunur.

Kullanıcı şikâyeti

Başka profil → güvenlik menüsü → “Şikâyet Et”.

Bottom sheet:

targetType="User"

targetId=profile.id

Gönderi şikâyetiyle aynı component ve serializer kullanılır.

Kendi hesabını şikâyet etmeye yönelik UI gösterilmez.

Başarı, validation, 409 ve network state davranışları gönderi şikâyetiyle aynıdır.

Moderasyon kuyruğu

Moderator → “Moderasyon”.

İlk giriş canonical varsayılan Pending kuyruğu gösterir.

Status filtreleri:

“Bekleyen” → Pending

“Sonuçlanan” → Resolved

“Reddedilen” → Dismissed

Filtre seçimi yalnız canonical status query parametresini üretir.

Query verilmediğinde backend varsayılanı Pending olduğu için ilk yüklemede query zorunlu değildir.

Status değişiminde eski isteğin geciken cevabı yeni status listesini overwrite etmez.

items=[] seçili status için normal empty state'tir.

403 empty state değildir.

401 merkezi login akışına gider.

Moderasyon rapor detayı

Kuyruk kartı → ModerationReportDetailPage(report.id).

GET /api/v1/moderation/reports/{reportId} çağrılır.

Detay canonical response'taki:

reporterUserId

targetType

targetId

reason

details

status

createdAt

resolvedAt

resolvedByUserId

alanlarını gösterir.

Pending değilse resolve/dismiss mutation CTA'ları gösterilmez.

Resolved ve Dismissed kayıtlar read-only inceleme yüzeyidir.

404 → “Şikâyet bulunamadı”.

403 → yetki hatasıdır.

401 → merkezi login akışıdır.

Pending raporu resolve etme

Yalnız status="Pending" raporda kullanılabilir.

targetType="Post" için:

NoAction

RemovePost

canonical aksiyonları gösterilebilir.

targetType="User" için:

RemovePost sunulmaz.

Canonical resolve aksiyonu NoAction olur.

UI hesap kapatma, askıya alma veya kullanıcı silme gibi contract dışı aksiyon üretmez.

Resolve form:

action zorunludur.

note opsiyoneldir.

note maksimum 500 karakterdir.

Submit → POST /api/v1/moderation/reports/{reportId}/resolve

Request body path id'sini tekrar içermez.

Başarı sonrası:

canonical mutation response kaynak kabul edilir,

rapor detayı yeniden yüklenir,

aktif moderasyon listesi yeniden yüklenir,

RemovePost seçildiyse standart owner DELETE endpoint'i ayrıca çağrılmaz,

post görünürlüğü client tarafında yeniden hesaplanmaz.

Pending raporu dismiss etme

Yalnız status="Pending" raporda kullanılabilir.

Opsiyonel note maksimum 500 karakterdir.

Submit → POST /api/v1/moderation/reports/{reportId}/dismiss

Request body yalnız canonical note alanını içerir.

Başarı response canonical kaynak kabul edilir.

Dismiss target kaynağını değiştirmez.

Detay ve aktif kuyruk canonical GET endpoint'lerinden yeniden yüklenir.

Moderasyon mutation çakışması

Resolve veya dismiss sırasında 409 dönerse:

mutation loading kapanır,

success state gösterilmez,

local olarak Resolved veya Dismissed state üretilmez,

“Şikâyet başka bir işlemle güncellendi.” mesajı gösterilir,

rapor detayı canonical GET ile yeniden yüklenir,

aktif kuyruk yeniden yüklenir,

backend'in güncel status değeri kaynak kabul edilir.

Components

Engellenen kullanıcı satırı

Token: {components.social-graph-list-item}, {components.relationship-button}

Widget hierarchy:

BlockedUserListItem(user)
└── ConstrainedBox(minHeight: 72)
    └── Padding
        └── Row
            ├── CircleAvatar(size: 48)
            ├── SizedBox(width: spacing.md)
            ├── Expanded
            │   └── Column(crossAxis: start)
            │       ├── Text(user.displayName)
            │       ├── Text("@${user.username}")
            │       └── Text(blockedAt)
            └── OutlinedButton("Engeli Kaldır")
                └── loading | label

Kurallar:

Minimum dokunma alanı 44x44px'tir.

Satır canonical kullanıcı alanlarını kullanır.

blockedAt {typography.body-sm} kullanır.

Mutation sırasında yalnız ilgili CTA loading olur.

Satır üzerinde follow/unfollow gösterilmez.

Block listesi local profile cache'inden türetilmez.

Engellenen kullanıcılar ekranı

Token: {components.state-panel}, {components.social-graph-list-item}

Widget hierarchy:

BlockedUsersPage
└── Scaffold
    ├── AppBar
    │   ├── leading: BackButton
    │   └── title: Text("Engellenen Hesaplar")
    └── SafeArea
        └── state
            ├── loading-state
            ├── empty-state
            ├── error-state
            └── CustomScrollView
                └── SliverList
                    └── BlockedUserListItem[]

Kurallar:

Veri kaynağı yalnız GET /api/v1/blocks olur.

Boş liste için primary CTA zorunlu değildir.

Search/filter UI eklenmez.

Pagination/cursor üretilmez.

Şikâyet bottom sheet

Token: {components.report-sheet}, {components.input}, {components.primary-button}

Widget hierarchy:

ReportSheet(targetType, targetId)
└── showModalBottomSheet
    └── SafeArea
        └── Form
            └── Column(mainAxisSize: min)
                ├── drag handle
                ├── Text("Şikâyet Et")
                ├── canonical ReportReason options
                ├── TextFormField
                │   ├── label: "Açıklama (isteğe bağlı)"
                │   ├── multiline
                │   └── maxLength: 500
                ├── inline validation/conflict message
                └── FilledButton("Şikâyet Et")

Kurallar:

Gönderi ve kullanıcı aynı serializer'ı kullanır.

targetType, targetId, reason, details dışında request alanı üretilmez.

Pending duplicate 409 success state değildir.

Moderasyon status filtresi

Widget hierarchy:

ModerationPage
└── Column
    ├── SingleChildScrollView(horizontal)
    │   └── Row
    │       ├── FilterChip("Bekleyen")
    │       ├── FilterChip("Sonuçlanan")
    │       └── FilterChip("Reddedilen")
    └── Expanded
        └── selected status state

Kurallar:

Chip label'ları görsel localization'dır.

API'ye yalnız canonical Pending, Resolved, Dismissed değerleri gönderilir.

Aynı anda tek status seçili olur.

Moderator olmayan kullanıcıya filtre yüzeyi gösterilmez.

Filtre değişimi stale request korumasına sahiptir.

Moderasyon rapor kartı

Token: {components.moderation-card}

Widget hierarchy:

ModerationReportCard(report)
└── Card
    └── InkWell
        └── Padding
            └── Column(crossAxis: start)
                ├── Row
                │   ├── Expanded
                │   │   └── target summary
                │   └── status badge
                ├── Text(report.reason)
                ├── optional Text(report.details)
                ├── Text(createdAt)
                └── pending ise Text("İncele")

Kurallar:

Kart tap → ModerationReportDetailPage(report.id).

Status badge canonical ReportStatus değerinden map edilir.

Contract dışı hedef preview datası varsayılmaz.

API yalnız target id sağlıyorsa UI kullanıcı/post içeriği üretmez.

Moderasyon rapor detayı

Token: {components.moderation-card}, {components.input}, {components.primary-button}

Widget hierarchy:

ModerationReportDetailPage(reportId)
└── Scaffold
    ├── AppBar
    │   └── title: Text("Şikâyet Detayı")
    └── SafeArea
        └── state
            ├── loading
            ├── error
            └── CustomScrollView
                └── SliverToBoxAdapter
                    └── Column
                        ├── report metadata
                        ├── Divider
                        └── status == Pending ise action area
                            ├── targetType == Post ise
                            │   └── action selector
                            │       ├── NoAction
                            │       └── RemovePost
                            ├── targetType == User ise
                            │   └── NoAction resolve affordance
                            ├── optional note field
                            └── actions
                                ├── FilledButton("Sonuçlandır")
                                └── OutlinedButton("Reddet")

Kurallar:

Resolved/Dismissed detayda mutation CTA'ları gösterilmez.

RemovePost yalnız targetType=Post iken seçilebilir.

API serialization canonical enum casing'ini korur.

Note maksimum 500 karakterdir.

Resolve ve dismiss aynı anda tetiklenemez.

Mutation sırasında aksiyon alanı tekrar submit edilemez.

409 sonrasında detail canonical GET ile yenilenir.

Screen states

Engellenen Hesaplar

Loading:

Skeleton kullanıcı satırları gösterilir.

Önceki auth session'a ait stale block listesi gösterilmez.

Empty:

Başlık: “Engellediğin hesap yok”

Açıklama: “Engellediğin hesaplar burada görünür.”

CTA yoktur.

items=[] bu state'tir.

Error:

Başlık: “Engellenen hesaplar yüklenemedi”

Açıklama: “Liste alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

401 merkezi login akışına gider.

Success mutation:

“Engel kaldırıldı.”

Kullanıcı engelleme

Loading:

Yalnız block mutation aksiyonu loading olur.

Success:

“Kullanıcı engellendi.”

Stale profil/social relationship görünümü korunmaz.

Error:

400 self-block canonical hata mesajıyla gösterilir.

404 kaynak bulunamadı/kullanılamıyor deneyimidir.

Block nedeni tahmin edilmez.

401 merkezi login akışına gider.

Şikâyet formu

Initial:

Reason seçilmemiş form API empty state değildir.

Submit disabled olur.

Validation:

Canonical field error ilgili form alanında gösterilir.

409:

Post hedefi: “Bu içerik için zaten bekleyen bir şikâyetin var.”

User hedefi: “Bu hesap için zaten bekleyen bir şikâyetin var.”

Success snackbar gösterilmez.

Error:

“Şikâyet gönderilemedi. Tekrar deneyin.”

Reason ve details korunur.

Success:

“Şikâyetiniz alındı”

Moderasyon Kuyruğu

Loading:

Seçili status için skeleton kartlar gösterilir.

Empty Pending:

Başlık: “Bekleyen şikâyet yok”

Açıklama: “İncelenecek yeni şikâyet bulunmuyor.”

Empty Resolved:

Başlık: “Sonuçlanan şikâyet yok”

Açıklama: “Sonuçlandırılmış şikâyet bulunmuyor.”

Empty Dismissed:

Başlık: “Reddedilen şikâyet yok”

Açıklama: “Reddedilmiş şikâyet bulunmuyor.”

Empty state'lerde primary CTA yoktur.

Error:

Başlık: “Moderasyon kuyruğu yüklenemedi”

Açıklama: “Şikâyetler alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

401 merkezi login akışına gider.

403:

Başlık: “Bu alana erişim yetkin yok”

Retry ile yetki kazanılmış gibi davranılmaz.

Moderasyon Detayı

Loading:

Başka rapora ait stale metadata gösterilmez.

404:

Başlık: “Şikâyet bulunamadı”

Açıklama: “Bu şikâyet artık kullanılamıyor.”

403:

Başlık: “Bu alana erişim yetkin yok”

401:

Merkezi login akışına gider.

400:

Canonical resolve/dismiss validation mesajı ilgili alan bağlamında gösterilir.

409:

“Şikâyet başka bir işlemle güncellendi.”

Detail ve aktif liste backend'den yeniden yüklenir.

Success resolve:

“Şikâyet sonuçlandırıldı.”

Success dismiss:

“Şikâyet reddedildi.”

Navigation

Güvenlik/Ayarlar → BlockedUsersPage.

BlockedUsersPage → “Engeli Kaldır”; route değişmez.

Başka profil → güvenlik menüsü → block/report.

Başkasının postu → overflow → report.

Moderator drawer destination → ModerationPage.

Status chip → aynı route içinde canonical status değişir.

Moderasyon kartı → ModerationReportDetailPage(report.id).

Resolve/dismiss başarı → detail güncellenir ve kaynak liste canonical GET ile yenilenir.

Moderator olmayan kullanıcıya ModerationPage destination gösterilmez.

401 tüm korumalı güvenlik/moderasyon yüzeylerinde merkezi login akışına gider.

Cross-feature synchronization

Block sonrası

Başarılı block:

target ile iki yönlü follow ilişkilerinin backend tarafından kaldırılabileceğini kabul eder,

ilgili profile read state'ini invalidate eder,

açık Followers/Following listelerini stale canonical gerçek olarak tutmaz,

feed görünürlüğünü client tarafında elle düzenlemez,

gerektiğinde GET /api/v1/feed ile yeniden yükler,

target profile artık 404 ise bunun block nedeniyle olduğunu kullanıcıya açıklamaz.

Unblock sonrası

Başarılı unblock:

eski follow ilişkisini geri var saymaz,

relationship state için canonical profile/social graph response bekler,

block listesi GET /api/v1/blocks ile yenilenir.

Moderasyon RemovePost sonrası

Başarılı RemovePost:

moderator client standart DELETE /api/v1/posts/{postId} çağrısı yapmaz,

postu local collection'lardan kalıcı gerçekmiş gibi elle silmez,

ilgili canonical read state'lerini invalidate/refetch eder,

normal kullanıcı görünürlüğünü backend'in moderasyon semantiğine bırakır.

Accessibility

Tüm aksiyonlar minimum 44x44px dokunma alanına sahiptir.

Status yalnız renkle ifade edilmez; metin etiketi bulunur.

Destructive block aksiyonu ikon + metinle açıkça etiketlenir.

RemovePost, NoAction, resolve ve dismiss seçimleri screen reader tarafından ayırt edilebilir label taşır.

Loading sırasında odak sebepsiz yere ekranın başına sıçramaz.

Error ve conflict mesajları semantik live region üzerinden duyurulabilir.

Dinamik metin ölçeklendirmede moderator action alanı yatay taşma üretmez.

Uzun details ve note metinleri sabit yükseklikte kesilmez.

Do's and Don'ts

Do

GET /api/v1/blocks response'unu engellenen kullanıcılar yönetiminin canonical kaynağı olarak kullan.

Unblock path'inde satırdaki gerçek username değerini kullan.

Block sonrası relationship ve feed görünürlüğünü backend state ile yeniden senkronize et.

Report request'inde yalnız targetType, targetId, reason, details alanlarını kullan.

Canonical enum string'lerini birebir casing ile serialize et.

Duplicate pending report 409 sonucunu conflict state olarak göster.

Moderasyon kuyruğunda yalnız canonical status filtresini kullan.

İlk moderation kuyruğunun backend varsayılanının Pending olduğunu koru.

Rapor detayı path'inde gerçek integer report.id kullan.

RemovePost aksiyonunu yalnız Post report için sun.

User report resolve için contract dışı kullanıcı yaptırımı üretme.

Resolved/Dismissed rapor detaylarını read-only göster.

Resolve/dismiss 409 sonrasında canonical detail ve listeyi yeniden yükle.

RemovePost sonrasında standart owner delete endpoint'ini çağırma.

401'i merkezi login akışına gönder.

403'ü empty state gibi gösterme.

404 sonucundan block ilişkisi çıkarma.

Don'ts

GET /api/v1/blocks için search, sort, cursor, page veya offset parametresi üretme.

Unblock sonrasında eski follow ilişkisini otomatik geri getirme.

Blocked-users listesini profile cache'inden tahmin etme.

Report enum değerlerini spam, harassment, post veya başka alias/casing ile gönderme.

postId, userId, reportType, categoryCode veya targetIdentifier request alanı üretme.

Duplicate pending report 409 sonucunda yeni report oluşturulmuş gibi success gösterme.

Moderasyon için All, Open, Closed gibi canonical olmayan API status değeri üretme.

Moderator olmayan kullanıcıya moderator navigation veya action gösterme.

User report üzerinde RemovePost aksiyonu sunma.

SuspendUser, BanUser, DeleteUser, WarnUser veya başka contract dışı moderation action üretme.

Resolved veya Dismissed report üzerinde tekrar resolve/dismiss CTA'sı gösterme.

409 sonrasında local state'i zorla success durumuna taşıma.

Moderasyon kaldırması için DELETE /api/v1/posts/{postId} kullanma.

Client tarafında block/moderation görünürlüğünü yeniden implement etme.

404 sonucunu “Bu kullanıcı seni engelledi” mesajına dönüştürme.