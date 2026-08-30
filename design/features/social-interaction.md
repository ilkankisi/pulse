# Feature: Sosyal Etkileşim Fazı

## Scope

Bu feature mevcut Pulse uygulamasına sosyal etkileşim davranışlarını ekler.

Korunan davranışlar:

- Mevcut Material 3 tasarım sistemi
- Mevcut root navigation
- Mevcut back-stack davranışı
- Profil
- Feed
- Composer
- Followers/Following
- Safety
- Moderation
- Mevcut FAB composer giriş noktası

Kapsam:

- Repost ve Quote
- Notifications
- Mention ve hashtag navigation
- Bookmark / Kaydedilenler
- En az tek görselli media composer
- Feed ve Post Detail media preview

Kapsam dışı:

- DM / özel mesaj
- Poll / anket
- Hashtag trendleri / trend keşif ekranı
- Algoritmik For You feed
- Çok seviyeli thread
- İkinci root navigation
- Public bookmark count

## Acceptance Checklist

- Feed ve Post Detail aynı `SocialPostCard` Post/Repost/Quote semantiğini ve hierarchy'sini kullanır.
- Repost aksiyonu `idle-not-reposted`, `loading-add`, `reposted`, `loading-remove`, `error` state'lerini tanımlar.
- Quote aksiyonu `idle`, `opening-composer`, `submitting`, `success`, `error` state'lerini tanımlar.
- Notifications; Like, Reply, Follow ve Mention event'lerini, read/unread davranışını ve loading/empty/error/success state'lerini tanımlar.
- `@username` → `ProfilePage(username)` ve `#tag` → `HashtagPostsPage(tag)` navigation davranışı açıktır.
- Bookmark save/remove state'leri tanımlıdır ve `BookmarksPage` mevcut Profil/Hesap alanından erişilebilirdir.
- Composer en az tek görsel için select, remove, upload/loading, upload error/retry ve submit-preservation davranışlarını tanımlar.
- Feed ve Post Detail için Post/Repost/Quote media preview hierarchy'si açıkça ayrılmıştır.
- `NotificationsPage`, `BookmarksPage`, `HashtagPostsPage` ve `QuoteComposer` mevcut UI içindeki somut giriş noktalarından açılır; orphan ekran oluşturulmaz.
- Mevcut root navigation, back-stack, Ana Akış, Profil, Followers/Following, Safety, Moderation ve FAB composer davranışları korunur.
- Yeni root destination ve ikinci root navigation oluşturulmaz.
- DM, poll, hashtag trends/trend keşfi ve algoritmik For You feed açıkça kapsam dışıdır.
- Modular compile başarısı aşağıdaki içerik acceptance kriterlerinin yerine geçmez.

## Acceptance Evidence

### Feed ve Post Detail repost / quote

Feed ve Post Detail aynı `SocialPostCard` Post/Repost/Quote semantiğini kullanır.

Normal Post:

