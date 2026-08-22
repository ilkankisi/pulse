# Pulse — Database Model

## 1. Amaç

Bu doküman Pulse canonical PostgreSQL veri modelini tanımlar.

API wire-format kaynağı `docs/api-contract.md` dosyasıdır.

İlkeler:

- primary key integer
- timestamp UTC
- foreign key ile referential integrity
- sosyal ilişkilerde duplicate engeli
- retry/double-tap için idempotency invariant'ları
- MinIO binary, PostgreSQL metadata
- ownership backend tarafından doğrulanır

Database kolon adları API JSON alan adları olmak zorunda değildir.

Persistence `Text` alanı API canonical `content` alanına map edilir; wire-formatta `text` alanı oluşturulmaz.

## 2. Users

Tablo: `Users`

Alanlar:

- `Id`: integer, PK
- `Username`: string, required
- `NormalizedUsername`: string, required
- `Email`: string, required
- `NormalizedEmail`: string, required
- `PasswordHash`: string, required
- `Role`: string, required
- `CreatedAt`: UTC timestamp

Constraint:

- `NormalizedUsername` unique
- `NormalizedEmail` unique

## 3. Follows

Tablo: `Follows`

Alanlar:

- `FollowerId`: FK → `Users.Id`
- `FollowingId`: FK → `Users.Id`
- `CreatedAt`: UTC timestamp

Unique:

`(FollowerId, FollowingId)`

Kurallar:

- self-follow yasak
- duplicate aktif follow yasak
- retry/double-tap ikinci aktif row üretmez

## 4. Posts

Tablo: `Posts`

Alanlar:

- `Id`: integer, PK
- `AuthorId`: FK → `Users.Id`
- `Text`: string, required
- `Kind`: string, required
- `OriginalPostId`: nullable FK → `Posts.Id`
- `CreatedAt`: UTC timestamp

`Text` persistence alanı API canonical `content` alanına map edilir.

Maksimum post içeriği 280 karakterdir.

`Kind` canonical değerleri:

- `Post`
- `Repost`
- `Quote`

### Normal Post

- `Kind = Post`
- `OriginalPostId = null`

### Repost

- `Kind = Repost`
- `OriginalPostId` required
- aynı author + original post için tek aktif repost

Database invariant:

`Kind = Repost` kayıtlarında `(AuthorId, OriginalPostId)` unique olmalıdır.

Bu kural retry/double-tap sonucunda duplicate aktif repost oluşmasını engeller.

### Quote

- `Kind = Quote`
- `OriginalPostId` required
- `Text` quote sahibinin içeriğidir ve API'de `content` olarak yayınlanır
- Quote ayrı Post resource create işlemidir
- aynı author aynı original postu birden fazla ayrı quote ile paylaşabilir
- Repost `(AuthorId, OriginalPostId)` uniqueness kuralı Quote kayıtlarına uygulanmaz

## 5. Replies

Tablo: `Replies`

Alanlar:

- `Id`: integer, PK
- `PostId`: FK → `Posts.Id`
- `AuthorId`: FK → `Users.Id`
- `Text`: string, required
- `CreatedAt`: UTC timestamp

`Replies.Text` API canonical `content` alanına map edilir.

Tek seviyeli reply kullanılır.

Reply-to-reply parent ilişkisi bu fazda yoktur.

## 6. PostLikes

Tablo: `PostLikes`

Alanlar:

- `PostId`: FK → `Posts.Id`
- `UserId`: FK → `Users.Id`
- `CreatedAt`: UTC timestamp

Unique:

`(PostId, UserId)`

Retry/double-tap ikinci aktif like oluşturmaz.

## 7. Bookmarks

Tablo: `Bookmarks`

Alanlar:

- `UserId`: FK → `Users.Id`
- `PostId`: FK → `Posts.Id`
- `CreatedAt`: UTC timestamp

Unique:

`(UserId, PostId)`

Kurallar:

- bookmark kullanıcıya özeldir
- duplicate aktif bookmark yoktur
- retry/double-tap ikinci aktif bookmark oluşturmaz
- başka kullanıcı bookmark'ı silinemez

## 8. Notifications

Tablo: `Notifications`

Alanlar:

- `Id`: integer, PK
- `RecipientUserId`: FK → `Users.Id`
- `ActorUserId`: FK → `Users.Id`
- `Type`: string, required
- `PostId`: nullable FK → `Posts.Id`
- `SourceKey`: string, required
- `IsRead`: boolean, required, default false
- `CreatedAt`: UTC timestamp

Canonical `Type`:

- `Like`
- `Reply`
- `Follow`
- `Mention`

action: update
Index:

- `(RecipientUserId, CreatedAt)`
- `(RecipientUserId, IsRead)`

Unique:

- `(RecipientUserId, SourceKey)`

Notification idempotency kuralı:

- aynı source interaction retry edildiğinde aynı recipient için ikinci
  notification row'u oluşturulmaz
