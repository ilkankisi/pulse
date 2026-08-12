# Pulse Veritabanı Modeli

## 1. Amaç

Bu doküman güncel Pulse MVP için PostgreSQL veri modelini tanımlar.

Model aşağıdaki canonical dokümanlarla uyumludur:

- `docs/architecture.md`
- `docs/api-contract.md`

Backend Entity Framework Core modeli, migration'lar ve persistence testleri bu dokümandaki kararlarla uyumlu olmalıdır.

## 2. Genel kurallar

- Veritabanı: PostgreSQL
- ORM: Entity Framework Core
- Birincil kimlikler: integer identity
- Tarih-zaman: UTC `timestamp with time zone`
- Tablo ve sütun isimleri: snake_case
- HTTP JSON alanları: camelCase
- Şifreler düz metin saklanmaz.
- Kullanıcı sahipliği JWT `sub` claim'inden belirlenir.
- Gönderi metni veritabanında `content` sütununda saklanır.
- `description`, `title`, `text` veya `body` gönderi sütunu olarak kullanılmaz.
- Persistence enum string değerleri `docs/api-contract.md` içindeki canonical casing ile birebir aynı olmalıdır.
- Aynı enum için persistence, backend veya mobil katmanda ikinci bir string formatı tanımlanmaz.

## 3. Güncel MVP tabloları

Güncel MVP aşağıdaki tabloları gerektirir:

- `users`
- `posts`
- `follows`
- `likes`
- `user_blocks`
- `reports`
- `moderation_actions`

Arama, bildirim, bookmark, repost ve medya tabloları güncel MVP için zorunlu değildir.

`user_blocks`, `reports` ve `moderation_actions` Güvenlik & Moderasyon kapsamının canonical persistence tablolarıdır.

Sosyal Graf & Profil Tamamlama fazı yeni tablo gerektirmez. Bu faz mevcut `users`, `posts`, `follows` ve `user_blocks` tablolarından read model üretir.

## 4. İlişki diyagramı

