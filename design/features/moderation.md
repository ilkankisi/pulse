Feature: Moderasyon kuyruğu

Scope

Moderator-only şikâyet kuyruğu, detay inceleme ve canonical karar aksiyonları.

Components

Moderasyon kuyruğu kartı

Token: {components.moderation-card}

Widget hierarchy:

CustomScrollView
└── SliverList
    └── Card
        └── Padding
            └── Column(crossAxis: start)
                ├── Row
                │   ├── target summary
                │   └── status badge
                ├── Text(report reason)
                ├── Text(report description, optional)
                ├── Text(metadata)
                └── action area
                    └── canonical moderator actions

fluttertemplates kaynağı: Core / Cards — https://fluttertemplates.dev/widgets

Kurallar:

Yalnız moderator kullanıcıya gösterilir.

Status ve action değerleri docs/api-contract.md ile map edilir.

UI yeni role/status/action üretmez.

İşlenen kayıt backend sonucuna göre yenilenir veya listeden çıkarılır.

Kuyruk query verilmediğinde canonical Pending durumunu kullanır.

Durum filtresi sunulursa yalnız Pending, Resolved ve Dismissed değerleri kullanılır.

Liste satırı canonical report.id ile ModerationDetailPage açar.

Moderasyon detay ve karar yüzeyi

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
                    ├── report metadata
                    │   ├── targetType + targetId
                    │   ├── reporterUserId
                    │   ├── reason
                    │   ├── details, optional
                    │   ├── status
                    │   ├── createdAt
                    │   ├── resolvedAt, optional
                    │   └── resolvedByUserId, optional
                    └── status == Pending ise action area
                        ├── moderation action selector
                        │   ├── NoAction
                        │   └── targetType == Post ise RemovePost
                        ├── TextFormField
                        │   ├── label: "Moderatör notu (isteğe bağlı)"
                        │   ├── multiline
                        │   └── maxLength: 500
                        ├── FilledButton("Çözümle")
                        └── OutlinedButton("Reddet")

Kurallar:

Detay yalnız GET /api/v1/moderation/reports/{reportId} sonucundan render edilir.

Resolve yalnız POST /api/v1/moderation/reports/{reportId}/resolve işlemine map edilir.

Dismiss yalnız POST /api/v1/moderation/reports/{reportId}/dismiss işlemine map edilir.

Resolve action yalnız canonical NoAction veya RemovePost olabilir.

RemovePost yalnız targetType=Post için gösterilir.

User report için RemovePost gösterilmez veya request'e yazılmaz.

note en fazla 500 karakterdir.

Mutation sırasında resolve/dismiss CTA'ları tekrar tetiklenemez.

Resolved veya Dismissed kayıtta yeni karar CTA'sı gösterilmez.

Başarılı işlem sonrası status/action backend response'undan alınır.

Moderasyon kaldırması standart DELETE /api/v1/posts/{postId} endpoint'ine map edilmez.

Dismiss target kaynağını değiştirmez.

Screen states

Moderasyon Kuyruğu

Empty state

Başlık: "Bekleyen şikâyet yok"

Açıklama: "İncelenecek yeni şikâyet bulunmuyor."

CTA yoktur.

Error state

Başlık: "Moderasyon kuyruğu yüklenemedi"

Açıklama: "Şikâyetler alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

403 empty değildir.

401 login akışına gider.

Success

Backend'in güncel moderation sonucu render edilir.

App bar vs body CTA

Moderasyon aksiyonları ilgili kayıt body alanındadır.

Şikâyet Detayı

Loading state

Canonical report kaydı yüklenene kadar loading gösterilir.

Empty state

Tekil report detayında empty state kullanılmaz.

Error state

400 canonical action/note validation hatası form üzerinde gösterilir.

401 login akışına gider.

403 yetkisiz durumudur; empty state değildir ve moderation CTA'ları gösterilmez.

404:

Başlık: "Şikâyet bulunamadı"

Açıklama: "Bu şikâyet artık mevcut değil veya erişilemiyor."

409:

Başlık: "Şikâyet daha önce işlendi"

Açıklama: "Güncel durumu görmek için kaydı yenile."

CTA: "Yenile"

Success

Resolve sonucu Resolved, dismiss sonucu Dismissed olarak backend response'undan render edilir.

RemovePost sonucunda istemci post görünürlüğünü local olarak taklit etmez; sonraki canonical read sonucu kaynak kabul edilir.

App bar vs body CTA

Karar CTA'ları yalnız Pending kaydın body alanındadır.

Do's and Don'ts

Do

Material 3 semantik token'larını kullan.

Takipçiler ve Takip Edilenler için aynı SocialGraphListItem bileşenini kullan.

Profil sayaçlarını minimum 44x44px dokunma alanına sahip yap.

Kendi profilim ve başka profil için aynı Followers/Following ekranlarını yeniden kullan.

Followers route'una görüntülenen profilin username değerini geçir.

Following route'una görüntülenen profilin username değerini geçir.

Takipçiler için GET /api/v1/profiles/{username}/followers kullan.

Takip Edilenler için GET /api/v1/profiles/{username}/following kullan.

Liste satırından profile geçerken row.username kullan.

Profil A → sosyal graf → Profil B → Profil B sosyal graf zincirinde her route'un kendi username bağlamını koru.

Geri navigasyonda mümkünse sosyal graf scroll konumunu koru.

Follow/unfollow durumlarını backend ile senkronize et.

404 kayıt-yok durumunu empty state olarak ele al.

401'i login akışına gönder.

403'ü normal empty state gibi gösterme.

Moderator-only UI'ı role sonucuna göre gizle.

Pending kayıtta yalnız canonical moderation aksiyonlarını göster.

User report'unda RemovePost aksiyonunu gösterme.

Resolve/dismiss sonrasında backend response'unu kaynak kabul et.

409 durumunda kaydın güncel durumunu yeniden yükle.

Minimum dokunma alanını 44x44px koru.

Don'ts

Başka profilin “Takipçi” sayacına basınca current-user takipçilerini açma.

Başka profilin “Takip” sayacına basınca current-user takip listesini açma.

Profil A listesindeki Profil B satırından profile geçerken A'nın username'ini kullanma.

Followers ve Following ekranlarını ana NavigationBar/NavigationDrawer öğesi yapma.

API kontratında olmayan sosyal graf endpoint'i üretme.

API kontratında olmayan cursor, offset veya pagination query parametresi üretme.

Takipçi/takip sayaçlarını yalnız local optimistic değerle kalıcı kaynak kabul etme.

Kullanıcının kendi sosyal graf satırında “Takip Et” veya “Takibi Bırak” gösterme.

Followers ve Following için birbirinden farklı duplicate kullanıcı satırı tasarlama.

Sosyal graf satırına duplicate “Engelle” veya “Şikâyet Et” aksiyonu ekleme.

Kayıt yok durumunu "yüklenemedi" error state'e dönüştürme.

401'i normal retry paneli olarak gösterme.

Moderator olmayan kullanıcıya moderation action gösterme.

API kontratında olmayan role, status veya moderation action üretme.

User report için RemovePost request'i üretme.

Resolved veya Dismissed report üzerinde tekrar resolve/dismiss gösterme.

Moderasyon kaldırması için standart post DELETE endpoint'ini kullanma.

Çok seviyeli thread, DM veya kapsam dışı yeni özellik ekleme.

Navigation

Drawer Moderasyon destination (moderator rolü).

Moderasyon Kuyruğu → ModerationDetailPage(report.id).

Detay işlendiğinde geri dönülen kuyruk backend'in güncel sonucu ile yenilenir.