- `SourceKey` source interaction için stable kimliktir

action: update
Canonical sosyal ilişki uniqueness/idempotency invariant'ları:

- Mention relation için `(PostId, MentionedUserId)` unique olmalıdır.
- Aynı post içinde aynı geçerli kullanıcı birden fazla kez mention edilse
  bile tek mention relation ve tek Mention notification oluşur.
- Bulunmayan veya geçersiz `@username` için mention relation ya da
  notification oluşturulmaz.
- Hashtag relation için `(PostId, HashtagId)` unique olmalıdır; aynı normalize
  hashtag aynı posta ikinci kez bağlanmaz.
- Hashtag persistence yalnız ilgili gönderilerin listelenmesini destekler;
  trend skoru, trend/ranking veya popularity modeli tanımlamaz.
- Post-media relation için `(PostId, MediaId)` unique olmalıdır; aynı media
  aynı posta ikinci kez bağlanmaz.
- Media ownership post veya quote ile bağlama öncesinde backend tarafından
  doğrulanır.
- Media binary PostgreSQL'de tutulmaz; PostgreSQL yalnız owner/object key,
  media type, content type, dimensions ve post ilişki metadata'sını tutar.
- Repost için yalnız `Kind = Repost` kayıtlarında
  `(AuthorId, OriginalPostId)` tek aktif relation olarak unique uygulanır;
  bu uniqueness `Quote` kayıtlarına uygulanmaz.
- `Bookmarks (UserId, PostId)`, `PostLikes (PostId, UserId)` ve
  `Follows (FollowerId, FollowingId)` mevcut unique invariant'larını korur;
  retry/double-tap ikinci aktif relation oluşturmaz.

Stable source identity örnekleri:

- Like: `like:{postId}:{actorUserId}`
- Follow: `follow:{actorUserId}:{recipientUserId}`
- Reply: `reply:{replyId}`
- Mention: `mention:{postId}:{mentionedUserId}`

Unique invariant:

`(RecipientUserId, Type, SourceKey)` unique.

Bu invariant:

- aynı source event retry edildiğinde duplicate notification oluşmasını engeller
- aynı post için farklı reply kaynaklarının ayrı Reply notification üretmesine izin verir
- duplicate mention event'inin ikinci Mention notification üretmesini engeller

Read/unread state update aynı notification satırını değiştirir.

Read/unread update yeni notification oluşturmaz.

## 9. Hashtags

Tablo: `Hashtags`

Alanlar:

- `Id`: integer, PK
- `Tag`: string
- `NormalizedTag`: string

Unique:

`NormalizedTag`

### PostHashtags

Alanlar:

- `PostId`: FK → `Posts.Id`
- `HashtagId`: FK → `Hashtags.Id`

Unique:

`(PostId, HashtagId)`

Kurallar:

- aynı post/tag duplicate relation oluşturmaz
- hashtag modeli trend skoru içermez
- popularity/ranking state'i tutulmaz

## 10. PostMentions

Tablo: `PostMentions`

Alanlar:

- `PostId`: FK → `Posts.Id`
- `MentionedUserId`: FK → `Users.Id`

Unique:

`(PostId, MentionedUserId)`

Kurallar:

- geçersiz/bulunmayan username için kayıt yok
- aynı postta aynı kullanıcı tekrar mention edilse tek relation vardır
- geçerli recipient author'dan farklıysa Mention notification üretilir
- notification duplicate engeli `Notifications.SourceKey` invariant'ıyla birlikte uygulanır

## 11. PostMedia

Tablo: `PostMedia`

Alanlar:

- `Id`: integer, PK
- `OwnerUserId`: FK → `Users.Id`
- `PostId`: nullable FK → `Posts.Id`
- `ObjectKey`: string, required
- `MediaType`: string, required
- `ContentType`: string, required
- `Width`: nullable integer
- `Height`: nullable integer
- `CreatedAt`: UTC timestamp

Canonical `MediaType`:

- `Image`
- `Video`

Unique:

`ObjectKey`

Kurallar:

- binary MinIO'dadır
- PostgreSQL yalnız metadata ve ilişki tutar
- upload authenticated `OwnerUserId` kullanıcısına aittir
- başka kullanıcının media id'si post/quote içine bağlanamaz
- `ObjectKey` aynı MinIO object'in duplicate metadata kaydını engeller
- storage credential API response'unda açığa çıkarılmaz

Tek görselli postta bir `PostMedia` kaydı ilgili `PostId` ile bağlanır ve API `media[]` alanında yayınlanır.

## 12. Blocks

Tablo: `Blocks`

Alanlar:

- `BlockerUserId`: FK → `Users.Id`
- `BlockedUserId`: FK → `Users.Id`
- `CreatedAt`: UTC timestamp

Unique:

`(BlockerUserId, BlockedUserId)`

Kurallar:

- self-block yasak
- duplicate aktif block yasak
- retry/double-tap ikinci aktif row üretmez
- block feed/profile sosyal görünürlüğüne backend tarafından uygulanır

