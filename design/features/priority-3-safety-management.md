Feature: Öncelik 3 güvenlik ve yönetim deneyimi

Scope

Bu feature mevcut güvenlik ve moderasyon yüzeylerini canonical API kontratıyla tamamlar:

Başka kullanıcıyı engelleme.

Başka kullanıcı üzerindeki engeli kaldırma.

Oturum sahibinin engellediği hesapları görüntüleme.

Engellenen hesaplar listesinden engeli kaldırma.

Başkasının gönderisini şikâyet etme.

Başka kullanıcı hesabını şikâyet etme.

Canonical report reason seçimi ve isteğe bağlı details girişi.

Moderator rolündeki kullanıcı için şikâyet kuyruğunu görüntüleme.

Pending, Resolved ve Dismissed moderation durumlarını canonical filtre ile görüntüleme.

Şikâyet detayını görüntüleme.

Pending şikâyeti canonical NoAction veya uygun olduğunda RemovePost aksiyonuyla resolve etme.

Pending şikâyeti ayrı dismiss işlemiyle kapatma.

Moderasyon note alanını yönetme.

Loading, empty, error, conflict ve success durumlarını tutarlı biçimde ele alma.

Tüm endpoint, request alanı, response alanı, enum, authorization ve HTTP semantiği canonical docs/api-contract.md sözleşmesinden map edilir.

UI:

API kontratında olmayan güvenlik veya moderasyon endpoint'i üretmez.

API kontratında olmayan role, report reason, report status veya moderation action üretmez.

Integer resource id değerlerini string/UUID'ye dönüştürmez.

Block nedeniyle görünmeyen kaynağın neden görünmediğini 404 response'undan tahmin etmez.

Moderasyon response'unda bulunmayan hedef gönderi içeriği, kullanıcı profili veya policy metadata üretmez.

Standart kullanıcı post delete endpoint'ini moderasyon kaldırma aksiyonu olarak kullanmaz.

Canonical API mapping

Block

Engelle:

POST /api/v1/profiles/{username}/block

Request body yoktur.

Başarı response'u:

username

isBlocked=true

Engeli kaldır:

DELETE /api/v1/profiles/{username}/block

Request body yoktur.

Başarı 204 No Content döner.

Engellenen hesaplar:

GET /api/v1/blocks

Başarılı collection response:

items[].id

items[].username

items[].displayName

items[].avatarUrl

items[].blockedAt

Boş liste 200 + {"items":[]} semantiğidir; 404 değildir.

Report

Şikâyet oluştur:

POST /api/v1/reports

Canonical request alanları:

targetType

targetId

reason

details

Canonical ReportTargetType:

Post

User

Canonical ReportReason:

Spam

Harassment

HateSpeech

Violence

SexualContent

Impersonation

Other

Enum string'leri serializer tarafından yukarıdaki casing ile birebir gönderilir.

details isteğe bağlıdır ve maksimum 500 karakterdir.

Post report:

targetType = Post

targetId = post.id

User report:

targetType = User

targetId = profile.id

Alternatif postId, userId, reportType, categoryCode veya targetIdentifier request alanı üretilmez.

Moderation

Kuyruk:

GET /api/v1/moderation/reports

Query verilmezse backend varsayılanı Pending'dir.

Canonical optional status değerleri yalnız:

Pending

Resolved

Dismissed

Detay:

GET /api/v1/moderation/reports/{reportId}

Resolve:

POST /api/v1/moderation/reports/{reportId}/resolve

Canonical request:

action

optional note

Canonical ModerationAction:

NoAction

RemovePost

note maksimum 500 karakterdir.

Dismiss:

POST /api/v1/moderation/reports/{reportId}/dismiss

Canonical request:

optional note

Dismiss bir ModerationAction enum değeri değildir; ayrı endpoint davranışıdır.

