Feature: Engelleme ve şikâyet

Scope

Güvenlik menüsü, şikâyet sheet, engelleme dialogu ve engellenen hesap yönetimi.

Components

Güvenlik aksiyon menüsü

Token: {components.safety-action-menu}

Widget hierarchy:

PopupMenuButton | MenuAnchor
└── menuChildren
    ├── gönderi:
    │   └── MenuItemButton
    │       ├── Icon(flag_outlined)
    │       └── Text("Şikâyet Et")
    └── başka kullanıcı profili:
        ├── MenuItemButton
        │   ├── Icon(flag_outlined)
        │   └── Text("Şikâyet Et")
        └── MenuItemButton
            ├── Icon(block)
            └── Text("Kullanıcıyı Engelle" | "Engeli Kaldır")

fluttertemplates kaynağı: Dialogs & Sheets / Menus — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Minimum dokunma alanı 44x44px'tir.

Kullanıcı kendi hesabını engelleyemez.

Kullanıcı kendi hesabı veya kendi gönderisi için şikâyet aksiyonu görmez.

Engelleme destructive/security aksiyonudur.

UI block/report endpoint veya enum üretmez.

Report target yalnız canonical Post veya User değerine map edilir.

Report reason yalnız canonical Spam, Harassment, HateSpeech, Violence, SexualContent, Impersonation veya Other değerlerinden biridir.

Şikâyet bottom sheet

Token: {components.report-sheet}, {components.input}, {components.primary-button}

Widget hierarchy:

showModalBottomSheet
└── SafeArea
    └── Padding
        └── Form
            └── Column(mainAxisSize: min)
                ├── drag handle
                ├── Text("Şikâyet Et")
                ├── Text("Neden şikâyet ediyorsun?")
                ├── RadioGroup | RadioListTile[]
                │   └── canonical report reason seçenekleri
                ├── TextFormField
                │   ├── label: "Açıklama (isteğe bağlı)"
                │   ├── multiline
                │   └── maxLength: 500
                └── FilledButton("Şikâyet Et")

fluttertemplates kaynağı: Dialogs & Sheets / Modal Bottom Sheet — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Gönderi ve kullanıcı şikâyeti aynı component'i kullanır.

Reason canonical API kontratından map edilir.

Reason seçilmeden submit aktif olmaz.

Açıklama en fazla 500 karakterdir.

Ağ hatasında reason ve açıklama korunur.

400 validation hatasında sheet açık kalır ve backend field bilgisi ilgili input'a map edilir.

404 hedefin artık bulunamadığı veya görünmediği durumdur; UI block sebebini tahmin etmez.

409 duplicate pending report başarı gibi gösterilmez.

Başarı snackbar'ı: “Şikâyetiniz alındı”.

Engelleme onay dialogu

Token: {components.safety-action-menu}, {colors.error}

Widget hierarchy:

showDialog
└── AlertDialog
    ├── title: Text("Kullanıcı engellensin mi?")
    ├── content: Text(
    │       "Bu kullanıcının içerik ve etkileşimleri bloklama kurallarına göre sınırlandırılacak."
    │   )
    └── actions
        ├── TextButton("İptal")
        └── FilledButton("Engelle")

fluttertemplates kaynağı: Dialogs & Sheets / Alert Dialog — https://fluttertemplates.dev/widgets/dialogs

Kurallar:

Engelleme confirmation olmadan başlamaz.

Loading sırasında CTA tekrar tetiklenemez.

Başarı: “Kullanıcı engellendi.”

Engeli kaldırma: “Engel kaldırıldı.”

Backend görünürlük kuralları UI'da yeniden tanımlanmaz.

Block sonrasında backend tarafından kaldırılan follow ilişkileri local state ile geri üretilmez.

Unblock eski follow ilişkilerini otomatik geri getirmez.

Engellenen kullanıcılar listesi

Token: {components.social-graph-list-item}, {components.state-panel}

Widget hierarchy:

BlockedUsersPage
└── Scaffold
    ├── AppBar
    │   └── Text("Engellenen Hesaplar")
    └── SafeArea
        └── blocked users state
            ├── loading
            ├── empty
            ├── error
            └── CustomScrollView
                └── SliverList
                    └── Padding
                        └── Row
                            ├── CircleAvatar
                            ├── Expanded
                            │   └── Column(crossAxis: start)
                            │       ├── Text(displayName)
                            │       └── Text("@username")
                            └── OutlinedButton("Engeli Kaldır")

Kurallar:

Veri yalnız GET /api/v1/blocks response'undan gelir.

Liste canonical id, username, displayName, avatarUrl ve blockedAt alanlarını kullanır.

UI ek filter, sort, cursor veya pagination parametresi üretmez.

“Engeli Kaldır” canonical DELETE /api/v1/profiles/{username}/block işlemine map edilir.

Mutation sırasında yalnız ilgili satır CTA'sı loading/disabled olur.

204 başarıdan sonra ilgili satır listeden kaldırılır.

Unblock eski follow ilişkisini geri getirmez.

Minimum dokunma alanı 44x44px korunur.

Screen states

Şikâyet Formu

Empty state

Reason seçilmemiş başlangıç hali API empty state değildir.

Error state

"Şikâyet gönderilemedi. Tekrar deneyin."

400 canonical validation mesajı ilgili alanda gösterilir.

404 hedefin artık kullanılamadığı belirtilir; block ilişkisi ifşa edilmez.

409: "Bu içerik veya hesap için zaten bekleyen bir şikâyetin var."

401 login akışına gider.

Taslak korunur.

Success

"Şikâyetiniz alındı"

App bar vs body CTA

CTA bottom sheet içinde "Şikâyet Et".

Kullanıcı Engelleme

Empty state

Uygulanmaz.

Error state

Ağ hatasında profil korunur.

401 login akışına gider.

Success

"Kullanıcı engellendi."

"Engel kaldırıldı."

App bar vs body CTA

Güvenlik menüsünden başlatılır.

Engellenen Hesaplar

Loading state

Liste yüklenirken sayfa bağlamı korunur.

Empty state

Başlık: "Engellenen hesap yok"

Açıklama: "Engellediğin hesaplar burada görünür."

CTA yoktur.

Error state

Başlık: "Engellenen hesaplar yüklenemedi"

Açıklama: "Liste alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

401 login akışına gider.

Success

Canonical items listesi render edilir.

Unblock başarıyla tamamlandığında ilgili satır kaldırılır.

App bar vs body CTA

Sayfa seviyesinde destructive CTA yoktur.

“Engeli Kaldır” yalnız ilgili liste satırındadır.

Navigation

Gönderi overflow veya profil güvenlik menüsünden.

Profil / hesap güvenliği → "Engellenen Hesaplar" → BlockedUsersPage.

BlockedUsersPage global NavigationBar veya NavigationDrawer destination değildir.