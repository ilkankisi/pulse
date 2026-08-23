# Feature: Sosyal Etkileşim Fazı

## Scope

Feature: Sosyal Etkileşim Fazı
Scope
Bu feature mevcut Pulse uygulamasına sosyal etkileşim davranışlarını ekler.
## Acceptance Evidence

### Feed ve Post Detail repost / quote

Feed ve Post Detail aynı SocialPostCard semantiğini kullanır.

Normal Post:

text +SocialPostCard +├── author header +├── RichPostText +├── PostMediaPreview +└── SocialActionBar +

Repost:

text +SocialPostCard(kind: Repost) +├── repost context +├── repost actor metadata +├── OriginalPostCard +│   ├── original author +│   ├── RichPostText +│   └── original media +└── parent SocialActionBar +

Kurallar:

- Original içerik parent karta flatten edilmez.
- OriginalPostCard ikinci SocialActionBar göstermez.
- OriginalPostCard açılışı PostDetail(originalPost.id) ile yapılır.

Quote:

text +SocialPostCard(kind: Quote) +├── quote author +├── quote RichPostText +├── quote media +├── OriginalPostCard +└── parent SocialActionBar +

Kurallar:

- Quote metni ve original içerik ayrı render edilir.
- Quote media original media ile birleştirilmez.

Action state:

- Repost: idle, loading, success, error
- Bookmark: idle-unselected, loading-add, selected, loading-remove, error
- Loading yalnız ilgili action üzerinde görünür.
- Duplicate submit engellenir.
- Mutation error mevcut başarılı içeriği silmez.
- Public bookmark count gösterilmez.

### Notifications

Notification ekranı mevcut app shell notification girişinden açılır.

text +NotificationListItem +├── actor avatar +├── event summary +├── optional post preview +├── timestamp +└── unread indicator +

Desteklenen event türleri:

- Like
- Reply
- Follow
- Mention

State davranışları:

- Initial loading sırasında empty gösterilmez.
- Empty: "Henüz bildirim yok"
- Error: "Bildirimler yüklenemedi" + "Tekrar Dene"
- Unread kayıtlar indicator ile gösterilir.
- Read kayıtlar normal surface kullanır.

### Mention ve hashtag navigation

- @username → ProfilePage(username)
- #tag → HashtagPostsPage(tag)

RichPostText içindeki navigation mevcut root navigation ve back-stack üzerinde çalışır.

### Bookmark / Kaydedilenler

Kaydedilenler mevcut Profil/Hesap alanından açılır. Yeni root navigation oluşturulmaz.

State:

- Loading: skeleton/loading state
- Empty: "Henüz kaydedilen gönderi yok"
- Error: "Kaydedilenler yüklenemedi"
- Success: SocialPostCard ile render edilir.

Bookmark durumu canonical API sonucundan gelir.

### Composer media lifecycle

Composer:

text +Composer +├── text input +├── media preview +├── media picker +└── submit +

Attachment state:

- empty
- selected
- uploading
- uploaded
- uploadError
- removing

Kurallar:

- En az tek görsel desteklenir.
- Upload tamamlanmadan media id kullanılmaz.
- Local preview API kimliği değildir.
- Upload error taslağı silmez.
- Submit error text ve media state'ini korur.

QuoteComposer:

text +QuoteComposer +├── text input +├── own media attachment +├── OriginalPostCard +└── submit +

Original preview sabittir. Media lifecycle normal composer ile aynıdır.

### Media preview hierarchy

Feed ve Post Detail aynı PostMediaPreview bileşen ailesini kullanır.

- Post: text → media → SocialActionBar
- Repost: repost context → OriginalPostCard → SocialActionBar
- Quote: quote text → quote media → OriginalPostCard → SocialActionBar

Aspect ratio korunur.

### Navigation korunumu ve orphan kontrolü

Yeni ekran girişleri:

- Notifications → app shell notification entry
- Kaydedilenler → Profil/Hesap action
- Hashtag Posts → RichPostText hashtag action
- Quote Composer → SocialActionBar → Repost → Alıntıla
- Post Detail → post card, OriginalPostCard, notification target

Kurallar:

- Yeni ekranlar orphan değildir.
- Mevcut root navigation korunur.
- Back-stack korunur.
- İkinci root navigation oluşturulmaz.
- Mevcut Ana Akış, Profil, Followers/Following, Safety, Moderation ve FAB composer davranışları değişmez.

Kapsam dışı:

- DM / özel mesaj
- Poll / anket
- Hashtag trends
- Algoritmik For You feed
- Çok seviyeli thread


Korunan davranışlar:
- Mevcut Material 3 tasarım sistemi
- Root navigation
- Back-stack
- Profil
- Feed
- Composer
- Safety
- Moderation akışları

Kapsam:
- Repost ve Quote
- Notifications
- Mention ve hashtag navigation
- Bookmark / Kaydedilenler
- Tek görselli media composer
- Feed ve Post Detail media preview

Kapsam dışı:
- DM / özel mesaj
- Poll / anket
- Hashtag trendleri
- Algoritmik For You feed
- Çok seviyeli thread
- İkinci root navigation
- Public bookmark count

## Components

### SocialPostCard

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

Kurallar:

Original içerik parent karta flatten edilmez.

Original kart ikinci SocialActionBar göstermez.

OriginalPostCard PostDetail(originalPost.id) açar.

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

idle

loading

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

NotificationListItem:

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

unread indicator görünür.

read normal surface kullanır.

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

Post:
text → media → SocialActionBar

Repost:
repost context → OriginalPostCard → SocialActionBar

Quote:
quote text → quote media → OriginalPostCard → SocialActionBar

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

Kaydedilenler

Loading:

Skeleton/loading state kullanılır.

Empty:

Başlık: "Henüz kaydedilen gönderi yok"

Error:

Başlık: "Kaydedilenler yüklenemedi"

Success:

SocialPostCard kullanılır.

Hashtag Posts

Loading:

Initial hashtag loading gösterilir.

Empty:

Başlık: "Bu etikette gönderi yok"

Error:

Başlık: "Gönderiler yüklenemedi"

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

Upload tamamlanmadan submit edilmez.

Submit error text ve media state'ini korur.

Ortak kurallar:

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

SocialActionBar → Repost → Alıntıla

Post Detail:

Post card

OriginalPostCard

Notification target

Kurallar:

@username → ProfilePage(username)

#tag → HashtagPostsPage(tag)

Post card → PostDetail(post.id)

OriginalPostCard → PostDetail(originalPost.id)

Yeni ekranlar orphan değildir.

Mevcut root navigation ve back-stack korunur.

İkinci root navigation oluşturulmaz.

Korunan:

Ana Akış

Profil

Followers/Following

Safety

Moderation

FAB composer

Navigation eklenmeyen kapsam:

DM

Poll

Hashtag trends

Algoritmik For You feed
action: update