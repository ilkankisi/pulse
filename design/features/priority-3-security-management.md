Feature: Öncelik 3 güvenlik ve yönetim deneyimi

Scope

Bu feature güvenlik ve yetkili moderasyon deneyimini kapsar:

Başka kullanıcıyı engelleme.

Engeli kaldırma.

Engellenen hesapları görüntüleme ve listeden engeli kaldırma.

Başkasının gönderisini şikâyet etme.

Başka kullanıcı hesabını şikâyet etme.

Canonical report reason seçimi ve isteğe bağlı açıklama.

Moderator rolünde şikâyet kuyruğunu görüntüleme.

Pending, Resolved ve Dismissed durumları arasında canonical filtreleme.

Şikâyet detayını görüntüleme.

Pending şikâyeti canonical resolve aksiyonuyla sonuçlandırma.

Pending şikâyeti ayrı dismiss akışıyla kapatma.

Loading, empty, error, conflict ve success durumlarını ayrı ele alma.

UI canonical API sözleşmesinde bulunmayan endpoint, enum, role, request alanı veya response alanı üretmez.

404 cevabından kullanıcının engellenmiş olduğu sonucu çıkarılmaz.

Moderator olmayan kullanıcıya moderasyon navigation veya mutation aksiyonu gösterilmez.

Standart kullanıcı post silme davranışı moderasyon kaldırma aksiyonu yerine kullanılmaz.

Components

Profil güvenlik menüsü

Token: {components.security-overflow-menu}

Widget hierarchy:

PopupMenuButton
└── items
    ├── PopupMenuItem
    │   └── Text("Kullanıcıyı Engelle" | "Engeli Kaldır")
    └── PopupMenuItem
        └── Text("Şikâyet Et")

fluttertemplates: Popup Menu — /widgets/overlays

Kurallar:

Kendi profilinde block/report aksiyonları gösterilmez.

Engelleme state'i yalnız canonical relationship/block bilgisinden gelir.

Block seçildiğinde confirmation dialog açılır.

Mutation sırasında ilgili aksiyon tekrar tetiklenemez.

Engelleme onay dialogu

Token: {components.destructive-confirm-dialog}

Widget hierarchy:

AlertDialog
├── title: Text("Kullanıcıyı engelle?")
├── content: Text
└── actions
    ├── TextButton("İptal")
    └── FilledButton("Engelle")

fluttertemplates: Dialogs — /widgets/overlays

Kurallar:

“İptal” hiçbir mutation üretmez.

“Engelle” canonical block mutation'ını tetikler.

Loading sırasında destructive CTA disabled olur.

Başarı snackbar: "Kullanıcı engellendi."

Engellenen hesaplar listesi

Token: {components.blocked-users-list}

Widget hierarchy:

Scaffold
├── AppBar
│   └── Text("Engellenen Hesaplar")
└── body
    └── state
        ├── loading: ListView
        │   └── shimmer row*
        ├── success: ListView
        │   └── Card
        │       └── ListTile
        │           ├── leading: CircleAvatar
        │           ├── title: Text(displayName)
        │           ├── subtitle: Column
        │           │   ├── Text("@username")
        │           │   └── Text(blockedAt)
        │           └── trailing: TextButton("Engeli Kaldır")
        ├── empty: EmptyState
        └── error: ErrorState
            └── FilledButton("Yeniden Dene")

fluttertemplates: List Item / Settings — /widgets/layouts, /widgets/profile

Kurallar:

Liste yalnız canonical blocked-users response alanlarını kullanır.

Satıra follow CTA eklenmez.

Unblock sırasında yalnız ilgili satır loading/disabled olur.

Son kayıt kaldırılırsa successful empty state'e geçilir.

Başarı snackbar: "Engel kaldırıldı."

Şikâyet formu

Token: {components.report-sheet}

Widget hierarchy:

ModalBottomSheet
└── SafeArea
    └── Form
        └── Column
            ├── Text("Şikâyet Et")
            ├── RadioListTile | DropdownButtonFormField
            │   └── canonical reason options
            ├── TextFormField
            │   ├── labelText: "Açıklama"
            │   └── maxLength: 500
            └── FilledButton("Şikâyeti Gönder")

fluttertemplates: Bottom Sheets + Form — /widgets/overlays, /widgets/forms

Kurallar:

Reason seçilmeden submit aktif olmaz.

Gönderi şikâyeti canonical post target id kullanır.

Kullanıcı şikâyeti canonical user target id kullanır.

username, postId, userId, reportType gibi sözleşmede olmayan alternatif request alanları üretilmez.

Network/5xx hatasında form içeriği korunur.

Başarı snackbar: "Şikâyetiniz alındı"

Duplicate pending conflict başarılı submission gibi gösterilmez.

Moderasyon kuyruğu

Token: {components.moderation-queue}

Widget hierarchy:

