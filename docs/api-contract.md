# Pulse API Sözleşmesi

## 1. Amaç

Bu doküman Pulse backend ile Flutter mobil/web istemcisi arasındaki tek HTTP ve JSON sözleşmesidir.

Backend DTO'ları, integration test gövdeleri ve mobil modeller bu dokümandaki alan adlarıyla birebir uyumlu olmalıdır.

## 2. Genel kurallar

- API taban yolu: `/api/v1`
- Sağlık endpoint'i: `/health`
- JSON alanları: camelCase
- Kimlikler: integer
- Tarih-zaman: UTC ISO 8601
- Korumalı kaynaklar: `Authorization: Bearer <token>`
- Gönderi metni alanı: `content`
- Gönderi maksimum uzunluğu: 280 karakter
- Mobil backend alanlarını yeniden adlandırmaz.
- Bu dokümanda olmayan alternatif alanlar kullanılmaz.

Geçersiz gönderi alanları:

- `description`
- `title`
- `text`
- `body`

Geçersiz kimlik biçimi:

```json
{
  "id": "225ebeca-5e61-4327-83d3-c8ffc6d29410"
}
```

Geçerli kimlik biçimi:

```
{
  "id": 1
}
```

3. Yerel adresler ve CORS

Flutter web:

```
http://127.0.0.1:8080
```

Backend API:

```
http://127.0.0.1:5000
```

Backend aşağıdakileri desteklemelidir:

```
Origin: http://127.0.0.1:8080
Header: Authorization
Header: Content-Type
Method: GET
Method: POST
Method: PUT
Method: DELETE
Method: OPTIONS
```

Tarayıcı OPTIONS preflight istekleri başarılı cevaplanmalıdır.

4. JWT yapılandırması

Orchestrator başlangıcı:

```
dotnet run --no-launch-profile
ASPNETCORE_ENVIRONMENT=Development
```

Development ayarları:

```
{
  "Jwt": {
    "Key": "development-only-key-at-least-32-bytes",
    "Issuer": "Pulse.Api",
    "Audience": "Pulse.Client"
  }
}
```

Kurallar:

Jwt:Key en az 32 byte olmalıdır.

Development ortamı production secret eksikliği nedeniyle çökmemelidir.

Production anahtarı environment variable veya secret store üzerinden sağlanmalıdır.

Production secret repoda bulunmamalıdır.

Anonim endpoint'ler:

```
GET /health
POST /api/v1/auth/register
POST /api/v1/auth/login
```

Diğer endpoint'ler Bearer token gerektirir.