```text
SocialPostCard
├── author header
├── RichPostText
├── PostMediaPreview
└── SocialActionBar

Repost:

SocialPostCard(kind: Repost)
├── repost context
├── repost actor metadata
├── OriginalPostCard
│   ├── original author
│   ├── RichPostText
│   └── original media
└── parent SocialActionBar

Repost kuralları:

Original içerik parent karta flatten edilmez.

Original içerik ile repost actor metadata birbirine karıştırılmaz.

OriginalPostCard ikinci bir SocialActionBar göstermez.

OriginalPostCard → PostDetail(originalPost.id).

Feed ve Post Detail aynı repost hierarchy'sini kullanır.

Quote:

SocialPostCard(kind: Quote)
├── quote author
├── quote RichPostText
├── quote media
├── OriginalPostCard
└── parent SocialActionBar

Quote kuralları:

Quote metni ile original içerik ayrı render edilir.

Quote media original media ile birleştirilmez.

Quote post'un aksiyonları parent SocialActionBar üzerinde kalır.

OriginalPostCard original gönderiye aittir.

Feed ve Post Detail aynı quote hierarchy'sini kullanır.

Post Detail:

PostDetail
├── author context
├── RichPostText
├── own PostMediaPreview
├── OriginalPostCard
├── SocialActionBar
└── replies

Post Detail kuralları:

Normal Post, Repost ve Quote ayrımı Feed ile aynıdır.

Replies, ana gönderinin SocialActionBar bileşeninden sonra render edilir.

Action loading ana post içeriğini gizlemez.

Action-level error tüm Post Detail ekranını error state'e dönüştürmez.

SocialActionBar

Aksiyon sırası:

Reply

Repost / Quote

Like

Bookmark

Repost state:

idle-not-reposted

loading-add

reposted

loading-remove

error

Quote state:

idle

opening-composer

submitting

success

error

Bookmark state:

idle-unselected

loading-add

selected

loading-remove

error

Kurallar:

Loading yalnız ilgili action üzerinde görünür.

Loading sırasında aynı mutation duplicate submit edilemez.

Mutation error mevcut başarılı kart içeriğini silmez.

Repost kaldırma başarısız olursa son başarılı reposted state korunur.

Quote submit başarısız olursa quote taslağı ve varsa media attachment state'i korunur.

Bookmark state canonical API sonucundan gelir.

Public bookmark count gösterilmez.

Notifications

Notification ekranı mevcut app shell notification girişinden açılır.

NotificationListItem
├── actor avatar
├── event summary
├── optional post preview
├── timestamp
└── unread indicator

Desteklenen türler:

Like

Reply

Follow

Mention

Read/unread:

Unread notification görünür unread indicator kullanır.

Read notification normal surface kullanır.

Unread item açıldığında yalnız ilgili notification read mutation state'ine geçer.

Read mutation sırasında tüm liste loading state'e dönmez.

Read mutation başarısız olursa mevcut liste korunur ve notification unread kalır.

Read mutation başarılı olduğunda unread indicator kaldırılır.

Notification target navigation:

Like → PostDetail(post.id)

Reply → PostDetail(post.id)

Mention → PostDetail(post.id)

Follow → ProfilePage(actor.username)

Screen states:

Loading:

Initial loading sırasında empty state gösterilmez.

Önceki kullanıcıya ait notification verisi gösterilmez.

Empty:

Başlık: "Henüz bildirim yok"

Error:

Başlık: "Bildirimler yüklenemedi"

CTA: "Tekrar Dene"

Success:

Like, Reply, Follow ve Mention event'leri gösterilir.

Read/unread state item seviyesinde görünür.

Ortak kurallar:

401 merkezi login/session akışına gider.

403 empty değildir.

Ağ/5xx empty değildir.

Mention ve hashtag navigation

RichPostText metin içindeki etkileşimli mention ve hashtag span'larını ayırır.

Kurallar:

@username → ProfilePage(username)

#tag → HashtagPostsPage(tag)

Yalnız geçerli ve tıklanabilir @username span'ı profile route üretir.

Düz metin içindeki bağımsız @ karakteri navigation üretmez.

Tıklanan hashtag değeri HashtagPostsPage(tag) route bağlamına taşınır.

Hashtag Posts yeni root destination değildir.

Hashtag Posts trend/trending ekranı değildir.

RichPostText navigation mevcut root navigation ve back-stack üzerinde çalışır.

Hashtag Posts screen states:

Loading:

Initial hashtag loading görünür.

Loading sırasında empty state gösterilmez.

Empty:

Başlık: "Bu etikette gönderi yok"

Error:

Başlık: "Gönderiler yüklenemedi"

CTA: "Tekrar Dene"

Success:

Sonuçlar SocialPostCard ile render edilir.

Kart → PostDetail(post.id).

Bookmark / Kaydedilenler

Bookmark SocialActionBar içinde save/remove olarak çalışır.

Save/remove davranışı:

Unselected → save.

Save sırasında state loading-add.

Save başarılı → selected.

Selected → remove.

Remove sırasında state loading-remove.

Remove başarılı → idle-unselected.

Save/remove mutation sırasında duplicate submit engellenir.

Save/remove başarısız olduğunda son başarılı bookmark state'i korunur.

Bookmark state canonical API sonucuyla senkronize edilir.

Public bookmark count gösterilmez.

Kaydedilenler mevcut Profil/Hesap alanından açılır.

BookmarksPage
└── state
    ├── loading
    ├── empty
    ├── error
    └── SocialPostCard[]

Kaydedilenler screen states:

Loading:

Skeleton/loading state kullanılır.

Initial loading sırasında empty gösterilmez.

Empty:

Başlık: "Henüz kaydedilen gönderi yok"

Error:

Başlık: "Kaydedilenler yüklenemedi"

CTA: "Tekrar Dene"

Success:

SocialPostCard kullanılır.

Kart → PostDetail(post.id).

Kaydedilenler içinden bookmark kaldırma başarılı olduğunda ilgili kart canonical backend sonucuna göre listeden kaldırılır veya liste yeniden senkronize edilir.

Navigation:

Kaydedilenler root destination değildir.

Profil/Hesap action → BookmarksPage.

Geri navigasyon kullanıcıyı kaynak Profil/Hesap bağlamına döndürür.

Composer media lifecycle

Composer:

Composer
├── text input
├── media preview
├── media picker
└── submit

Attachment state:

empty

selected

uploading

uploaded

uploadError

removing

State geçişleri:

empty → görsel seçimi → selected

selected → upload başlangıcı → uploading

uploading → başarılı upload → uploaded

uploading → upload hatası → uploadError

selected / uploaded / uploadError → remove → removing

removing → başarılı remove → empty

Kurallar:

En az tek görsel desteklenir.

Görsel seçildikten sonra local preview gösterilir.

Local preview API media kimliği değildir.

uploading sırasında progress/loading affordance görünür.

Aynı attachment upload sırasında tekrar upload edilemez.

Canonical media kimliği yalnız upload başarıyla uploaded state'ine geçtiğinde submit için kullanılabilir.

Upload tamamlanmadan media id kullanılmaz.

Upload error text taslağını silmez.

Upload error local preview'ı silmez.

uploadError durumunda retry veya remove yapılabilir.

Remove sırasında attachment üzerinde loading/removing affordance gösterilir.

Remove başarılı olduğunda attachment empty olur; text taslağı korunur.

Remove başarısız olduğunda mevcut attachment preview/state korunur ve item-level hata gösterilir.

selected, uploading, uploadError veya removing durumundaki media, tamamlanmış media submit'i olarak kabul edilmez.

Submit error text ve media state'ini korur.

Media mutation error tüm composer'ı sıfırlamaz.

Quote Composer:

QuoteComposer
├── text input
├── own media attachment
├── OriginalPostCard
└── submit

Quote Composer kuralları:

Original preview sabittir.

Quote content original content ile flatten edilmez.

Quote media lifecycle normal composer ile aynıdır.

Quote attachment quote post'a aittir.

Quote attachment original post media'sı ile birleştirilmez.

Quote submit error quote text ve media state'ini korur.

PostMediaPreview

Feed ve Post Detail aynı PostMediaPreview bileşen ailesini kullanır.

Hierarchy:

Normal Post:

RichPostText
→ PostMediaPreview
→ SocialActionBar

Repost:

repost context
→ OriginalPostCard
→ SocialActionBar

Quote:

quote RichPostText
→ quote PostMediaPreview
→ OriginalPostCard
→ SocialActionBar

Kurallar:

Aspect ratio korunur.

Tek görsel preview kartın mevcut içerik genişliğini aşmaz.

Normal Post media'sı post text'i ile SocialActionBar arasında kalır.

Repost'ta original media yalnız OriginalPostCard içinde gösterilir.

Quote'ta quote sahibinin media'sı OriginalPostCard öncesinde gösterilir.

Quote original media'sı yalnız OriginalPostCard içinde kalır.

Feed ve Post Detail aynı media hierarchy'sini kullanır.

Media loading post text'ini veya SocialActionBar'ı gizlemez.

Media preview hatası tüm Feed/Post Detail ekranını error state'e dönüştürmez.

Media preview hatası preview alanında item-level fallback/error olarak gösterilir.

Feed screen states

Loading:

Initial loading sırasında empty gösterilmez.

Success:

Normal Post, Repost ve Quote tanımlanan hierarchy ile render edilir.

Media içeren postlarda PostMediaPreview doğru seviyede render edilir.

Error:

Mutation hataları full-screen Feed error oluşturmaz.

Önceki başarılı kart state'i korunur.

Ağ/5xx initial load hatası empty state değildir.

Post Detail screen states

Loading:

Action loading ana postu gizlemez.

Media loading ana post metnini gizlemez.

Success:

Post/Repost/Quote hierarchy Feed ile aynıdır.

Replies SocialActionBar sonrasında kalır.

Error:

Action-level hata item seviyesinde kalır.

Media-level hata preview seviyesinde kalır.

Ana gönderi initial load ağ/5xx hatası empty state değildir.

Navigation korunumu ve orphan kontrolü

Yeni ekran ve akış giriş noktaları:

Notifications:

Mevcut app shell notification girişi → NotificationsPage.

Kaydedilenler:

Mevcut Profil/Hesap alanındaki action → BookmarksPage.

Hashtag Posts:

RichPostText içindeki #tag → HashtagPostsPage(tag).

Mention:

RichPostText içindeki @username → mevcut ProfilePage(username).

Quote Composer:

SocialActionBar → Repost → Alıntıla → QuoteComposer(originalPost).

Post Detail:

Post card → PostDetail(post.id).

OriginalPostCard → PostDetail(originalPost.id).

Like/Reply/Mention notification target → PostDetail(post.id).

Kaydedilenler kartı → PostDetail(post.id).

Hashtag Posts kartı → PostDetail(post.id).

Follow notification:

Follow notification target → ProfilePage(actor.username).

Orphan-screen kuralları:

NotificationsPage mevcut app shell girişinden erişilebilir.

BookmarksPage mevcut Profil/Hesap alanından erişilebilir.

HashtagPostsPage RichPostText hashtag aksiyonundan erişilebilir.

QuoteComposer SocialActionBar repost/quote akışından erişilebilir.

Yeni ekranların hiçbiri yalnız route tanımlı olup UI giriş noktası bulunmayan orphan ekran değildir.

Navigation korunumu:

Mevcut root navigation korunur.

Mevcut NavigationBar/NavigationDrawer destination yapısı korunur.

Yeni root destination oluşturulmaz.

İkinci root navigation oluşturulmaz.

Mevcut back-stack korunur.

Geri navigasyon her yeni alt ekrandan onu açan kaynak bağlama döner.

Aktif route gereksiz yere yeniden stack'e eklenmez.

Ana Akış davranışı korunur.

Profil davranışı korunur.

Followers/Following davranışları korunur.

Safety davranışı korunur.

Moderation davranışı korunur.

Mevcut FAB composer davranışı korunur.

Components

SocialPostCard

Normal Post:

SocialPostCard
├── author header
├── RichPostText
├── PostMediaPreview
└── SocialActionBar

Repost:

SocialPostCard(kind: Repost)
├── repost context
├── repost actor metadata
├── OriginalPostCard
│   ├── original author
│   ├── RichPostText
│   └── original media
└── parent SocialActionBar

Kurallar:

Original içerik parent karta flatten edilmez.

Original kart ikinci SocialActionBar göstermez.

OriginalPostCard → PostDetail(originalPost.id).

Quote:

SocialPostCard(kind: Quote)
├── quote author
├── quote RichPostText
├── quote media
├── OriginalPostCard
└── parent SocialActionBar

Kurallar:

Quote içeriği ile original içerik ayrıdır.

Quote media original media ile birleştirilmez.

Post Detail

PostDetail
├── author context
├── RichPostText
├── own PostMediaPreview
├── OriginalPostCard
├── SocialActionBar
└── replies

Kurallar:

Feed ve Post Detail aynı Post/Repost/Quote semantiğini kullanır.

Replies SocialActionBar sonrasında render edilir.

SocialActionBar

Aksiyon sırası:

Reply

Repost / Quote

Like

Bookmark

Repost state:

idle-not-reposted

loading-add

reposted

loading-remove

error

Quote state:

idle

opening-composer

submitting

success

error

Bookmark state:

idle-unselected

loading-add

selected

loading-remove

error

Kurallar:

Loading yalnız ilgili action üzerindedir.

Duplicate submit engellenir.

Error başarılı state'i silmez.

Bookmark state canonical API sonucundan gelir.

Public bookmark count gösterilmez.

Notifications

NotificationListItem
├── actor avatar
├── event summary
├── optional post preview
├── timestamp
└── unread indicator

Desteklenen türler:

Like

Reply

Follow

Mention

Read/unread:

Unread indicator görünür.

Read normal surface kullanır.

Read mutation yalnız ilgili notification item'ını etkiler.

Composer Media

Composer
├── text input
├── media preview
├── media picker
└── submit

Attachment state:

empty

selected

uploading

uploaded

uploadError

removing

Kurallar:

En az bir görsel desteklenir.

Upload tamamlanmadan media kimliği kullanılmaz.

Local preview API kimliği değildir.

Upload error text taslağını silmez.

Submit error text ve media state'ini korur.

Quote Composer

QuoteComposer
├── text input
├── own media attachment
├── OriginalPostCard
└── submit

Kurallar:

Original preview sabittir.

Quote content original content ile flatten edilmez.

Media lifecycle normal composer ile aynıdır.

PostMediaPreview

Feed ve Post Detail aynı media preview bileşen ailesini kullanır.

Hierarchy:

Post: text → media → SocialActionBar

Repost: repost context → OriginalPostCard → SocialActionBar

Quote: quote text → quote media → OriginalPostCard → SocialActionBar

Kurallar:

Aspect ratio korunur.

Screen states

Feed

Loading:

Initial loading sırasında empty gösterilmez.

Success:

Normal Post, Repost ve Quote doğru hierarchy ile render edilir.

Error:

Mutation hataları full-screen Feed error oluşturmaz.

Önceki başarılı kart state'i korunur.

Post Detail

Loading:

Action loading ana postu gizlemez.

Success:

Replies SocialActionBar sonrasında kalır.

Error:

Action-level hata item seviyesinde kalır.

Notifications

Loading:

Initial loading sırasında empty gösterilmez.

Empty:

Başlık: "Henüz bildirim yok"

Error:

Başlık: "Bildirimler yüklenemedi"

CTA: "Tekrar Dene"

Success:

Like, Reply, Follow ve Mention gösterilir.

Read/unread state görünür.

Kaydedilenler

Loading:

Skeleton/loading state kullanılır.

Empty:

Başlık: "Henüz kaydedilen gönderi yok"

Error:

Başlık: "Kaydedilenler yüklenemedi"

CTA: "Tekrar Dene"

Success:

SocialPostCard kullanılır.

Hashtag Posts

Loading:

Initial hashtag loading gösterilir.

Empty:

Başlık: "Bu etikette gönderi yok"

Error:

Başlık: "Gönderiler yüklenemedi"

CTA: "Tekrar Dene"

Success:

SocialPostCard ile render edilir.

Composer Media

States:

empty

selected

uploading

uploaded

uploadError

removing

Kurallar:

Upload tamamlanmadan media içeren submit tamamlanmaz.

Submit error text ve media state'ini korur.

Ortak state kuralları

401 merkezi login/session akışına gider.

403 empty değildir.

Ağ/5xx empty değildir.

Mutation error başarılı içeriği silmez.

Navigation

Mevcut root navigation korunur.

Giriş noktaları:

Notifications:

App shell notification girişinden açılır.

Kaydedilenler:

Profil/Hesap alanından açılır.

Hashtag Posts:

RichPostText içindeki #tag üzerinden açılır.

Quote Composer:

SocialActionBar → Repost → Alıntıla.

Post Detail:

Post card.

OriginalPostCard.

Notification target.

Kaydedilenler kartı.

Hashtag result kartı.

Kurallar:

@username → ProfilePage(username).

#tag → HashtagPostsPage(tag).

Post card → PostDetail(post.id).

OriginalPostCard → PostDetail(originalPost.id).

Yeni ekranlar orphan değildir.

Mevcut root navigation ve back-stack korunur.

İkinci root navigation oluşturulmaz.

Korunan navigation:

Ana Akış

Profil

Followers/Following

Safety

Moderation

FAB composer

Navigation eklenmeyen kapsam:

DM

Poll

Hashtag trends / trend keşfi

Algoritmik For You feed