Scaffold
├── AppBar
│   └── Text("Moderasyon")
└── body
    └── Column
        ├── SegmentedButton | TabBar
        │   ├── Text("Bekleyen")
        │   ├── Text("Çözümlenen")
        │   └── Text("Kapatılan")
        └── Expanded
            └── state
                ├── loading: ListView
                │   └── shimmer card*
                ├── success: ListView
                │   └── ReportCard*
                │       ├── report summary
                │       ├── status
                │       └── chevron
                ├── empty: EmptyState
                └── error: ErrorState
                    └── FilledButton("Yeniden Dene")

fluttertemplates: Dashboard / Tabbed Content — /widgets/dashboard, /widgets/layouts

Kurallar:

Yalnız Moderator rolüne gösterilir.

Filtre yalnız canonical report status değerlerine map edilir.

Filtre değişiminde eski listenin stale sonucu yeni filtre altında gösterilmez.

Retry mevcut filtreyi korur.

Moderasyon detay ve aksiyonları

Token: {components.moderation-detail}

Widget hierarchy:

Scaffold
├── AppBar
│   └── Text("Şikâyet Detayı")
└── body
    └── state
        ├── loading: detail skeleton
        ├── success: SingleChildScrollView
        │   └── Column
        │       ├── report metadata card
        │       ├── reason/details card
        │       ├── TextFormField
        │       │   ├── labelText: "Not"
        │       │   └── maxLength: 500
        │       └── action region
        │           ├── FilledButton("Çözümle")
        │           └── OutlinedButton("Kapat")
        └── error: ErrorState
            └── FilledButton("Yeniden Dene")

fluttertemplates: Detail + Edit Form — /widgets/admin

Kurallar:

Resolve yalnız canonical moderation action seçeneklerini kullanır.

Dismiss ayrı mutation davranışıdır; moderation action enum değeri gibi modellenmez.

Pending olmayan report için geçersiz aksiyon gösterilmez.

Mutation sırasında yalnız aksiyon alanı disabled/loading olur.

Başarı sonrası detay ve kuyruk state'i backend sonucuyla invalidate/refetch edilir.

Screen states

Engellenen Hesaplar

Empty state:

title: "Engellediğin hesap yok"

description: "Engellediğin hesaplar burada görünecek."

primaryCta: yok

Error state:

title: "Engellenen hesaplar yüklenemedi"

description: "Bağlantını kontrol edip yeniden deneyebilirsin."

primaryCta: "Yeniden Dene"

Success:

unblockSnackbar: "Engel kaldırıldı."

Şikâyet formu

Success:

snackbar: "Şikâyetiniz alındı"

Conflict:

description: "Bu içerik veya hesap için zaten bekleyen bir şikâyetin var."

form state korunur.

Error:

description: "Şikâyet gönderilemedi. Tekrar deneyin."

reason ve details korunur.

Moderasyon kuyruğu

Empty state:

title: "Bu durumda şikâyet yok"

description: "Seçili filtreye ait şikâyet bulunmuyor."

primaryCta: yok

Error state:

title: "Moderasyon kuyruğu yüklenemedi"

description: "Bağlantını kontrol edip yeniden deneyebilirsin."

primaryCta: "Yeniden Dene"

401:

merkezi session/login akışı.

403:

normal empty state değildir.

moderator yüzeyi gösterilmez veya yetkisiz erişim durumu gösterilir.

Moderasyon mutation

Success:

resolveSnackbar: "Şikâyet çözümlendi."

dismissSnackbar: "Şikâyet kapatıldı."

Error:

snackbar: "İşlem tamamlanamadı. Tekrar deneyin."

önceki doğrulanmış report state korunur.

Navigation

Başka kullanıcı profili → overflow → Engelle / Engeli Kaldır / Şikâyet Et.

Hesap/Güvenlik → Engellenen Hesaplar.

Başkasının gönderisi → overflow → Şikâyet Et.

Moderator navigation → Moderasyon.

Moderasyon kuyruğu → report satırı → Şikâyet Detayı.

Resolve/dismiss sonrasında route zorunlu olarak değişmez; detay ve kuyruk state'i yenilenir.

Do's and Don'ts

Do:

Canonical enum ve request alanlarını birebir kullan.

Empty, error, conflict ve unauthorized durumlarını ayır.

Destructive mutation'larda confirmation veya açık aksiyon sınırı kullan.

Moderator görünürlüğünü role göre sınırla.

Mutation sonrasında backend state'ini doğruluk kaynağı kabul et.

Don't:

404 sonucundan block nedeni çıkarma.

Moderator olmayan kullanıcıya moderation action gösterme.

Standart post delete endpoint'ini moderation remove davranışı olarak kullanma.

Client-side optimistic state'i kalıcı doğruluk kaynağı yapma.

Contract'ta olmayan reason/status/action değeri üretme.