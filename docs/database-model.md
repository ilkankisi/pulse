# Pulse — Database Model

## 1. Amaç

Bu doküman Pulse canonical PostgreSQL veri modelini tanımlar.

API wire-format kaynağı `docs/api-contract.md` dosyasıdır.

İlkeler:

- primary key integer
- timestamp UTC
- foreign key ile referential integrity
- sosyal ilişkilerde duplicate engeli
- MinIO binary, PostgreSQL metadata
- ownership backend tarafından doğrulanır

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

## 4. Posts

Tablo: `Posts`

Alanlar:

- `Id`: integer, PK
- `AuthorId`: FK → `Users.Id`
- `Text`: string, required
- `Kind`: string, required
- `OriginalPostId`: nullable FK → `Posts.Id`
- `CreatedAt`: UTC timestamp

`Kind`:

- `Post`
- `Repost`
- `Quote`

Normal Post:

- `OriginalPostId = null`

Repost:

- `OriginalPostId` required
- aynı author + original post için tek aktif repost

Database invariant:

`Kind = Repost` kayıtlarında `(AuthorId, OriginalPostId)` unique olmalıdır.

Quote:

- `OriginalPostId` required
- `Text` quote sahibinin içeriğidir

Text maksimum uzunluğu API canonical kontratındaki 280 karakter kuralıyla uyumludur.

## 5. Replies

Tablo: `Replies`

Alanlar:

- `Id`: integer, PK
- `PostId`: FK → `Posts.Id`
- `AuthorId`: FK → `Users.Id`
- `Text`: string
- `CreatedAt`: UTC timestamp

Tek seviyeli reply kullanılır; reply-to-reply parent alanı yoktur.

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

- kullanıcıya özeldir
- duplicate aktif bookmark yoktur
- başka kullanıcı bookmark'ı silinemez

## 8. Notifications

Tablo: `Notifications`

Alanlar:

- `Id`: integer, PK
- `RecipientUserId`: FK → `Users.Id`
- `ActorUserId`: FK → `Users.Id`
- `Type`: string
- `PostId`: nullable FK → `Posts.Id`
- `IsRead`: boolean, default false
- `CreatedAt`: UTC timestamp

Canonical `Type`:

- `Like`
- `Reply`
- `Follow`
- `Mention`

Index:

- `(RecipientUserId, CreatedAt)`
- `(RecipientUserId, IsRead)`

Duplicate prevention:

Aynı source interaction aynı recipient için tekrar işlendiğinde ikinci notification üretilmez.

Mention source identity için:

`(RecipientUserId, ActorUserId, PostId, Type)`

kombinasyonu duplicate Mention notification'ı engellemelidir.

Read-state update yeni notification oluşturmaz.

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

Hashtag modeli trend skoru içermez.

## 10. PostMentions

Tablo: `PostMentions`

Alanlar:

- `PostId`: FK → `Posts.Id`
- `MentionedUserId`: FK → `Users.Id`

Unique:

`(PostId, MentionedUserId)`

Kurallar:

- geçersiz username için kayıt yok
- aynı postta aynı kullanıcı tekrar mention edilse tek kayıt
- geçerli recipient author'dan farklıysa tek Mention notification üretilebilir

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

`MediaType`:

- `Image`
- `Video`

Unique:

`ObjectKey`

Kurallar:

- binary MinIO'dadır
- PostgreSQL yalnız metadata tutar
- upload authenticated user'a aittir
- başka kullanıcının media id'si bağlanamaz
- storage credential API response'unda açığa çıkarılmaz

## 12. Blocks

Tablo: `Blocks`

Alanlar:

- `BlockerUserId`: FK → `Users.Id`
- `BlockedUserId`: FK → `Users.Id`
- `CreatedAt`: UTC timestamp

Unique:

`(BlockerUserId, BlockedUserId)`

Self-block yasaktır.

Block feed/profile sosyal görünürlüğüne backend tarafından uygulanır.

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

Report reason/status wire token'ları yalnız `docs/api-contract.md` tarafından belirlenir.

## 14. Türetilmiş PostResponse alanları

- `likeCount` → `PostLikes`
- `replyCount` → `Replies`
- `repostCount` → `Posts` where `Kind = Repost`
- `isLiked` → current user + `PostLikes`
- `isBookmarked` → current user + `Bookmarks`
- `originalPost` → `OriginalPostId`
- `media` → `PostMedia`

Physical counter eklenmesi ayrı performans kararıdır ve API kontratını değiştirmez.

## 15. Referential integrity

Post/account deletion sırasında en az:

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
- repost/quote references

değerlendirilir.

Cascade yalnız business semantics ile uyumluysa kullanılır.

Ownership kontrolü backend için zorunludur.

## 16. Index ve uniqueness özeti

| İlişki | Kural |
|---|---|
| User username | `NormalizedUsername` unique |
| User email | `NormalizedEmail` unique |
| Follow | `(FollowerId, FollowingId)` unique |
| Like | `(PostId, UserId)` unique |
| Bookmark | `(UserId, PostId)` unique |
| Repost | `Kind=Repost` için `(AuthorId, OriginalPostId)` unique |
| PostHashtag | `(PostId, HashtagId)` unique |
| Mention | `(PostId, MentionedUserId)` unique |
| Block | `(BlockerUserId, BlockedUserId)` unique |
| Media object | `ObjectKey` unique |

Ek index:

- `Posts(AuthorId, CreatedAt)`
- `Posts(OriginalPostId, Kind)`
- `Replies(PostId, CreatedAt)`
- `Bookmarks(UserId, CreatedAt)`
- `Notifications(RecipientUserId, CreatedAt)`

## 17. Idempotency invariant'ları

Create retry veya kullanıcı double-tap davranışı aşağıdaki ilişkilerde duplicate aktif kayıt üretmemelidir:

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

## 18. Altyapı

PostgreSQL:

- relational application state
- EF Core migration target

MinIO:

- image/video binary

Redis:

- bu fazda zorunlu değil

`docker-compose.yml` Infra Agent tarafından üretilir.