## 13. Reports

Tablo: `Reports`

Alanlar:

- `Id`: integer, PK
- `ReporterUserId`: FK → `Users.Id`
- `ReportedUserId`: nullable FK → `Users.Id`
- `PostId`: nullable FK → `Posts.Id`
- `Reason`: string
- `Status`: string
- `CreatedAt`: UTC timestamp
- `ResolvedAt`: nullable UTC timestamp

Canonical report reason/status wire token'ları yalnız `docs/api-contract.md` tarafından belirlenir.

Database katmanı alternatif public enum string üretmez.

## 14. Türetilmiş PostResponse alanları

API `PostResponse` alanlarının veri kaynakları:

- `id` → `Posts.Id`
- `content` → `Posts.Text`
- `author` → `Users`
- `likeCount` → `PostLikes`
- `replyCount` → `Replies`
- `repostCount` → `Posts` where `Kind = Repost` ve ilgili `OriginalPostId`
- `isLikedByMe` → current user + `PostLikes`
- `isBookmarked` → current user + `Bookmarks`
- `parentPostId` → reply/post ilişkisindeki parent bilgi
- `kind` → `Posts.Kind`
- `originalPost` → `Posts.OriginalPostId`
- `media` → `PostMedia`

Physical counter kolonları eklenmesi ayrı performans kararıdır ve API kontratını değiştirmez.

## 15. Referential integrity

Post/account deletion sırasında en az şu ilişkiler değerlendirilir:

- follows
- likes
- replies
- bookmarks
- notifications
- hashtags
- mentions
- media
- blocks
- reports
- repost references
- quote references

Cascade yalnız business semantics ile uyumluysa kullanılır.

Ownership kontrolü backend için zorunludur.

Başka kullanıcıya ait relation veya resource yanlışlıkla silinemez.

## 16. Index ve uniqueness özeti

| İlişki | Kural |
|---|---|
| User username | `NormalizedUsername` unique |
| User email | `NormalizedEmail` unique |
| Follow | `(FollowerId, FollowingId)` unique |
| Like | `(PostId, UserId)` unique |
| Bookmark | `(UserId, PostId)` unique |
| Repost | `Kind=Repost` için `(AuthorId, OriginalPostId)` unique |
| Quote | ayrı Post resource; repost unique constraint'i uygulanmaz |
| PostHashtag | `(PostId, HashtagId)` unique |
| Mention | `(PostId, MentionedUserId)` unique |
| Notification source | `(RecipientUserId, Type, SourceKey)` unique |
| Block | `(BlockerUserId, BlockedUserId)` unique |
| Media object | `ObjectKey` unique |

Ek index:

- `Posts(AuthorId, CreatedAt)`
- `Posts(OriginalPostId, Kind)`
- `Replies(PostId, CreatedAt)`
- `Bookmarks(UserId, CreatedAt)`
- `Notifications(RecipientUserId, CreatedAt)`
- `Notifications(RecipientUserId, IsRead)`

## 17. Idempotency invariant'ları

Create retry veya kullanıcı double-tap davranışı aşağıdaki toggle/relationship kaynaklarında duplicate aktif kayıt üretmemelidir:

- Follow
- Like
- Bookmark
- Repost
- PostHashtag
- PostMention
- Block

Mention aynı post içinde tekrarlandığında:

- tek `PostMentions` kaydı
- tek recipient Mention notification

oluşur.

Notification retry güvenliği stable `SourceKey` ve `(RecipientUserId, Type, SourceKey)` uniqueness ile sağlanır.

`IsRead` true→false veya false→true update aynı notification satırını değiştirir; yeni row oluşturmaz.

Quote toggle değildir.

Her başarılı quote create yeni `Posts.Id` üreten ayrı Post resource'dur.

Bu nedenle aynı author/original çiftinin birden fazla ayrı quote resource oluşturması geçerlidir.

## 18. Altyapı

PostgreSQL:

- relational application state
- EF Core migration target

MinIO:

- image/video binary

Redis:

- bu faz için zorunlu değildir

`docker-compose.yml` Infra Agent tarafından üretilir.

Architect yalnız servis gereksinimini tanımlar.

## 19. Acceptance veri modeli kanıtı

Canonical veri modeli aşağıdaki Sosyal Etkileşim Fazı acceptance maddelerini karşılar:

- repost: `Posts.Kind + OriginalPostId` ve filtered uniqueness
- quote: `Posts.Kind + OriginalPostId`, ayrı resource create
- bookmark: `(UserId, PostId)` unique
- notifications: canonical type + persistent read state + stable source idempotency
- mention: yalnız valid user FK relation, duplicate relation engeli
- hashtag: normalized tag ve unique post/tag relation, trend state yok
- media: owner + post relation + unique object key + MinIO binary
- text-only backward compatibility: persistence `Text` → API `content`, maksimum 280 karakter