/api/v1/moderation/** endpoint'leri ayrıca Moderator rolü gerektirir.

5. Ortak HTTP kuralları

5.1 JSON Content-Type

```
Content-Type: application/json
```

5.2 Authorization

```
Authorization: Bearer <accessToken>
```

5.3 Hata response'u

```
{
  "error": "Açıklayıcı hata mesajı.",
  "field": null
}
```

Belirli alan hatası:

```
{
  "error": "Content must not exceed 280 characters.",
  "field": "content"
}
```

Standart durum kodları:

KodAnlam
400Validation, geçersiz JSON veya iş kuralı
401Token yok, geçersiz veya süresi dolmuş
403Kaynak sahipliği veya yetki hatası
404Path ile seçilen kaynak bulunamadı veya güvenlik nedeniyle görünmez
409Benzersizlik veya durum/ilişki çakışması
500Beklenmeyen sunucu hatası

Geçersiz JSON:

```
{
  "error": "Request body contains invalid JSON.",
  "field": null
}
```

6. Canonical endpoint matrisi

ModülHTTPPathAuthBaşarı
HealthGET/healthAnonim200
AuthPOST/api/v1/auth/registerAnonim201
AuthPOST/api/v1/auth/loginAnonim200
ProfileGET/api/v1/meBearer200
ProfilePUT/api/v1/meBearer200
ProfileGET/api/v1/profiles/{username}Bearer200
FollowPOST/api/v1/profiles/{username}/followBearer200
FollowDELETE/api/v1/profiles/{username}/followBearer200
FeedGET/api/v1/feedBearer200
PostsPOST/api/v1/postsBearer201
PostsDELETE/api/v1/posts/{postId}Bearer204
RepliesPOST/api/v1/posts/{postId}/repliesBearer201
LikesPOST/api/v1/posts/{postId}/likesBearer200
LikesDELETE/api/v1/posts/{postId}/likesBearer200
BlocksPOST/api/v1/profiles/{username}/blockBearer200
BlocksDELETE/api/v1/profiles/{username}/blockBearer204
BlocksGET/api/v1/blocksBearer200
ReportsPOST/api/v1/reportsBearer201
ModerationGET/api/v1/moderation/reportsModerator200
ModerationGET/api/v1/moderation/reports/{reportId}Moderator200
ModerationPOST/api/v1/moderation/reports/{reportId}/resolveModerator200
ModerationPOST/api/v1/moderation/reports/{reportId}/dismissModerator200

Moderator, geçerli Bearer token ile birlikte Moderator rolünün zorunlu olduğunu ifade eder.

7. Yasak legacy yollar

Aşağıdaki yollar backend tarafından map edilmemelidir:

```
/register
/login
/me
/feed
/posts
/profiles/{username}
/api/v1/auth/me
/api/v1/users/{username}
/api/v1/users/me
/api/v1/users/{username}/follow
```

Mobil repository bu yolları fallback olarak kullanmamalıdır.

Aynı davranış için birden fazla route tanımlanması yasaktır.

8. Health

GET /health

Auth: Anonim

İstek gövdesi: Yok

Başarı:

```
200 OK
```

Yanıt:

```
{
  "status": "ok"
}
```

Response kesin olarak küçük harfli status alanını ve "ok" değerini içermelidir.

9. Paylaşılan tipler

9.1 AuthUserResponse

```
{
  "id": 1,
  "username": "ilkan",
  "displayName": "İlkan",
  "avatarUrl": null
}
```

AlanTürNull
idintegerHayır
usernamestringHayır
displayNamestringHayır
avatarUrlstringEvet

9.2 AuthResponse

```
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 1,
    "username": "ilkan",
    "displayName": "İlkan",
    "avatarUrl": null
  }
}
```

AlanTürNull
accessTokenstringHayır
tokenTypestringHayır
expiresInintegerHayır
userAuthUserResponseHayır

tokenType:

```
Bearer
```

9.3 AuthorResponse

```
{
  "id": 2,
  "username": "ada",
  "displayName": "Ada",
  "avatarUrl": null
}
```

AlanTürNull
idintegerHayır
usernamestringHayır
displayNamestringHayır
avatarUrlstringEvet

9.4 PostResponse

```
{
  "id": 15,
  "author": {
    "id": 2,
    "username": "ada",
    "displayName": "Ada",
    "avatarUrl": null
  },
  "content": "Merhaba Pulse.",
  "parentPostId": null,
  "createdAt": "2026-08-08T12:00:00Z",
  "likeCount": 4,
  "replyCount": 1,
  "isLikedByMe": false
}
```

AlanTürNull
idintegerHayır
authorAuthorResponseHayır
contentstringHayır
parentPostIdintegerEvet
createdAtUTC ISO 8601 stringHayır
likeCountintegerHayır
replyCountintegerHayır
isLikedByMebooleanHayır

9.5 ReportTargetType

Tam string değerleri:

```
Post
User
```

Başka casing veya alias kullanılmaz.

9.6 ReportReason

Tam string değerleri:

```
Spam
Harassment
HateSpeech
Violence
SexualContent
Impersonation
Other
```

9.7 ReportStatus

Tam string değerleri:

```
Pending
Resolved
Dismissed
```

9.8 ModerationAction

Tam string değerleri:

```
NoAction
RemovePost
```

10. Auth

10.1 POST /api/v1/auth/register

Auth: Anonim

Create semantiği:

Gövdede kullanıcı kimliği bulunmaz.

Backend yeni integer id üretir.

İstek gövdesi:

AlanTürZorunlu
usernamestringEvet
displayNamestringEvet
passwordstringEvet

Golden request:

```
{
  "username": "ilkan",
  "displayName": "İlkan",
  "password": "ExamplePassword123!"
}
```

Başarı:

```
201 Created
```

Golden response:

```
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 1,
    "username": "ilkan",
    "displayName": "İlkan",
    "avatarUrl": null
  }
}
```

Username benzersizlik çakışması:

```
409 Conflict
```

10.2 POST /api/v1/auth/login

Auth: Anonim

İstek gövdesi:

AlanTürZorunlu
usernamestringEvet
passwordstringEvet

Golden request:

```
{
  "username": "ilkan",
  "password": "ExamplePassword123!"
}
```

Başarı:

```
200 OK
```

Golden response:

```
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 1,
    "username": "ilkan",
    "displayName": "İlkan",
    "avatarUrl": null
  }
}
```

Geçersiz credential:

```
401 Unauthorized
```

11. Profile

11.1 GET /api/v1/me

Auth: Bearer

İstek gövdesi: Yok

Başarı:

```
200 OK
```

Golden response:

```
{
  "id": 1,
  "username": "ilkan",
  "displayName": "İlkan",
  "bio": null,
  "avatarUrl": null,
  "followerCount": 10,
  "followingCount": 4,
  "isFollowing": false
}
```

AlanTürNull
idintegerHayır
usernamestringHayır
displayNamestringHayır
biostringEvet
avatarUrlstringEvet
followerCountintegerHayır
followingCountintegerHayır
isFollowingbooleanHayır

11.2 PUT /api/v1/me

Auth: Bearer

Update semantiği:

Oturum sahibi güncellenir.

Gövdede id bulunmaz.

Gövdede username bulunmaz.

İstek alanları:

AlanTürZorunluNull
displayNamestringEvetHayır
biostringEvetEvet
avatarUrlstringEvetEvet

Golden request:

```
{
  "displayName": "İlkan Kişi",
  "bio": "Pulse kullanıcısı",
  "avatarUrl": null
}
```

Başarı:

```
200 OK
```

Golden response:

```
{
  "id": 1,
  "username": "ilkan",
  "displayName": "İlkan Kişi",
  "bio": "Pulse kullanıcısı",
  "avatarUrl": null,
  "followerCount": 10,
  "followingCount": 4,
  "isFollowing": false
}
```

11.3 GET /api/v1/profiles/{username}

Auth: Bearer

İstek gövdesi: Yok

Başarı:

```
200 OK
```

Golden response:

```
{
  "id": 2,
  "username": "ada",
  "displayName": "Ada",
  "bio": null,
  "avatarUrl": null,
  "followerCount": 20,
  "followingCount": 8,
  "isFollowing": true
}
```

Kullanıcı bulunamazsa:

```
404 Not Found
```

Oturum sahibi ile hedef arasında block ilişkisi nedeniyle profil görünmezse:

```
404 Not Found
```

Response block ilişkisinin varlığını ayrıca açıklamaz.

12. Follows

12.1 POST /api/v1/profiles/{username}/follow

Auth: Bearer

Create semantiği:

Hedef path içindeki username ile belirlenir.

İstek gövdesi yoktur.

Golden request:

```
POST /api/v1/profiles/ada/follow
Authorization: Bearer <accessToken>
```

Başarı:

```
200 OK
```

Golden response:

```
{
  "username": "ada",
  "isFollowing": true
}
```

Kullanıcı bulunamazsa:

```
404 Not Found
```

Block ilişkisi varsa:

```
404 Not Found
```

12.2 DELETE /api/v1/profiles/{username}/follow

Auth: Bearer

İstek gövdesi: Yok

Başarı:

```
200 OK
```

Golden response:

```
{
  "username": "ada",
  "isFollowing": false
}
```

13. Feed

13.1 GET /api/v1/feed

Auth: Bearer

İstek gövdesi: Yok

Başarı:

```
200 OK
```

Golden response:

```
{
  "items": [
    {
      "id": 15,
      "author": {
        "id": 2,
        "username": "ada",
        "displayName": "Ada",
        "avatarUrl": null
      },
      "content": "Merhaba Pulse.",
      "parentPostId": null,
      "createdAt": "2026-08-08T12:00:00Z",
      "likeCount": 4,
      "replyCount": 1,
      "isLikedByMe": false
    }
  ]
}
```

Boş feed:

```
{
  "items": []
}
```

Boş feed 404 değildir.

Feed:

kronolojik olarak createdAt DESC sıralanır,

soft-delete postları içermez,

block ilişkisi bulunan kullanıcıların postlarını içermez.

14. Posts

14.1 POST /api/v1/posts

Auth: Bearer

Create semantiği:

Gövdede id yoktur.

Author id gövdeden alınmaz; token üzerinden belirlenir.

İstek alanları:

AlanTürZorunlu
contentstringEvet

Golden request:

```
{
  "content": "Merhaba Pulse."
}
```

Geçersiz request:

```
{
  "title": "Merhaba Pulse."
}
```

Başarı:

```
201 Created
```

Golden response:

```
{
  "id": 15,
  "author": {
    "id": 1,
    "username": "ilkan",
    "displayName": "İlkan",
    "avatarUrl": null
  },
  "content": "Merhaba Pulse.",
  "parentPostId": null,
  "createdAt": "2026-08-08T12:00:00Z",
  "likeCount": 0,
  "replyCount": 0,
  "isLikedByMe": false
}
```

Validation:

content boş olamaz.

content 280 karakteri aşamaz.

14.2 DELETE /api/v1/posts/{postId}

Auth: Bearer

İstek gövdesi: Yok

Yalnızca gönderi sahibi kendi gönderisini silebilir.

Başarı:

```
204 No Content
```

Post bulunamazsa:

```
404 Not Found
```

Başkasının postunu silme:

```
403 Forbidden
```

Bu endpoint standart kullanıcı sahiplik silmesidir.

Moderasyon kaldırması için bu endpoint kullanılmaz.

15. Replies

POST /api/v1/posts/{postId}/replies

Auth: Bearer

Create semantiği:

Parent post path içindeki postId ile belirlenir.

Gövdede id veya parentPostId bulunmaz.

İstek alanları:

AlanTürZorunlu
contentstringEvet

Golden request:

```
{
  "content": "Katılıyorum."
}
```

Başarı:

```
201 Created
```

Golden response:

```
{
  "id": 16,
  "author": {
    "id": 1,
    "username": "ilkan",
    "displayName": "İlkan",
    "avatarUrl": null
  },
  "content": "Katılıyorum.",
  "parentPostId": 15,
  "createdAt": "2026-08-08T12:05:00Z",
  "likeCount": 0,
  "replyCount": 0,
  "isLikedByMe": false
}
```

Kurallar:

content maksimum 280 karakter.

Parent bulunamazsa 404.

Soft-delete edilmiş parent için 404.

Block nedeniyle görünmeyen parent için 404.

16. Likes

16.1 POST /api/v1/posts/{postId}/likes

Auth: Bearer

İstek gövdesi: Yok

Başarı:

```
200 OK
```

Golden response:

```
{
  "postId": 15,
  "isLiked": true,
  "likeCount": 5
}
```

Post bulunamaz veya görünmezse:

```
404 Not Found
```

Aynı kullanıcının tekrar like isteği idempotenttir.

16.2 DELETE /api/v1/posts/{postId}/likes

Auth: Bearer

İstek gövdesi: Yok

Başarı:

```
200 OK
```

Golden response:

```
{
  "postId": 15,
  "isLiked": false,
  "likeCount": 4
}
```

Like bulunmasa da işlem idempotent olarak başarılı kabul edilir.

17. Blocks

17.1 POST /api/v1/profiles/{username}/block

Auth: Bearer

Create semantiği:

Hedef path içindeki username ile belirlenir.

İstek gövdesi yoktur.

Gövdede id veya username gönderilmez.

Golden request:

```
POST /api/v1/profiles/otheruser/block
Authorization: Bearer <accessToken>
```

Başarı:

```
200 OK
```

Golden response:

```
{
  "username": "otheruser",
  "isBlocked": true
}
```

Yanıt alanları:

AlanTürZorunluNull
usernamestringEvetHayır
isBlockedbooleanEvetHayır

Kurallar:

Kullanıcı kendisini engellerse 400.

Hedef kullanıcı bulunamazsa 404.

Aynı block tekrar oluşturulursa ikinci kayıt açılmaz.

Tekrarlanan create yine 200 döndürür.

Block oluşturulduğunda iki kullanıcı arasındaki mevcut follow ilişkileri kaldırılır.

17.2 DELETE /api/v1/profiles/{username}/block

Auth: Bearer

İstek gövdesi: Yok

Golden request:

```
DELETE /api/v1/profiles/otheruser/block
Authorization: Bearer <accessToken>
```

Başarı:

```
204 No Content
```

Yanıt gövdesi: Yok

Kurallar:

Block yoksa işlem idempotent olarak yine 204 döndürür.

Engelin kaldırılması eski follow ilişkilerini geri oluşturmaz.

17.3 GET /api/v1/blocks

Auth: Bearer

İstek gövdesi: Yok

Read semantiği:

Yalnızca oturum sahibinin engellediği kullanıcılar döndürülür.

Başarı:

```
200 OK
```

Golden response:

```
{
  "items": [
    {
      "id": 22,
      "username": "otheruser",
      "displayName": "Other User",
      "avatarUrl": null,
      "blockedAt": "2026-08-08T12:00:00Z"
    }
  ]
}
```

Yanıt alanları:

AlanTürZorunluNull
itemsarrayEvetHayır
items[].idintegerEvetHayır
items[].usernamestringEvetHayır
items[].displayNamestringEvetHayır
items[].avatarUrlstringEvetEvet
items[].blockedAtUTC ISO 8601 stringEvetHayır

Empty state:

```
{
  "items": []
}
```

Kayıt yokken 404 kullanılmaz.

18. Reports

18.1 POST /api/v1/reports

Auth: Bearer

Create semantiği:

Gövdede report id bulunmaz.

Reporter kimliği token üzerinden belirlenir.

Hedef targetType ve targetId ile belirlenir.

İstek alanları:

AlanTürZorunluNull
targetTypeReportTargetTypeEvetHayır
targetIdintegerEvetHayır
reasonReportReasonEvetHayır
detailsstringHayırEvet

details maksimum 500 karakterdir.

Golden post-report request:

```
{
  "targetType": "Post",
  "targetId": 15,
  "reason": "Harassment",
  "details": "Repeated targeted insults."
}
```

Golden user-report request:

```
{
  "targetType": "User",
  "targetId": 22,
  "reason": "Impersonation",
  "details": null
}
```

Alternatif request alanları geçersizdir:

```
postId
userId
reportType
categoryCode
targetIdentifier
```

Başarı:

```
201 Created
```

Golden response:

```
{
  "id": 41,
  "targetType": "Post",
  "targetId": 15,
  "reason": "Harassment",
  "details": "Repeated targeted insults.",
  "status": "Pending",
  "createdAt": "2026-08-08T12:15:00Z"
}
```

Yanıt alanları:

AlanTürZorunluNull
idintegerEvetHayır
targetTypeReportTargetTypeEvetHayır
targetIdintegerEvetHayır
reasonReportReasonEvetHayır
detailsstringEvetEvet
statusReportStatusEvetHayır
createdAtUTC ISO 8601 stringEvetHayır

HTTP semantiği:

Target bulunamazsa 404.

Kullanıcı kendi hesabını şikâyet ederse 400.

Kullanıcı kendi postunu şikâyet ederse 400.

Aynı reporter ve target için Pending report varsa 409.

Geçersiz enum 400.

details 500 karakteri aşarsa 400.

Report oluşturulması hedefi otomatik kaldırmaz.

19. Moderation

Tüm endpoint'ler:

```
Authorization: Bearer <accessToken>
```

ve Moderator rolü gerektirir.

Normal User rolü:

```
403 Forbidden
```

19.1 GET /api/v1/moderation/reports

Auth: Moderator

İstek gövdesi: Yok

Opsiyonel query:

```
status=Pending
status=Resolved
status=Dismissed
```

Query verilmezse:

```
Pending
```

Başarı:

```
200 OK
```

Golden response:

```
{
  "items": [
    {
      "id": 41,
      "reporterUserId": 7,
      "targetType": "Post",
      "targetId": 15,
      "reason": "Harassment",
      "details": "Repeated targeted insults.",
      "status": "Pending",
      "createdAt": "2026-08-08T12:15:00Z",
      "resolvedAt": null,
      "resolvedByUserId": null
    }
  ]
}
```

Yanıt alanları:

AlanTürZorunluNull
itemsarrayEvetHayır
items[].idintegerEvetHayır
items[].reporterUserIdintegerEvetHayır
items[].targetTypeReportTargetTypeEvetHayır
items[].targetIdintegerEvetHayır
items[].reasonReportReasonEvetHayır
items[].detailsstringEvetEvet
items[].statusReportStatusEvetHayır
items[].createdAtUTC ISO 8601 stringEvetHayır
items[].resolvedAtUTC ISO 8601 stringEvetEvet
items[].resolvedByUserIdintegerEvetEvet

Empty state:

```
{
  "items": []
}
```

Boş kuyruk 404 değildir.

19.2 GET /api/v1/moderation/reports/{reportId}

Auth: Moderator

İstek gövdesi: Yok

Başarı:

```
200 OK
```

Golden response:

```
{
  "id": 41,
  "reporterUserId": 7,
  "targetType": "Post",
  "targetId": 15,
  "reason": "Harassment",
  "details": "Repeated targeted insults.",
  "status": "Pending",
  "createdAt": "2026-08-08T12:15:00Z",
  "resolvedAt": null,
  "resolvedByUserId": null
}
```

Report bulunamazsa:

```
404 Not Found
```

19.3 POST /api/v1/moderation/reports/{reportId}/resolve

Auth: Moderator

Update semantiği:

Report path içindeki reportId ile belirlenir.

Gövdede report id bulunmaz.

İstek alanları:

AlanTürZorunluNull
actionModerationActionEvetHayır
notestringHayırEvet

note maksimum 500 karakterdir.

Golden RemovePost request:

```
{
  "action": "RemovePost",
  "note": "Content violates harassment policy."
}
```

Golden NoAction request:

```
{
  "action": "NoAction",
  "note": null
}
```

Başarı:

```
200 OK
```

Golden response:

```
{
  "id": 41,
  "status": "Resolved",
  "action": "RemovePost",
  "resolvedAt": "2026-08-08T12:30:00Z",
  "resolvedByUserId": 3
}
```

Yanıt alanları:

AlanTürZorunluNull
idintegerEvetHayır
statusReportStatusEvetHayır
actionModerationActionEvetHayır
resolvedAtUTC ISO 8601 stringEvetHayır
resolvedByUserIdintegerEvetHayır

Kurallar:

Report bulunamazsa 404.

Report Pending değilse 409.

RemovePost yalnızca targetType=Post için geçerlidir.

RemovePost bir User report için kullanılırsa 400.

RemovePost fiziksel DELETE yapmaz.

NoAction target kaynağı değiştirmez.

Başarılı işlem audit kaydı oluşturur.

19.4 POST /api/v1/moderation/reports/{reportId}/dismiss

Auth: Moderator

Update semantiği:

Report path içindeki reportId ile belirlenir.

Gövdede id bulunmaz.

İstek alanları:

AlanTürZorunluNull
notestringHayırEvet

note maksimum 500 karakterdir.

Golden request:

```
{
  "note": "No policy violation found."
}
```

Başarı:

```
200 OK
```

Golden response:

```
{
  "id": 41,
  "status": "Dismissed",
  "resolvedAt": "2026-08-08T12:35:00Z",
  "resolvedByUserId": 3
}
```

Yanıt alanları:

AlanTürZorunluNull
idintegerEvetHayır
statusReportStatusEvetHayır
resolvedAtUTC ISO 8601 stringEvetHayır
resolvedByUserIdintegerEvetHayır

Kurallar:

Report bulunamazsa 404.

Report Pending değilse 409.

Dismiss target kaynağını değiştirmez.

Başarılı işlem audit kaydı oluşturur.

20. Block görünürlük semantiği

Block ilişkisi aşağıdaki mevcut kaynaklarda server-side uygulanır:

```
GET /api/v1/feed
GET /api/v1/profiles/{username}
POST /api/v1/profiles/{username}/follow
POST /api/v1/posts/{postId}/likes
POST /api/v1/posts/{postId}/replies
```

Kurallar:

Engelli hesapların postları feed'den filtrelenir.

İki kullanıcı arasında block varsa yeni follow oluşturulamaz.

Block nedeniyle görünmeyen profile erişim 404 döndürür.

Block nedeniyle görünmeyen post üzerinde like/reply 404 döndürür.

Response block ilişkisinin varlığını ayrıca açıklamaz.

Block oluşturulduğunda iki yöndeki mevcut follow ilişkileri kaldırılır.

Unblock eski follow ilişkisini geri getirmez.

21. Moderasyon ile kaldırılmış gönderi semantiği

RemovePost sonucunda soft-delete edilmiş post:

feed'de dönmez,

normal görünür post kabul edilmez,

yeni like kabul etmez,

yeni reply kabul etmez.

Görünmeyen soft-delete post için ilişkili kaynak işlemleri:

```
404 Not Found
```

Mobil istemci moderasyon kaldırması için:

```
DELETE /api/v1/posts/{postId}
```

endpoint'ini kullanmaz.

Standart DELETE endpoint'inin gönderi sahipliği semantiği değişmez.

22. HTTP Create / Update / Read kuralları

Create

Yeni kaynak create işlemi:

```
POST /collection
```

Gövdede server tarafından üretilecek kaynak kimliği bulunmaz.

Bu kural:

register,

posts,

replies,

block,

reports

create akışları için geçerlidir.

Update

Mevcut kaynağın güncellenmesi canonical path üzerinden yapılır.

Örnek:

```
PUT /api/v1/me
```

Moderasyon state transition işlemleri action endpoint'leri üzerinden gerçekleştirilir:

```
POST /api/v1/moderation/reports/{reportId}/resolve
POST /api/v1/moderation/reports/{reportId}/dismiss
```

Request body içinde path kimliği tekrar edilmez.

Read

Tek kaynağın path ile seçildiği GET endpoint'lerinde kayıt bulunamazsa:

```
404 Not Found
```

Collection endpoint'lerinde kayıt olmaması:

```
200 OK
```

ve boş collection döndürür.

Örnek:

```
{
  "items": []
}
```

Bu davranış özellikle:

```
GET /api/v1/feed
GET /api/v1/blocks
GET /api/v1/moderation/reports
```

için empty state anlamına gelir.

23. Golden sample kuralı

Backend integration testindeki PostAsJsonAsync ve PutAsJsonAsync request gövdeleri bu dokümandaki golden JSON ile aynı alan adlarını kullanmalıdır.

Özellikle:

Post:

```
{
  "content": "Merhaba Pulse."
}
```

Reply:

```
{
  "content": "Katılıyorum."
}
```

Profile update:

```
{
  "displayName": "İlkan Kişi",
  "bio": "Pulse kullanıcısı",
  "avatarUrl": null
}
```

Report:

```
{
  "targetType": "Post",
  "targetId": 15,
  "reason": "Harassment",
  "details": "Repeated targeted insults."
}
```

Moderation resolve:

```
{
  "action": "RemovePost",
  "note": "Content violates harassment policy."
}
```

Mobil bu alanların yerine alternatif property isimleri kullanamaz.

24. Enum casing kuralı

Enum string değerleri case-sensitive canonical değerler olarak değerlendirilir.

ReportTargetType:

```
Post
User
```

ReportReason:

```
Spam
Harassment
HateSpeech
Violence
SexualContent
Impersonation
Other
```

ReportStatus:

```
Pending
Resolved
Dismissed
```

ModerationAction:

```
NoAction
RemovePost
```

Aşağıdaki örnekler canonical değildir:

```
post
user
spam
harassment
pending
resolved
remove_post
removePost
```

25. Kimlik kararı

Güncel Pulse MVP kaynak kimlikleri integer'dır.

Backend:

```
int Id
```

Mobil:

```
final int id;
```

API:

```
{
  "id": 1
}
```

UUID string kullanılmaz.

26. Gönderi alan adları

Bir gönderinin canonical temel alanları:

```
id
author
content
parentPostId
createdAt
likeCount
replyCount
isLikedByMe
```

Kullanıcı tarafından oluşturulan metin alanı:

```
content
```

Geçersiz alternatifler:

```
title
description
text
body
```

Mobil UI bir gönderi başlığı benzeri görsel öğe üretse bile backend request/response alanını title olarak değiştirmez.

27. Güvenlik ve moderasyon hata örnekleri

Self-block:

```
{
  "error": "You cannot block yourself.",
  "field": null
}
```

Duplicate pending report:

```
{
  "error": "A pending report already exists for this target.",
  "field": null
}
```

Geçersiz report reason:

```
{
  "error": "Invalid report reason.",
  "field": "reason"
}
```

Geçersiz moderation action:

```
{
  "error": "Invalid moderation action.",
  "field": "action"
}
```

Moderator rolü yok:

```
{
  "error": "You are not authorized to perform this action.",
  "field": null
}
```

Daha önce sonuçlandırılmış report:

```
{
  "error": "The report has already been resolved.",
  "field": null
}
```

28. Authorization özeti

Anonim:

```
GET /health
POST /api/v1/auth/register
POST /api/v1/auth/login
```

Bearer:

```
GET /api/v1/me
PUT /api/v1/me
GET /api/v1/profiles/{username}
POST /api/v1/profiles/{username}/follow
DELETE /api/v1/profiles/{username}/follow
GET /api/v1/feed
POST /api/v1/posts
DELETE /api/v1/posts/{postId}
POST /api/v1/posts/{postId}/replies
POST /api/v1/posts/{postId}/likes
DELETE /api/v1/posts/{postId}/likes
POST /api/v1/profiles/{username}/block
DELETE /api/v1/profiles/{username}/block
GET /api/v1/blocks
POST /api/v1/reports
```

Bearer + Moderator:

```
GET /api/v1/moderation/reports
GET /api/v1/moderation/reports/{reportId}
POST /api/v1/moderation/reports/{reportId}/resolve
POST /api/v1/moderation/reports/{reportId}/dismiss
```

29. Tek kaynak kuralı

Bu doküman backend ve mobil arasında API sözleşmesinin tek kaynağıdır.

Backend DTO alanı ile mobil model alanı farklı isim kullanamaz.

Aynı davranış için ikinci route tanımlanamaz.

Legacy fallback kullanılamaz.

Yeni modül eklendiğinde:

ayrı endpoint bölümü,

HTTP method + path,

auth,

request body alanları,

response body alanları,

enum listeleri,

golden request,

golden response,

HTTP semantiği,

empty-state/404 anlamı

bu dosyada açık şekilde tanımlanmadan implementasyona başlanmamalıdır.