~~~mermaid
erDiagram
    USERS ||--o{ POSTS : authors
    USERS ||--o{ FOLLOWS : follower
    USERS ||--o{ FOLLOWS : following
    USERS ||--o{ LIKES : creates
    USERS ||--o{ USER_BLOCKS : blocker
    USERS ||--o{ USER_BLOCKS : blocked
    USERS ||--o{ REPORTS : reporter
    USERS ||--o{ REPORTS : target_user
    USERS ||--o{ REPORTS : resolves
    USERS ||--o{ MODERATION_ACTIONS : moderator
    POSTS ||--o{ POSTS : receives_replies
    POSTS ||--o{ LIKES : receives
    POSTS ||--o{ REPORTS : target_post
    REPORTS ||--o{ MODERATION_ACTIONS : receives
~~~

## 5. users

### 5.1 Sütunlar

| Sütun | PostgreSQL türü | Null | Kural |
|---|---|---|---|
| `id` | integer | Hayır | Primary key, identity |
| `username` | varchar(30) | Hayır | Benzersiz |
| `normalized_username` | varchar(30) | Hayır | Küçük harf, benzersiz |
| `email` | varchar(320) | Hayır | Benzersiz |
| `normalized_email` | varchar(320) | Hayır | Küçük harf, benzersiz |
| `password_hash` | text | Hayır | BCrypt hash |
| `display_name` | varchar(80) | Hayır | Trim sonrası boş olamaz |
| `bio` | varchar(160) | Evet | Trimlenmiş |
| `avatar_url` | text | Evet | URL |
| `role` | varchar(32) | Hayır | Canonical kullanıcı rolü |
| `is_active` | boolean | Hayır | Varsayılan `true` |
| `created_at` | timestamptz | Hayır | UTC |
| `updated_at` | timestamptz | Evet | UTC |

### 5.2 Role değerleri

`role` yalnız aşağıdaki canonical persistence değerlerinden birini saklar:

- `User`
- `Moderator`

Bu string'ler JWT/API rol kararlarıyla birebir aynıdır.

Aşağıdaki gibi alternatif role persistence değerleri kullanılmaz:

- küçük harfli alias
- snake_case alias
- endpoint'e özel farklı rol string'i

### 5.3 İndeksler

- Unique index: `normalized_username`
- Unique index: `normalized_email`
- Index: `(is_active, created_at DESC)`
- Index: `(role, is_active)`

### 5.4 Kurallar

Kullanıcı adı karşılaştırmaları normalize edilmiş alan üzerinden yapılır.

E-posta karşılaştırmaları normalize edilmiş alan üzerinden yapılır.

Password hash dışında şifre verisi saklanmaz.

Kullanıcı kendi kimliğini request body ile belirleyemez.

`is_active=false` kullanıcı hesabının aktif kabul edilmediğini gösterir.

Authentication ve korumalı kaynak erişimi application katmanında `is_active` durumunu dikkate almalıdır.

Moderator yetkisi yalnız istemci UI kontrolüne bırakılmaz; backend rol doğrulaması zorunludur.

`created_at`, profile response içindeki canonical `createdAt` alanının persistence kaynağıdır.

Profil sayaçları `users` tablosunda zorunlu denormalize sütunlar değildir.

## 6. posts

### 6.1 Sütunlar

| Sütun | PostgreSQL türü | Null | Kural |
|---|---|---|---|
| `id` | integer | Hayır | Primary key, identity |
| `author_id` | integer | Hayır | FK → `users.id` |
| `content` | varchar(280) | Hayır | Trim sonrası 1–280 karakter |
| `parent_post_id` | integer | Evet | Self FK → `posts.id` |
| `created_at` | timestamptz | Hayır | UTC |
| `deleted_at` | timestamptz | Evet | Kullanıcı soft delete zamanı |
| `is_hidden` | boolean | Hayır | Varsayılan `false`; moderasyon görünürlüğü |

### 6.2 İndeksler

- Index: `(created_at DESC, id DESC)`
- Index: `(author_id, created_at DESC, id DESC)`
- Index: `(parent_post_id, created_at ASC, id ASC)`
- Index: `(is_hidden, created_at DESC, id DESC)`
- Partial index: `deleted_at IS NULL`
- Görünür feed/profil sorguları için uygun index: `deleted_at IS NULL AND is_hidden = false`

### 6.3 Kurallar

`content` null olamaz.

`content` trim sonrası boş olamaz.

`content` en fazla 280 karakterdir.

`author_id` request body üzerinden alınmaz.

Ana gönderide `parent_post_id` null olur.

Yanıtta `parent_post_id` üst gönderinin kimliğidir.

`parent_post_id` dolu olan bir gönderiye yeni yanıt oluşturulamaz.

Bir gönderinin standart kullanıcı silme yetkisi sahibine aittir.

Standart kullanıcı silmesi fiziksel DELETE yerine `deleted_at` ile soft delete olarak uygulanabilir.

Moderasyon kaldırması standart kullanıcı silmesinden ayrıdır.

`RemovePost` moderasyon aksiyonunda:

~~~text
is_hidden = true
~~~

uygulanır.

Moderasyon kararı fiziksel DELETE yapmaz.

Bir gönderinin normal istemciye görünür kabul edilmesi için iki koşul birlikte sağlanmalıdır:

~~~text
deleted_at IS NULL
is_hidden = false
~~~

`deleted_at IS NOT NULL` veya `is_hidden=true` olan gönderiler:

- feed içinde dönmez,
- profil gönderi listesinde dönmez,
- normal görünür gönderi kabul edilmez,
- yeni like kabul etmez,
- yeni reply kabul etmez.

### 6.4 Tek seviyeli yanıt doğrulaması

Yeni yanıt oluşturulmadan önce üst gönderi okunur.

Aşağıdaki koşul sağlanmalıdır:

~~~text
parent.parent_post_id IS NULL
~~~

Üst gönderinin `parent_post_id` değeri doluysa işlem reddedilir.

Üst gönderi ayrıca görünür olmalıdır:

~~~text
parent.deleted_at IS NULL
parent.is_hidden = false
~~~

### 6.5 Profil gönderileri read modeli

Canonical profil gönderileri sorgusu:

- `author_id = profile_user_id`
- `parent_post_id IS NULL`
- `deleted_at IS NULL`
- `is_hidden = false`

koşullarını birlikte uygular.

Sıralama:

~~~text
created_at DESC
id DESC
~~~

Profil `postCount` değeri aynı görünür kök gönderi koşullarını kullanan sayımdan türetilir.

Reply kayıtları profil ana gönderi collection'ına dahil edilmez.

## 7. follows

### 7.1 Sütunlar

| Sütun | PostgreSQL türü | Null | Kural |
|---|---|---|---|
| `follower_id` | integer | Hayır | FK → `users.id` |
| `following_id` | integer | Hayır | FK → `users.id` |
| `created_at` | timestamptz | Hayır | UTC |

### 7.2 Anahtar ve indeksler

Composite primary key:

~~~text
(follower_id, following_id)
~~~

Check constraint:

~~~text
follower_id <> following_id
~~~

İndeksler:

- Index: `(following_id, created_at DESC)`
- Index: `(follower_id, created_at DESC)`

### 7.3 Kurallar

Kullanıcı kendisini takip edemez.

Aynı takip ilişkisi birden fazla kez oluşturulamaz.

Takip eden kullanıcı JWT `sub` claim'inden belirlenir.

Takip hedefi path'teki username üzerinden çözülür.

Request body içinde `followerId` veya `followingId` bulunmaz.

İki kullanıcı arasında herhangi bir yönde block ilişkisi bulunuyorsa yeni follow oluşturulamaz.

Yeni block oluşturulduğunda iki kullanıcı arasındaki mevcut follow kayıtları kaldırılır.

Unblock işlemi eski follow kayıtlarını otomatik geri oluşturmaz.

### 7.4 Sosyal graf read modeli

`followerCount`, hedef kullanıcının `following_id` olduğu follow kayıtlarının sayısıdır.

`followingCount`, hedef kullanıcının `follower_id` olduğu follow kayıtlarının sayısıdır.

`isFollowedByCurrentUser` aşağıdaki ilişkinin varlığından türetilir:

~~~text
follower_id = current_user_id
following_id = response_user_id
~~~

Bu alan persistence sütunu değildir.

Followers collection sorgusu:

~~~text
following_id = profile_user_id
~~~

koşulunu kullanır.

Following collection sorgusu:

~~~text
follower_id = profile_user_id
~~~

koşulunu kullanır.

Her iki collection da follow ilişkisinin:

~~~text
created_at DESC
~~~

sırasını kullanır; eşitlikte response kullanıcı `id DESC` ile deterministik sıralama uygulanır.

Followers ve following için mevcut indeksler yeterlidir; yeni sosyal graf tablosu gerekmez.
## 8. likes

### 8.1 Sütunlar

| Sütun | PostgreSQL türü | Null | Kural |
|---|---|---|---|
| `user_id` | integer | Hayır | FK → `users.id` |
| `post_id` | integer | Hayır | FK → `posts.id` |
| `created_at` | timestamptz | Hayır | UTC |

### 8.2 Anahtar ve indeksler

Composite primary key:

~~~text
(user_id, post_id)
~~~

Foreign key'ler:

~~~text
user_id -> users.id
post_id -> posts.id
~~~

İndeksler:

- Index: `(post_id, created_at DESC)`
- Index: `(user_id, created_at DESC)`

### 8.3 Kurallar

Bir kullanıcı aynı gönderiyi en fazla bir kez beğenebilir.

Like sahibi JWT `sub` claim'inden belirlenir.

Request body içinde `userId` bulunmaz.

Like hedefi path'teki `postId` üzerinden çözülür.

Aşağıdaki postlara yeni like oluşturulamaz:

- `deleted_at IS NOT NULL`
- `is_hidden = true`
- block ilişkisi nedeniyle kullanıcıya görünmeyen post

Block veya görünürlük nedeniyle erişilemeyen hedef HTTP katmanında canonical `404` semantiğini kullanır.

## 9. user_blocks

### 9.1 Sütunlar

| Sütun | PostgreSQL türü | Null | Kural |
|---|---|---|---|
| `blocker_user_id` | integer | Hayır | FK → `users.id` |
| `blocked_user_id` | integer | Hayır | FK → `users.id` |
| `created_at` | timestamptz | Hayır | UTC |

### 9.2 Anahtar ve indeksler

Composite primary key:

~~~text
(blocker_user_id, blocked_user_id)
~~~

Foreign key'ler:

~~~text
blocker_user_id -> users.id
blocked_user_id -> users.id
~~~

Check constraint:

~~~text
blocker_user_id <> blocked_user_id
~~~

Unique invariant:

~~~text
(blocker_user_id, blocked_user_id)
~~~

aynı yönlü block ilişkisini tekilleştirir.

Ek index:

~~~text
(blocked_user_id, created_at DESC)
~~~

### 9.3 Kurallar

Engelleyen kullanıcı JWT `sub` claim'inden belirlenir.

Engellenen kullanıcı canonical profile path'indeki username üzerinden çözülür.

Request body içinde `blockerUserId` veya `blockedUserId` bulunmaz.

Kullanıcı kendisini engelleyemez.

Aynı block ilişkisi ikinci kez oluşturulmaz.

Create işlemi idempotent API davranışı gösterebilir ancak persistence'ta duplicate satır oluşturmaz.

Block oluşturulduğunda:

1. `user_blocks` ilişkisi oluşturulur.
2. `blocker -> blocked` follow kaydı varsa kaldırılır.
3. `blocked -> blocker` follow kaydı varsa kaldırılır.
4. İşlem tek transaction içinde tamamlanır.

Unblock eski follow kayıtlarını geri oluşturmaz.

### 9.4 Görünürlük kontrolü

Etkileşim ve içerik görünürlüğü için iki kullanıcı arasında herhangi bir yönde block bulunması yeterlidir.

Örnek mantık:

~~~text
EXISTS (
  blocker_user_id = current_user_id
  AND blocked_user_id = target_user_id
)
OR
EXISTS (
  blocker_user_id = target_user_id
  AND blocked_user_id = current_user_id
)
~~~

Bu kontrol server-side olarak:

- profil görünürlüğünde,
- profil gönderileri collection'ında,
- followers collection'ında,
- following collection'ında,
- feed filtrelemesinde,
- follow oluşturmada,
- like hedefinde,
- reply hedefinde

uygulanmalıdır.

Followers ve following collection'larında response öğesindeki kullanıcı oturum sahibine block nedeniyle görünmüyorsa ilgili öğe sonuçtan çıkarılır.

Hedef profil oturum sahibine block nedeniyle görünmüyorsa profile bağlı collection sorgusu çalıştırılmaz; HTTP katmanı canonical `404` sonucu üretir.

## 10. reports

### 10.1 Sütunlar

| Sütun | PostgreSQL türü | Null | Kural |
|---|---|---|---|
| `id` | integer | Hayır | Primary key, identity |
| `reporter_user_id` | integer | Hayır | FK → `users.id` |
| `target_type` | varchar(32) | Hayır | Canonical `ReportTargetType` |
| `target_post_id` | integer | Evet | FK → `posts.id` |
| `target_user_id` | integer | Evet | FK → `users.id` |
| `reason` | varchar(32) | Hayır | Canonical `ReportReason` |
| `details` | varchar(500) | Evet | Kullanıcı açıklaması |
| `status` | varchar(32) | Hayır | Canonical `ReportStatus`; varsayılan `Pending` |
| `created_at` | timestamptz | Hayır | UTC |
| `resolved_at` | timestamptz | Evet | UTC |
| `resolved_by_user_id` | integer | Evet | FK → `users.id` |

### 10.2 ReportTargetType

`target_type` için tam canonical persistence değerleri:

- `Post`
- `User`

Persistence değeri API enum string'i ile birebir aynıdır.

### 10.3 ReportReason

`reason` için tam canonical persistence değerleri:

- `Spam`
- `Harassment`
- `HateSpeech`
- `Violence`
- `SexualContent`
- `Impersonation`
- `Other`

### 10.4 ReportStatus

`status` için tam canonical persistence değerleri:

- `Pending`
- `Resolved`
- `Dismissed`

Yeni report başlangıç durumu:

~~~text
Pending
~~~

Enum değerlerinde küçük harfli alias, snake_case veya endpoint'e özel farklı casing kullanılmaz.

### 10.5 Target bütünlüğü

Bir report tam olarak bir hedefe sahip olmalıdır.

`target_type = Post` olduğunda:

~~~text
target_post_id IS NOT NULL
target_user_id IS NULL
~~~

`target_type = User` olduğunda:

~~~text
target_user_id IS NOT NULL
target_post_id IS NULL
~~~

Database check constraint iki target foreign key'in aynı anda dolu olmasını veya ikisinin de null olmasını engellemelidir.

Mantıksal constraint:

~~~text
(
  target_type = 'Post'
  AND target_post_id IS NOT NULL
  AND target_user_id IS NULL
)
OR
(
  target_type = 'User'
  AND target_user_id IS NOT NULL
  AND target_post_id IS NULL
)
~~~

### 10.6 Foreign key'ler

~~~text
reporter_user_id -> users.id
target_post_id -> posts.id
target_user_id -> users.id
resolved_by_user_id -> users.id
~~~

### 10.7 İndeksler

- Index: `(status, created_at)`
- Index: `(reporter_user_id, target_type, target_post_id)`
- Index: `(reporter_user_id, target_type, target_user_id)`
- Index: `(resolved_by_user_id, resolved_at)`

Aynı reporter ve aynı target için yalnızca bir açık `Pending` rapora izin verilir.

Bu invariant application katmanında zorunlu olarak kontrol edilir.

PostgreSQL tarafında uygun partial unique index/constraint ile desteklenmelidir.
Post target için mantıksal tekillik:

~~~text
reporter_user_id
target_type
target_post_id
WHERE status = 'Pending'
~~~

User target için mantıksal tekillik:

~~~text
reporter_user_id
target_type
target_user_id
WHERE status = 'Pending'
~~~

### 10.8 Kurallar

Reporter kullanıcı JWT `sub` claim'inden belirlenir.

Request body reporter id içermez.

Kullanıcı kendi hesabını şikâyet edemez.

Kullanıcı kendi postunu şikâyet edemez.

`details` null olabilir.

`details` en fazla 500 karakterdir.

Report oluşturmak hedef post veya kullanıcı üzerinde otomatik persistence değişikliği oluşturmaz.

Bir report yalnız `Pending` durumundayken resolve/dismiss edilebilir.

Resolve sonucunda:

~~~text
status = Resolved
resolved_at = current UTC
resolved_by_user_id = moderator id
~~~

Dismiss sonucunda:

~~~text
status = Dismissed
resolved_at = current UTC
resolved_by_user_id = moderator id
~~~

## 11. moderation_actions

### 11.1 Sütunlar

| Sütun | PostgreSQL türü | Null | Kural |
|---|---|---|---|
| `id` | integer | Hayır | Primary key, identity |
| `report_id` | integer | Hayır | FK → `reports.id` |
| `moderator_user_id` | integer | Hayır | FK → `users.id` |
| `action` | varchar(32) | Hayır | Canonical `ModerationAction` |
| `note` | varchar(500) | Evet | Moderasyon notu |
| `created_at` | timestamptz | Hayır | UTC |

### 11.2 ModerationAction

`action` için canonical persistence değerleri:

- `NoAction`
- `RemovePost`

Bu değerler `docs/api-contract.md` içindeki string değerleriyle birebir aynıdır.

Alternatif küçük harf veya farklı format kullanılmaz.

### 11.3 Foreign key ve indeksler

Foreign key'ler:

~~~text
report_id -> reports.id
moderator_user_id -> users.id
~~~

İndeksler:

- Index: `(report_id)`
- Index: `(moderator_user_id, created_at DESC)`
- Index: `(action, created_at DESC)`

### 11.4 Audit davranışı

Moderasyon kararı denetlenebilir bir persistence kaydı oluşturmalıdır.

Kayıt en az:

- report kimliği,
- moderator kullanıcı kimliği,
- canonical action,
- opsiyonel note,
- UTC karar zamanı

içermelidir.

`note` null olabilir ve en fazla 500 karakterdir.

## 12. Moderasyon persistence davranışı

### 12.1 NoAction

`NoAction` işlemi:

1. report'un `Pending` olduğunu doğrular.
2. `moderation_actions` kaydı oluşturur.
3. report `Resolved` yapılır.
4. `resolved_at` doldurulur.
5. `resolved_by_user_id` doldurulur.
6. hedef kullanıcı veya post değiştirilmez.

### 12.2 RemovePost

`RemovePost` yalnız `target_type=Post` raporlarında geçerlidir.

Persistence işlemi:

1. report'un `Pending` olduğunu doğrular.
2. target postu doğrular.
3. `moderation_actions` kaydı oluşturur.
4. report'u `Resolved` yapar.
5. `resolved_at` ve `resolved_by_user_id` alanlarını doldurur.
6. hedef postta `is_hidden=true` yapar.

`RemovePost`:

- fiziksel DELETE yapmaz,
- post `deleted_at` alanını kullanıcı silmesiyle karıştırmaz,
- moderasyon görünürlüğünü `is_hidden` ile temsil eder.

### 12.3 Dismiss

Dismiss:

1. report'un `Pending` olduğunu doğrular.
2. report'u `Dismissed` yapar.
3. `resolved_at` doldurur.
4. `resolved_by_user_id` doldurur.
5. denetlenebilir moderasyon kaydı oluşturur.
6. hedef kaynağı değiştirmez.

### 12.4 Transaction sınırı

Aşağıdaki değişiklikler tek database transaction içinde yapılmalıdır:

- moderation action audit kaydı,
- report state transition,
- gerekiyorsa post `is_hidden` değişikliği.

Ara adımlardan biri başarısız olursa transaction rollback edilmelidir.

İkinci concurrent resolve/dismiss işlemi güncel report state kontrolü nedeniyle uygulanmamalıdır.

API bu state çakışmasını `409 Conflict` olarak temsil eder.

## 13. Görünürlük ve sorgu kuralları

### 13.1 Post görünürlüğü

Normal kullanıcıya görünür post filtresi en az:

~~~text
deleted_at IS NULL
AND is_hidden = false
~~~

koşullarını kullanır.

Feed ve profil gönderileri ayrıca block ilişkisini de dikkate alır.

### 13.2 Profile görünürlüğü

Profile hedef kullanıcı ile oturum sahibi arasında herhangi bir yönde block varsa canonical API görünürlük kuralı uygulanır.

Persistence katmanı block ilişkisinin varlığını sağlayan sorguyu sunar.

HTTP katmanı bunu `404` semantiğiyle temsil eder.

Profile bağlı aşağıdaki collection'lar aynı görünürlük ön koşulunu kullanır:

- profil gönderileri,
- followers,
- following.

### 13.3 Like ve reply hedefi

Like/reply hedef postu:

~~~text
deleted_at IS NULL
AND is_hidden = false
~~~

olmalıdır.

Post author ile oturum sahibi arasında block ilişkisi bulunmamalıdır.

### 13.4 Sosyal graf görünürlüğü

Followers ve following collection'ları için:

1. hedef profil görünür olmalıdır,
2. follow ilişkileri mevcut `follows` tablosundan okunmalıdır,
3. response kullanıcısı oturum sahibine block nedeniyle görünmüyorsa sonuçtan çıkarılmalıdır.

Sosyal graf görünürlük filtresi follow ilişkisini fiziksel olarak değiştirmez.

Block oluşturma sırasında mevcut follow kayıtlarının kaldırılması ayrı transaction davranışıdır.

## 14. Delete davranışları ve foreign key stratejisi

İlişkisel bütünlük korunmalıdır.

Kullanıcı veya postların fiziksel silinmesi MVP'nin normal kullanıcı akışı değildir.

Post silme soft-delete/görünürlük modeli kullandığından report ve moderation audit kayıtlarının tarihsel referansları korunmalıdır.

Önerilen davranışlar:

- `posts.author_id -> users.id`: restrict
- `posts.parent_post_id -> posts.id`: restrict veya audit bütünlüğünü koruyan eşdeğer davranış
- `follows.* -> users.id`: cascade yalnız açıkça hesap fiziksel silme süreci tanımlanırsa
- `likes.user_id -> users.id`: hesap fiziksel silme sürecine göre cascade
- `likes.post_id -> posts.id`: normal akışta post fiziksel silinmez
- `user_blocks.* -> users.id`: hesap fiziksel silme sürecine göre cascade
- `reports.reporter_user_id -> users.id`: audit gereksinimine göre restrict
- `reports.target_user_id -> users.id`: audit gereksinimine göre restrict
- `reports.target_post_id -> posts.id`: audit gereksinimine göre restrict
- `reports.resolved_by_user_id -> users.id`: audit gereksinimine göre restrict
- `moderation_actions.report_id -> reports.id`: restrict
- `moderation_actions.moderator_user_id -> users.id`: restrict

Production retention veya kullanıcı hesabı fiziksel silme politikası ayrı bir ürün kararıdır.
## 15. Canonical database ↔ API eşlemeleri

Database snake_case alanları HTTP JSON property adlarını değiştirmez.

Örnekler:

| Database | API |
|---|---|
| `display_name` | `displayName` |
| `avatar_url` | `avatarUrl` |
| `created_at` | `createdAt` |
| `parent_post_id` | `parentPostId` |
| `target_type` | `targetType` |
| `target_post_id` / `target_user_id` | `targetId` + `targetType` |
| `resolved_at` | `resolvedAt` |
| `resolved_by_user_id` | `resolvedByUserId` |

`is_hidden` persistence görünürlük alanıdır.

Moderasyon resolve request body için `isHidden` alanı tanımlanmaz.

İstemci `RemovePost` canonical moderation action'ını gönderir; persistence katmanı bunun sonucunu `posts.is_hidden=true` olarak uygular.

Profil read modelinde:

- `users.created_at` → `createdAt`
- görünür kök post sayımı → `postCount`
- hedef kullanıcının takipçi sayımı → `followerCount`
- hedef kullanıcının takip ettiği hesap sayımı → `followingCount`
- current user ile response kullanıcısı arasındaki follow ilişkisi → `isFollowedByCurrentUser`

olarak eşlenir.

`postCount`, `followerCount`, `followingCount` ve `isFollowedByCurrentUser` için ayrı persistence sütunu zorunlu değildir.

## 16. Persistence enum tek kaynak kuralı

Canonical string değerleri:

### UserRole

- `User`
- `Moderator`

### ReportTargetType

- `Post`
- `User`

### ReportReason

- `Spam`
- `Harassment`
- `HateSpeech`
- `Violence`
- `SexualContent`
- `Impersonation`
- `Other`

### ReportStatus

- `Pending`
- `Resolved`
- `Dismissed`

### ModerationAction

- `NoAction`
- `RemovePost`

Bu değerler API contract ile birebir aynıdır.

Backend persistence enum/string dönüşümü bu değerlerden başka format üretmemelidir.

Mobil serializer için de `docs/api-contract.md` tek kaynak olmaya devam eder.

## 17. Migration gereksinimleri

Güvenlik & Moderasyon migration'ı en az aşağıdaki şema değişikliklerini içermelidir:

- `users.role`
- mevcut `users.is_active` alanının korunması
- `posts.is_hidden`
- `user_blocks` tablosu
- `reports` tablosu
- `moderation_actions` tablosu
- gerekli foreign key'ler
- block composite unique/primary key
- report target integrity constraint
- duplicate pending report invariant'ını destekleyen index/constraint'ler
- görünür post sorgularını destekleyen index'ler
- moderation queue için `reports(status, created_at)` index'i
- moderation audit için `moderation_actions(report_id)` index'i

Migration mevcut `users`, `posts`, `follows` veya `likes` verilerini gereksiz yere yeniden oluşturmaz.

Yeni non-null boolean alan için güvenli varsayılan:

~~~text
posts.is_hidden = false
~~~

Yeni kullanıcı rolü için güvenli başlangıç değeri:

~~~text
users.role = User
~~~

Moderator kullanıcı ataması seed/admin operasyonu tarafından açıkça yapılmalıdır.

### 17.1 Sosyal Graf & Profil Tamamlama migration kararı

Sosyal Graf & Profil Tamamlama fazı için yeni migration zorunlu değildir.

Gerekli veriler mevcut alanlardan türetilir:

- `users.created_at`
- `posts.author_id`
- `posts.parent_post_id`
- `posts.deleted_at`
- `posts.is_hidden`
- `follows.follower_id`
- `follows.following_id`
- `follows.created_at`
- `user_blocks.blocker_user_id`
- `user_blocks.blocked_user_id`

Yeni:

- `post_count`
- `follower_count`
- `following_count`
- `is_followed_by_current_user`
- `profile_posts`
- `social_graph`

sütun veya tabloları bu MVP kapsamında oluşturulmaz.

İleride performans nedeniyle denormalize sayaçlar eklenirse bunların transaction/tutarlılık stratejisi ayrı migration ve mimari karar gerektirir.

## 18. Test doğrulamaları

Backend persistence/integration testleri en az aşağıdakileri doğrulamalıdır:

- `users.role` canonical değerleri
- `users.is_active` davranışı
- `posts.is_hidden` varsayılan `false`
- block composite tekilliği
- self-block iş kuralı
- block sonrası follow temizliği
- block görünürlük filtresi
- report Post target bütünlüğü
- report User target bütünlüğü
- iki target'ın aynı anda dolmasının reddi
- target bulunmadığında report oluşturulmaması
- duplicate `Pending` report invariant'ı
- canonical `ReportTargetType`
- canonical `ReportReason`
- canonical `ReportStatus`
- canonical `ModerationAction`
- moderator resolve `NoAction`
- moderator resolve `RemovePost`
- `RemovePost` sonrası `posts.is_hidden=true`
- dismiss sonrası hedef kaynağın değişmemesi
- ikinci resolve/dismiss state çakışmasının reddi
- moderation audit kaydının oluşturulması
- hidden/deleted postların feed, like ve reply sorgularından filtrelenmesi
- `users.created_at` değerinin profile `createdAt` alanına kaynak olması
- `postCount` hesabının yalnız görünür kök gönderileri sayması
- `followerCount` hesabının `following_id` üzerinden doğru üretilmesi
- `followingCount` hesabının `follower_id` üzerinden doğru üretilmesi
- `isFollowedByCurrentUser` hesabının current-user follow ilişkisine göre üretilmesi
- profil gönderilerinin yalnız hedef kullanıcıya ait görünür kök postları döndürmesi
- profil gönderilerinin `created_at DESC, id DESC` sıralanması
- followers sorgusunun `following_id = profile_user_id` kullanması
- following sorgusunun `follower_id = profile_user_id` kullanması
- sosyal graf listelerinde block nedeniyle görünmeyen kullanıcıların filtrelenmesi
- mevcut profil için boş collection'ın hata olarak değerlendirilmemesi

Persistence testlerindeki canonical enum değerleri `docs/api-contract.md` golden sample değerlerinden farklı casing kullanmamalıdır.

## 19. Model özeti

Güncel persistence modeli:

~~~text
users
  role
  is_active
  created_at

posts
  author_id
  parent_post_id
  deleted_at
  is_hidden

follows
  follower_id
  following_id
  created_at

likes
user_blocks
reports
moderation_actions
~~~

Güvenlik & Moderasyon kararları:

- block ilişkisi yönlüdür,
- block persistence tekildir,
- block iki kullanıcı arasındaki mevcut follow ilişkilerini kaldırır,
- report hedefi tam olarak `Post` veya `User` olur,
- duplicate açık report oluşturulmaz,
- moderator işlemleri audit edilir,
- `NoAction` hedefi değiştirmez,
- `RemovePost` `posts.is_hidden=true` uygular,
- kullanıcı soft delete davranışı `deleted_at` ile ayrı tutulur,
- canonical persistence enum değerleri API contract ile birebir aynıdır.

Sosyal Graf & Profil Tamamlama kararları:

- yeni sosyal graf tablosu yoktur,
- yeni profil-post ilişki tablosu yoktur,
- yeni sayaç sütunları zorunlu değildir,
- `createdAt` kaynağı `users.created_at` değeridir,
- `postCount` görünür kök postlardan türetilir,
- `followerCount` mevcut `follows` tablosundan türetilir,
- `followingCount` mevcut `follows` tablosundan türetilir,
- `isFollowedByCurrentUser` mevcut follow ilişkisinden türetilir,
- profil gönderileri mevcut `posts` tablosundan okunur,
- followers/following mevcut `follows` tablosundan okunur,
- sosyal graf görünürlüğü mevcut `user_blocks` modeliyle server-side filtrelenir.

## 20. Sosyal Graf ve Profil read-model özeti

Canonical kaynak eşlemesi:

~~~text
Profile
  users
  posts
  follows
  user_blocks

Profile Posts
  posts
  users
  user_blocks

Followers
  follows
  users
  user_blocks

Following
  follows
  users
  user_blocks
~~~

Profile read model:

~~~text
id
username
displayName
bio
avatarUrl
createdAt
postCount
followerCount
followingCount
isFollowedByCurrentUser
~~~

bu alanları mevcut persistence modelinden üretir.

Followers ve following liste öğeleri aynı persistence projection yaklaşımını kullanır:

~~~text
id
username
displayName
avatarUrl
isFollowedByCurrentUser
~~~

Bu alanlar yeni tablo veya kalıcı projection olarak zorunlu değildir.

Backend sorguları:

- canonical profile namespace ile hedef kullanıcıyı çözer,
- block görünürlüğünü uygular,
- yalnız gerekli projection alanlarını seçer,
- collection sıralamasını deterministic tutar,
- API katmanına canonical camelCase response modeli sağlar.

Bu fazın persistence kararı mevcut ilişkisel modeli yeniden kullanmak ve ikinci bir sosyal graf veri kaynağı oluşturmamaktır.