Tüm /api/v1/moderation/** yüzeyleri geçerli Bearer token yanında Moderator rolü gerektirir.

User flows

Kullanıcı engelleme

Başka kullanıcı profili → güvenlik menüsü → “Kullanıcıyı Engelle”.

Kendi profilinde block aksiyonu gösterilmez.

Kullanıcı “Kullanıcıyı Engelle” seçtiğinde confirmation dialog açılır.

“İptal”:

Dialog kapanır.

Profil state'i değişmez.

Mutation gönderilmez.

“Engelle”:

POST /api/v1/profiles/{profile.username}/block.

Request body gönderilmez.

Mutation sırasında confirmation CTA tekrar tetiklenemez.

Başarı response'undaki username ve isBlocked canonical kaynak kabul edilir.

Başarı mesajı: “Kullanıcı engellendi.”

Backend block semantiği nedeniyle eski follow ilişkileri geri getirilebilir state olarak tutulmaz.

Profil/feed/list görünürlüğü backend sonucuyla yeniden senkronize edilir.

Self-block 400 normal empty state değildir.

Hedef bulunamazsa veya görünmezse 404 canonical görünürlük semantiği uygulanır.

Engel kaldırma

Engelli kullanıcıya ait mevcut güvenlik yüzeyi veya Engellenen Hesaplar listesi → “Engeli Kaldır”.

DELETE /api/v1/profiles/{username}/block.

Mutation sırasında yalnız ilgili unblock aksiyonu loading/disabled olur.

Başarı 204 response body beklemeden tamamlanır.

Başarı mesajı: “Engel kaldırıldı.”

Unblock eski follow ilişkilerini UI'da geri oluşturmaz.

Gerekli read state backend'den invalidate/refetch edilir.

Engellenen hesaplar

Kendi hesap/profil güvenlik yüzeyi → “Engellenen Hesaplar”.

BlockedUsersPage açılır.

Sayfa GET /api/v1/blocks kullanır.

Liste yalnız oturum sahibinin engellediği hesapları render eder.

Her satır canonical:

displayName

username

avatarUrl

blockedAt

alanlarını kullanır.

Satırdaki primary yönetim aksiyonu “Engeli Kaldır”dır.

Engel kaldırma mutation'ı sırasında yalnız ilgili satır aksiyonu disabled/loading olur.

Başarıdan sonra satır canonical read state'ten kaldırılır veya liste refetch edilir.

Son satır kaldırılırsa ekran başarılı empty state'e geçer.

Engellenen hesap listesindeki kullanıcıya normal ProfilePage açılabileceği varsayılmaz; block görünürlük semantiği profile erişimini 404 yapabileceğinden satırın zorunlu navigasyonu unblock yönetimidir.

Gönderi şikâyeti

Başkasının gönderisi → overflow → “Şikâyet Et”.

Kullanıcının kendi postunda report aksiyonu gösterilmez.

Report sheet:

targetType=Post

targetId=post.id

ile açılır.

Kullanıcı canonical reason seçer.

İsteğe bağlı details girebilir.

Reason seçilmeden submit aktif olmaz.

Submit:

POST /api/v1/reports

Başarı:

201 Created

report response canonical kaynak kabul edilir.

Başarı mesajı: “Şikâyetiniz alındı.”

Report oluşturulması hedef gönderiyi UI'da otomatik olarak silmez veya moderation-removed kabul etmez.

Kullanıcı şikâyeti

Başka kullanıcı profili → güvenlik menüsü → “Şikâyet Et”.

Kendi profilinde report aksiyonu gösterilmez.

Report sheet:

targetType=User

targetId=profile.id

ile açılır.

Reason/details davranışı gönderi şikâyetiyle aynı component'i reuse eder.

Başarı mesajı: “Şikâyetiniz alındı.”

Duplicate pending report

Aynı reporter-target için mevcut Pending report nedeniyle backend 409 döndürürse:

Sheet taslağı korunur.

Yeni başarılı report state'i üretilmez.

Hedef otomatik gizlenmez.

Kullanıcıya “Bu içerik veya hesap için bekleyen bir şikâyetin zaten var.” açıklaması gösterilir.

Kullanıcı sheet'i kapatabilir.

Moderasyon kuyruğu

Moderator → Moderasyon.

Default görünüm Pending kuyruktur.

Default Pending görünümü için status query göndermek zorunlu değildir; backend query yokluğunda Pending kullanır.

Kullanıcı canonical status görünümü seçerse yalnız aşağıdaki mapping kullanılır:

Pending → status=Pending

Resolved → status=Resolved

Dismissed → status=Dismissed

Başka status, casing veya alias üretilmez.

Status değiştiğinde eski isteğin geciken cevabı yeni status sonucunu overwrite etmez.

Liste öğesi yalnız canonical moderation response alanlarını gösterir:

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

API response hedef post content veya hedef kullanıcı profile summary vermediği için queue kartında bu bilgiler uydurulmaz.

Kart tap → ModerationDetailPage(report.id).

Moderasyon detayı

Detay:

GET /api/v1/moderation/reports/{reportId}

Ekranda canonical report metadata gösterilir.

status=Pending ise moderation controls gösterilir.

status=Resolved veya status=Dismissed ise aynı transition aksiyonları tekrar gösterilmez.

Pending Post report:

“İşlem Yapma” → resolve NoAction

“Gönderiyi Kaldır” → resolve RemovePost

“Şikâyeti Reddet” → dismiss

Pending User report:

“İşlem Yapma” → resolve NoAction

“Şikâyeti Reddet” → dismiss

RemovePost gösterilmez.

Canonical kontratta kullanıcı hesabını kaldıran/suspend eden ModerationAction olmadığı için User report üzerinde böyle bir aksiyon üretilmez.

Resolve: NoAction

Moderator “İşlem Yapma” seçer.

Optional note girilebilir.

POST /api/v1/moderation/reports/{reportId}/resolve

Request:

{
  "action": "NoAction",
  "note": null
}

Note varsa canonical note alanına gönderilir.

Başarı response:

status=Resolved

action=NoAction

resolved metadata

canonical kaynak kabul edilir.

Resolve: RemovePost

Yalnız targetType=Post ve status=Pending durumunda gösterilir.

Destructive confirmation olmadan mutation gönderilmez.

POST /api/v1/moderation/reports/{reportId}/resolve

Request:

{
  "action": "RemovePost",
  "note": null
}

Başarılı RemovePost sonrasında UI standart owner delete endpoint'ine ikinci istek göndermez.

Hedef postun feed/profile/like/reply görünürlüğü server-side moderasyon semantiğine bırakılır.

Dismiss

Pending report → “Şikâyeti Reddet”.

Optional note girilebilir.

POST /api/v1/moderation/reports/{reportId}/dismiss

Request:

{
  "note": null
}

Dismiss request'inde action alanı gönderilmez.

Başarı response status=Dismissed olarak render edilir.

Dismiss hedef kaynağı client-side kaldırmaz.

Components

Engellenen kullanıcı liste satırı

Token: {components.social-graph-list-item}, {components.relationship-button}

Widget hierarchy:

BlockedUserListItem
└── ConstrainedBox(minHeight: 72)
    └── Padding
        └── Row
            ├── CircleAvatar
            ├── Expanded
            │   └── Column(crossAxis: start)
            │       ├── Text(displayName)
            │       ├── Text("@username")
            │       └── Text(blockedAt)
            └── OutlinedButton("Engeli Kaldır")

Kurallar:

Mevcut kullanıcı liste satırı görsel pattern'i reuse edilir.

Row içindeki kullanıcı verisi yalnız GET /api/v1/blocks response'undan gelir.

blockedAt metadata olarak ikincil tipografide gösterilir.

Unblock butonu minimum 44x44px dokunma alanına sahiptir.

Mutation sırasında tüm liste loading'e dönmez.

Şikâyet bottom sheet

Token: {components.report-sheet}, {components.input}, {components.primary-button}

Widget hierarchy:

showModalBottomSheet
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
            │   ├── canonical field: details
            │   ├── multiline
            │   └── maxLength: 500
            └── FilledButton("Şikâyet Et")

Kurallar:

UI etiketleri kullanıcı dilinde açıklanabilir fakat serializer canonical enum string'ini değiştirmez.

Post ve User report aynı component'i kullanır.

Target type sheet tarafından tahmin edilmez; çağıran yüzey canonical target context'i verir.

targetId integer id'dir.

Reason seçimi zorunludur.

Details isteğe bağlıdır.

Loading sırasında submit tekrar tetiklenemez.

Network/5xx, validation veya 409 durumunda reason/details taslağı korunur.

Engelleme confirmation dialog

Token: {components.safety-action-menu}, {colors.error}

Widget hierarchy:

AlertDialog
├── title: Text("Kullanıcı engellensin mi?")
├── content: Text(
│       "Bu kullanıcıyla olan takip ilişkileri kaldırılır ve içerikleri görünürlük kurallarına göre sınırlandırılır."
│   )
└── actions
    ├── TextButton("İptal")
    └── FilledButton("Engelle")

Kurallar:

Engelleme confirmation olmadan başlamaz.

UI unblock işleminin eski follow ilişkilerini geri getireceğini söylemez.

Moderasyon status seçimi

Token: {typography.label-md}, {colors.primary-container}

Widget hierarchy:

ModerationStatusControl
└── SegmentedButton | single-select FilterChip group
    ├── Text("Bekleyen")
    ├── Text("Sonuçlandırılan")
    └── Text("Reddedilen")

Canonical mapping:

Bekleyen → Pending

Sonuçlandırılan → Resolved

Reddedilen → Dismissed

Kurallar:

Görsel label enum serializer değildir.

Seçim minimum 44x44px dokunma alanına sahiptir.

Stale response aktif filtre sonucunu overwrite etmez.

Moderasyon kuyruğu kartı

Token: {components.moderation-card}

Widget hierarchy:

Card
└── InkWell
    └── Padding
        └── Column(crossAxis: start)
            ├── Row
            │   ├── Text("#reportId")
            │   └── status badge
            ├── Text(targetType + " #" + targetId)
            ├── Text(reason)
            ├── optional Text(details)
            ├── Text(createdAt)
            └── optional resolved metadata

Kurallar:

Target summary yalnız canonical targetType ve targetId üzerinden oluşturulur.

Post body, user display name veya başka hedef metadata API response'ta yoksa render edilmez.

Status badge yalnız Pending, Resolved, Dismissed canonical değerlerinden map edilir.

Moderasyon detay aksiyon alanı

Token: {components.moderation-card}, {components.primary-button}, {colors.error}

Widget hierarchy:

ModerationActionArea
└── status == Pending ise Column
    ├── TextFormField
    │   ├── label: "Moderatör notu (isteğe bağlı)"
    │   ├── multiline
    │   └── maxLength: 500
    ├── OutlinedButton("İşlem Yapma")
    ├── targetType == Post ise FilledButton("Gönderiyi Kaldır")
    └── TextButton("Şikâyeti Reddet")

Kurallar:

Tek mutation sürerken tüm moderation transition CTA'ları disabled olur.

RemovePost User report'ta render edilmez.

Note 500 karakteri aşamaz.

Pending olmayan report için transition CTA gösterilmez.

Screen states

Engellenen Hesaplar

Loading:

AppBar görünür kalır.

Liste alanında mevcut skeleton/list loading pattern'i kullanılır.

Empty:

Başlık: “Engellediğin hesap yok”

Açıklama: “Engellediğin hesaplar burada görünür.”

CTA yoktur.

Yalnız 200 + boş items response empty state'tir.

Error:

Başlık: “Engellenen hesaplar yüklenemedi”

Açıklama: “Liste alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

401 merkezi login akışına gider.

Network/5xx empty state değildir.

Unblock success:

“Engel kaldırıldı.”

Şikâyet Formu

Initial:

Reason seçilmemiş başlangıç hali API empty state değildir.

Submit disabled'dır.

Validation:

Reason zorunludur.

Details 500 karakteri aşamaz.

400 field error ilgili input/reason alanına bağlanır.

409:

Başlık: “Şikâyet zaten beklemede”

Açıklama: “Bu içerik veya hesap için bekleyen bir şikâyetin zaten var.”

Taslak korunur.

404:

“Hedef artık kullanılamıyor.”

Şikâyetin başarıyla oluşturulduğu varsayılmaz.

401:

Merkezi login akışına gider.

Network/5xx:

“Şikâyet gönderilemedi. Tekrar deneyin.”

Reason ve details korunur.

Success:

“Şikâyetiniz alındı.”

Moderasyon Kuyruğu

Loading:

Status seçimi görünür kalır.

Aktif filtre anlaşılır kalır.

Empty:

Pending:

Başlık: “Bekleyen şikâyet yok”

Açıklama: “İncelenecek yeni şikâyet bulunmuyor.”

Resolved:

Başlık: “Sonuçlandırılmış şikâyet yok”

Dismissed:

Başlık: “Reddedilmiş şikâyet yok”

Empty state yalnız başarılı items=[] response için gösterilir.

Error:

Başlık: “Moderasyon kuyruğu yüklenemedi”

Açıklama: “Şikâyetler alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

401 merkezi login akışına gider.

403:

Empty state değildir.

Yetkisiz kullanıcının moderation destination'ı normalde render edilmez.

Role state stale/yanlış olduğu için endpoint 403 dönerse moderation içeriği gösterilmez ve yetki hatası olarak ele alınır.

Moderasyon Detayı

Loading:

Report id route bağlamı korunur.

Error 404:

Başlık: “Şikâyet bulunamadı”

Sahte detail state gösterilmez.

Error 401:

Merkezi login akışına gider.

Error 403:

Yetki hatasıdır; empty state değildir.

Mutation 400:

Canonical validation/action hatası gösterilir.

Özellikle RemovePost User target için local fallback aksiyonuna çevrilmez.

Mutation 409:

Başlık: “Şikâyet zaten sonuçlandırılmış”

Açıklama: “Güncel durumu görmek için şikâyeti yeniden yükle.”

CTA: “Yeniden Yükle”

Local Pending state kalıcı kaynak kabul edilmez.

Mutation network/5xx:

Note korunur.

Report detail kaybolmaz.

CTA yeniden kullanılabilir hale gelir.

Resolve success:

Backend response'taki Resolved state render edilir.

Kuyruk ilgili status read state'leri invalidate/refetch edilir.

Dismiss success:

Backend response'taki Dismissed state render edilir.

Kuyruk ilgili status read state'leri invalidate/refetch edilir.

Navigation

Başka kullanıcı profili → güvenlik menüsü → Engelle / Engel Kaldır / Şikâyet Et.

Başkasının gönderisi → overflow → Şikâyet Et.

Kendi hesap/profil güvenlik yüzeyi → Engellenen Hesaplar.

Engellenen Hesaplar → ilgili satır → Engeli Kaldır.

Moderator-only drawer/sidebar destination → Moderasyon Kuyruğu.

Moderasyon Kuyruğu → kart → Moderasyon Detayı.

Moderasyon status seçimi aynı Moderasyon route bağlamında kalır; yeni global destination oluşturmaz.

Resolve veya dismiss mutation route'u değiştirmek zorunda değildir; başarılı canonical state detail içinde gösterilebilir.

Back navigation önceki moderation filter seçimini ve mümkünse scroll konumunu korur.

Contract boundaries

Bu feature canonical API'de bulunmayan davranışları tasarım gereksinimi olarak tanımlamaz.

Özellikle:

Mute endpoint'i Priority 3 güvenlik davranışı olarak varsayılmaz.

Kullanıcı suspend/ban moderation action'ı üretilmez.

User report üzerinde RemovePost gösterilmez.

Dismiss isminde ModerationAction enum değeri oluşturulmaz.

Moderasyon hedef postunu almak için kontratta olmayan GET /api/v1/posts/{postId} endpoint'i üretilmez.

Moderasyon hedef kullanıcı detayını almak için kontratta olmayan alternatif admin/profile endpoint'i üretilmez.

Block nedeniyle görünmeyen 404 response'un gerçek missing mi block mu olduğu tahmin edilmez.

GET /api/v1/blocks boş sonucu 404 olarak yorumlanmaz.

GET /api/v1/moderation/reports boş sonucu 404 olarak yorumlanmaz.

Standart DELETE /api/v1/posts/{postId} moderasyon RemovePost yerine kullanılmaz.

Report oluşturulması otomatik moderation kararı gibi gösterilmez.

Unblock işlemi eski follow ilişkilerini geri getirmez.

Do's and Don'ts

Do

Canonical Post ve User target type değerlerini birebir serialize et.

Canonical report reason değerlerini tek serializer üzerinden birebir kullan.

Report için targetType, targetId, reason, details alanlarını kullan.

Post report target id için post.id kullan.

User report target id için profile.id kullan.

Engellemede path için profile.username kullan.

Engellenen hesaplar için GET /api/v1/blocks kullan.

Unblock başarı 204 olduğunda response body bekleme.

Moderasyon status filtresinde yalnız Pending, Resolved, Dismissed değerlerini kullan.

Default moderation kuyruğunun Pending olduğunu koru.

Resolve için yalnız NoAction ve uygun Post hedefinde RemovePost kullan.

Dismiss için ayrı dismiss endpoint'ini kullan.

Moderation note ve report details alanlarında 500 karakter sınırını koru.

401'i merkezi login akışına gönder.

403 moderation permission hatasını empty state yapma.

409 transition/report conflict durumlarında mevcut local state'i canonical başarı gibi değiştirme.

Minimum 44x44px dokunma alanını koru.

Dynamic text scaling'i destekle.

Don't

Report request'inde postId, userId, reportType, categoryCode veya targetIdentifier üretme.

Enum değerlerini lowercase veya camelCase alias ile serialize etme.

Self-report veya self-block aksiyonunu kendi profil/post yüzeyinde gösterme.

Block sonrası follow state'i local olarak geri yükleme.

Unblock sonrası eski follow ilişkisini geri oluşturma.

Duplicate pending report 409 sonucunu success olarak gösterme.

Moderasyon response'unda olmayan target content veya user metadata uydurma.

User report için “Gönderiyi Kaldır” aksiyonu gösterme.

Canonical contract'ta olmayan user ban/suspend/delete moderation aksiyonu üretme.

Dismiss'i ModerationAction enum değeri kabul etme.

Resolve request body içine reportId ekleme.

Dismiss request body içine reportId veya action ekleme.

Moderasyon kaldırması için normal owner post delete endpoint'ini çağırma.

403'ü boş moderasyon kuyruğu gibi gösterme.

404 block semantiğini client-side açıklamaya çalışma.

Yeni role, permission, report status veya moderation action üretme.