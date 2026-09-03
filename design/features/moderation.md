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

401'i login akışına gönder.

403'ü normal empty state gibi gösterme.

Moderator-only navigation ve aksiyonları yalnız doğrulanmış Moderator yetki durumunda göster.

403 alındığında moderation içeriğini veya karar CTA'larını göstermeye devam etme.

Pending kayıtta yalnız canonical moderation aksiyonlarını göster.

User report'unda RemovePost aksiyonunu gösterme.

Resolve/dismiss sonrasında backend response'unu kaynak kabul et.

409 durumunda kaydın güncel durumunu yeniden yükle.

Minimum dokunma alanını 44x44px koru.

Don'ts

401'i normal retry paneli olarak gösterme.

Moderator olmayan kullanıcıya moderation action gösterme.

API kontratında olmayan role, status veya moderation action üretme.

User report için RemovePost request'i üretme.

Resolved veya Dismissed report üzerinde tekrar resolve/dismiss gösterme.

Moderasyon kaldırması için standart post DELETE endpoint'ini kullanma.

403 sonucunu boş moderation kuyruğu gibi gösterme.

409 sonrasında eski Pending state'i yalnız local state ile koruma.

Resolve veya dismiss sonucunu yalnız optimistic state ile kalıcı kaynak kabul etme.

Çok seviyeli thread, DM veya kapsam dışı yeni özellik ekleme.

Navigation

Drawer Moderasyon destination (moderator rolü).

Moderasyon Kuyruğu → ModerationDetailPage(report.id).

Detay işlendiğinde geri dönülen kuyruk backend'in güncel sonucu ile yenilenir.