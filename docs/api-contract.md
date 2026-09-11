Pulse API Sözleşmesi

1. Amaç

Bu doküman Pulse backend ile Flutter mobil/web istemcisi arasındaki tek HTTP ve JSON sözleşmesidir.

Backend DTO'ları, integration test gövdeleri ve mobil modeller bu dokümandaki alan adlarıyla birebir uyumlu olmalıdır.

2. Genel kurallar

API taban yolu: /api/v1

Sağlık endpoint'i: /health

JSON alanları: camelCase

Kimlikler: integer

Tarih-zaman: UTC ISO 8601

Korumalı kaynaklar: Authorization: Bearer <token>

Gönderi metni alanı: content

Gönderi maksimum uzunluğu: 280 karakter

Mobil backend alanlarını yeniden adlandırmaz.

Bu dokümanda olmayan alternatif alanlar kullanılmaz.

Bir alt kaynak veya kullanıcı tarafından oluşturulan collection için mutation endpoint'i tanımlanıyorsa, aynı kaynağın kullanıcı tarafından yeniden okunabilmesini sağlayan canonical GET endpoint'i de sözleşmede bulunmalıdır.

Create sonrası yalnız sayaç/state güncellemesi read-after-write gereksinimini karşılamaz; persisted içerik canonical read endpoint'inden tekrar okunabilir olmalıdır.

Geçersiz gönderi alanları:

description

title

text

body

Geçersiz kimlik biçimi:

{
  "id": "225ebeca-5e61-4327-83d3-c8ffc6d29410"
}

Geçerli kimlik biçimi:

{
  "id": 1
}

3. Yerel adresler ve CORS

Flutter web:

http://127.0.0.1:8080

Backend API:

http://127.0.0.1:5000

Backend aşağıdakileri desteklemelidir:

Origin: http://127.0.0.1:8080
Header: Authorization
Header: Content-Type
Method: GET
Method: POST
Method: PUT
Method: DELETE
Method: OPTIONS

Tarayıcı OPTIONS preflight istekleri başarılı cevaplanmalıdır.

4. JWT yapılandırması

Orchestrator başlangıcı:

dotnet run --no-launch-profile
ASPNETCORE_ENVIRONMENT=Development

Development ayarları:

{
  "Jwt": {
    "Key": "development-only-key-at-least-32-bytes",
    "Issuer": "Pulse.Api",
    "Audience": "Pulse.Client"
  }
}

Kurallar:

Jwt:Key en az 32 byte olmalıdır.

Development ortamı production secret eksikliği nedeniyle çökmemelidir.

Production anahtarı environment variable veya secret store üzerinden sağlanmalıdır.

Production secret repoda bulunmamalıdır.

Anonim endpoint'ler:

GET /health
POST /api/v1/auth/register
POST /api/v1/auth/login

Diğer endpoint'ler Bearer token gerektirir.

/api/v1/moderation/** endpoint'leri ayrıca Moderator rolü gerektirir.

5. Ortak HTTP kuralları

5.1 JSON Content-Type

Content-Type: application/json

5.2 Authorization

Authorization: Bearer <accessToken>

5.3 Hata response'u

{
  "error": "Açıklayıcı hata mesajı.",
  "field": null
}

Belirli alan hatası:

{
  "error": "Content must not exceed 280 characters.",
  "field": "content"
}

Standart durum kodları:

KodAnlam
400Validation, geçersiz JSON veya iş kuralı
401Token yok, geçersiz veya süresi dolmuş
403Kaynak sahipliği veya yetki hatası
404Path ile seçilen kaynak bulunamadı veya güvenlik nedeniyle görünmez
409Benzersizlik veya durum/ilişki çakışması
500Beklenmeyen sunucu hatası

Geçersiz JSON:

{
  "error": "Request body contains invalid JSON.",
  "field": null
}

6. Canonical endpoint matrisi

ModülHTTPPathAuthBaşarı
HealthGET/healthAnonim200
AuthPOST/api/v1/auth/registerAnonim201
AuthPOST/api/v1/auth/loginAnonim200
ProfileGET/api/v1/meBearer200
ProfilePUT/api/v1/meBearer200
ProfileGET/api/v1/profiles/{username}Bearer200
ProfileGET/api/v1/profiles/{username}/postsBearer200
SocialGraphGET/api/v1/profiles/{username}/followersBearer200
SocialGraphGET/api/v1/profiles/{username}/followingBearer200
FollowPOST/api/v1/profiles/{username}/followBearer200
FollowDELETE/api/v1/profiles/{username}/followBearer200
FeedGET/api/v1/feedBearer200
PostsPOST/api/v1/postsBearer201
PostsDELETE/api/v1/posts/{postId}Bearer204
RepliesGET/api/v1/posts/{postId}/repliesBearer200
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

Mobil repository bu yolları fallback olarak kullanmamalıdır.

Aynı davranış için birden fazla route tanımlanması yasaktır.

8. Health

GET /health

Auth: Anonim

İstek gövdesi: Yok

Başarı:

200 OK

Yanıt:

{
  "status": "ok"
}

Response kesin olarak küçük harfli status alanını ve "ok" değerini içermelidir.

9. Paylaşılan tipler

9.1 AuthUserResponse

{
  "id": 1,
  "username": "ilkan",
  "displayName": "İlkan",
  "avatarUrl": null
}

AlanTürNull
idintegerHayır
usernamestringHayır
displayNamestringHayır
avatarUrlstringEvet

9.2 AuthResponse

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

AlanTürNull
accessTokenstringHayır
tokenTypestringHayır
expiresInintegerHayır
userAuthUserResponseHayır

tokenType değeri Bearer'dır.

9.3 AuthorResponse

{
  "id": 2,
  "username": "ada",
  "displayName": "Ada",
  "avatarUrl": null
}

AlanTürNull
idintegerHayır
usernamestringHayır
displayNamestringHayır
avatarUrlstringEvet

9.4 PostResponse

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

Tam canonical string değerleri:

Post

User

Başka casing veya alias kullanılmaz.

9.6 ReportReason

Tam canonical string değerleri:

Spam

Harassment

HateSpeech

Violence

SexualContent

Impersonation

Other

9.7 ReportStatus

Tam canonical string değerleri:

Pending

Resolved

Dismissed

9.8 ModerationAction

Tam canonical string değerleri:

NoAction

RemovePost

9.9 SocialGraphUserResponse

Followers ve following collection'ları aynı canonical liste öğesi tipini kullanır.

{
  "id": 3,
  "username": "deniz",
  "displayName": "Deniz",
  "avatarUrl": null,
  "isFollowedByCurrentUser": true
}

AlanTürNull
idintegerHayır
usernamestringHayır
displayNamestringHayır
avatarUrlstringEvet
isFollowedByCurrentUserbooleanHayır

isFollowedByCurrentUser, oturum sahibinin response'taki kullanıcıyı takip edip etmediğini belirtir.

Followers ve following için ikinci bir JSON alan seti tanımlanmaz.

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

{
  "username": "ilkan",
  "displayName": "İlkan",
  "password": "ExamplePassword123!"
}

Başarı:

201 Created

Golden response:

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

Username benzersizlik çakışması:

409 Conflict

10.2 POST /api/v1/auth/login

Auth: Anonim

İstek gövdesi:

AlanTürZorunlu
usernamestringEvet
passwordstringEvet

Golden request:

{
  "username": "ilkan",
  "password": "ExamplePassword123!"
}

Başarı:

200 OK

Golden response:

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

Geçersiz credential:

401 Unauthorized
11. Profile

11.1 GET /api/v1/me

Auth: Bearer

İstek gövdesi: Yok

Başarı:

200 OK

Golden response:

{
  "id": 1,
  "username": "ilkan",
  "displayName": "İlkan",
  "bio": null,
  "avatarUrl": null,
  "createdAt": "2026-08-01T10:00:00Z",
  "postCount": 12,
  "followerCount": 10,
  "followingCount": 4,
  "isFollowedByCurrentUser": false
}

AlanTürNull
idintegerHayır
usernamestringHayır
displayNamestringHayır
biostringEvet
avatarUrlstringEvet
createdAtUTC ISO 8601 stringHayır
postCountintegerHayır
followerCountintegerHayır
followingCountintegerHayır
isFollowedByCurrentUserbooleanHayır

Kendi profilinde isFollowedByCurrentUser değeri false olur; self-follow desteklenmez.

postCount yalnız görünür kök gönderileri sayar.

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

{
  "displayName": "İlkan Kişi",
  "bio": "Pulse kullanıcısı",
  "avatarUrl": null
}

Başarı:

200 OK

Golden response:

{
  "id": 1,
  "username": "ilkan",
  "displayName": "İlkan Kişi",
  "bio": "Pulse kullanıcısı",
  "avatarUrl": null,
  "createdAt": "2026-08-01T10:00:00Z",
  "postCount": 12,
  "followerCount": 10,
  "followingCount": 4,
  "isFollowedByCurrentUser": false
}

11.3 GET /api/v1/profiles/{username}

Auth: Bearer

İstek gövdesi: Yok

Başarı:

200 OK

Golden response:

{
  "id": 2,
  "username": "ada",
  "displayName": "Ada",
  "bio": null,
  "avatarUrl": null,
  "createdAt": "2026-07-20T09:00:00Z",
  "postCount": 8,
  "followerCount": 20,
  "followingCount": 8,
  "isFollowedByCurrentUser": true
}

Canonical profile response alanları:

AlanTürZorunluNull
idintegerEvetHayır
usernamestringEvetHayır
displayNamestringEvetHayır
biostringEvetEvet
avatarUrlstringEvetEvet
createdAtUTC ISO 8601 stringEvetHayır
postCountintegerEvetHayır
followerCountintegerEvetHayır
followingCountintegerEvetHayır
isFollowedByCurrentUserbooleanEvetHayır

Kullanıcı bulunamazsa:

404 Not Found

Oturum sahibi ile hedef arasında block ilişkisi nedeniyle profil görünmezse:

404 Not Found

Response block ilişkisinin varlığını ayrıca açıklamaz.

11.4 GET /api/v1/profiles/{username}/posts

Auth: Bearer

İstek gövdesi: Yok

Read semantiği:

Hedef profil path içindeki username ile belirlenir.

Yalnız hedef kullanıcıya ait kök gönderiler döndürülür.

Mevcut PostResponse şeması yeniden kullanılır.

Başarı:

200 OK

Golden response:

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
      "content": "Profilimdeki gönderi.",
      "parentPostId": null,
      "createdAt": "2026-08-08T12:00:00Z",
      "likeCount": 4,
      "replyCount": 1,
      "isLikedByMe": false
    }
  ]
}

Yanıt alanları:

AlanTürZorunluNull
itemsPostResponse arrayEvetHayır

Kurallar:

Sıralama createdAt DESC, eşitlikte id DESC olur.

Yalnız parentPostId=null gönderiler döner.

Soft-delete edilmiş gönderiler döndürülmez.

Moderasyonla gizlenmiş gönderiler döndürülmez.

Hedef kullanıcı bulunamazsa 404.

Block nedeniyle hedef profil görünmezse 404.

Empty state:

{
  "items": []
}

Mevcut profilin hiç görünür kök gönderisi olmaması 404 değildir.

11.5 GET /api/v1/profiles/{username}/followers

Auth: Bearer

İstek gövdesi: Yok

Read semantiği:

Hedef profil path içindeki username ile belirlenir.

Hedef kullanıcıyı takip eden kullanıcılar döndürülür.

Başarı:

200 OK

Golden response:

{
  "items": [
    {
      "id": 3,
      "username": "deniz",
      "displayName": "Deniz",
      "avatarUrl": null,
      "isFollowedByCurrentUser": true
    }
  ]
}

items elemanları SocialGraphUserResponse tipidir.

Kurallar:

Hedef profil bulunamazsa 404.

Hedef profil block nedeniyle görünmezse 404.

Oturum sahibine block nedeniyle görünmeyen hesaplar sonuçtan filtrelenir.

isFollowedByCurrentUser her liste öğesi için oturum sahibine göre hesaplanır.

Sıralama follow ilişkisinin createdAt DESC değerine göre yapılır.

Eşitlikte kullanıcı id DESC sırası kullanılır.

Empty state:

{
  "items": []
}

Takipçi bulunmaması 404 değildir.

11.6 GET /api/v1/profiles/{username}/following

Auth: Bearer

İstek gövdesi: Yok

Read semantiği:

Hedef profil path içindeki username ile belirlenir.

Hedef kullanıcının takip ettiği kullanıcılar döndürülür.

Başarı:

200 OK

Golden response:

{
  "items": [
    {
      "id": 4,
      "username": "ece",
      "displayName": "Ece",
      "avatarUrl": null,
      "isFollowedByCurrentUser": false
    }
  ]
}

items elemanları SocialGraphUserResponse tipidir.

Kurallar:

Hedef profil bulunamazsa 404.

Hedef profil block nedeniyle görünmezse 404.

Oturum sahibine block nedeniyle görünmeyen hesaplar sonuçtan filtrelenir.

isFollowedByCurrentUser her liste öğesi için oturum sahibine göre hesaplanır.

Sıralama follow ilişkisinin createdAt DESC değerine göre yapılır.

Eşitlikte kullanıcı id DESC sırası kullanılır.

Empty state:

{
  "items": []
}

Takip edilen kullanıcı bulunmaması 404 değildir.

12. Follows

12.1 POST /api/v1/profiles/{username}/follow

Auth: Bearer

Create semantiği:

Hedef path içindeki username ile belirlenir.

İstek gövdesi yoktur.

Takip eden kullanıcı JWT üzerinden belirlenir.

Golden request:

POST /api/v1/profiles/ada/follow
Authorization: Bearer <accessToken>

Başarı:

200 OK

Golden response:

{
  "username": "ada",
  "isFollowing": true
}

Kullanıcı bulunamazsa:

404 Not Found

Block ilişkisi varsa:

404 Not Found

Self-follow:

400 Bad Request

Aynı follow ilişkisini tekrar oluşturma idempotent davranabilir ve duplicate persistence kaydı oluşturmaz.

12.2 DELETE /api/v1/profiles/{username}/follow

Auth: Bearer

İstek gövdesi: Yok

Başarı:

200 OK

Golden response:

{
  "username": "ada",
  "isFollowing": false
}

Follow kaydı bulunmasa da işlem idempotent olarak başarılı kabul edilebilir.

13. Feed

13.1 GET /api/v1/feed

Auth: Bearer

İstek gövdesi: Yok

Başarı:

200 OK

Golden response:

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

Boş feed:

{
  "items": []
}

Boş feed 404 değildir.

Feed:

kronolojik olarak createdAt DESC sıralanır,

eşitlikte id DESC kullanılır,

soft-delete postları içermez,

moderasyonla gizlenmiş postları içermez,

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

{
  "content": "Merhaba Pulse."
}

Geçersiz request:

{
  "title": "Merhaba Pulse."
}

Başarı:

201 Created

Golden response:

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

Validation:

content boş olamaz.

content 280 karakteri aşamaz.

14.2 DELETE /api/v1/posts/{postId}

Auth: Bearer

İstek gövdesi: Yok

Yalnızca gönderi sahibi kendi gönderisini silebilir.

Başarı:

204 No Content

Post bulunamazsa:

404 Not Found

Başkasının postunu silme:

403 Forbidden

Bu endpoint standart kullanıcı sahiplik silmesidir.

Moderasyon kaldırması için bu endpoint kullanılmaz.
15. Replies

15.1 GET /api/v1/posts/{postId}/replies

Auth: Bearer

İstek gövdesi: Yok

Read semantiği:

Parent post path içindeki postId ile belirlenir.

Yalnız doğrudan reply kayıtları döndürülür.

Reply kayıtları PostResponse şemasını yeniden kullanır.

Persist edilmiş bir reply, başarılı POST /api/v1/posts/{postId}/replies işleminden sonra bu endpoint üzerinden yeniden okunabilir olmalıdır.

Sıralama kullanıcı deneyimi gereği createdAt ASC, eşitlikte id ASC olur; böylece yanıtlar eski→yeni gösterilir.

Nested reply desteklenmediğinden dönen her öğenin parentPostId değeri path içindeki postId ile aynı olmalıdır.

Başarı:

200 OK

Golden response:

{
  "items": [
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
  ]
}

Yanıt alanları:

AlanTürZorunluNull
itemsPostResponse arrayEvetHayır

Kurallar:

Parent bulunamazsa 404.

Soft-delete edilmiş parent için 404.

Moderasyonla gizlenmiş parent için 404.

Block nedeniyle görünmeyen parent için 404.

Parent'ın kendisi reply ise 404; nested reply collection'ı tanımlı değildir.

Soft-delete edilmiş reply kayıtları döndürülmez.

Moderasyonla gizlenmiş reply kayıtları döndürülmez.

Block nedeniyle oturum sahibine görünmeyen reply author'larının kayıtları döndürülmez.

Empty collection 404 değildir.

Empty state:

{
  "items": []
}

15.2 POST /api/v1/posts/{postId}/replies

Auth: Bearer

Create semantiği:

Parent post path içindeki postId ile belirlenir.

Gövdede id veya parentPostId bulunmaz.

Başarılı create sonrası oluşturulan reply GET /api/v1/posts/{postId}/replies sonucunda görünür olmalıdır.

İstek alanları:

AlanTürZorunlu
contentstringEvet

Golden request:

{
  "content": "Katılıyorum."
}

Başarı:

201 Created

Golden response:

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

Kurallar:

content maksimum 280 karakter.

Parent bulunamazsa 404.

Soft-delete edilmiş parent için 404.

Moderasyonla gizlenmiş parent için 404.

Block nedeniyle görünmeyen parent için 404.

Parent'ın kendisi reply ise yeni nested reply oluşturulamaz.

16. Likes

16.1 POST /api/v1/posts/{postId}/likes

Auth: Bearer

İstek gövdesi: Yok

Başarı:

200 OK

Golden response:

{
  "postId": 15,
  "isLiked": true,
  "likeCount": 5
}

Post bulunamaz veya görünmezse:

404 Not Found

Aynı kullanıcının tekrar like isteği idempotenttir.

16.2 DELETE /api/v1/posts/{postId}/likes

Auth: Bearer

İstek gövdesi: Yok

Başarı:

200 OK

Golden response:

{
  "postId": 15,
  "isLiked": false,
  "likeCount": 4
}

Like bulunmasa da işlem idempotent olarak başarılı kabul edilir.

17. Blocks

17.1 POST /api/v1/profiles/{username}/block

Auth: Bearer

Create semantiği:

Hedef path içindeki username ile belirlenir.

İstek gövdesi yoktur.

Gövdede id veya username gönderilmez.

Golden request:

POST /api/v1/profiles/otheruser/block
Authorization: Bearer <accessToken>

Başarı:

200 OK

Golden response:

{
  "username": "otheruser",
  "isBlocked": true
}

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

DELETE /api/v1/profiles/otheruser/block
Authorization: Bearer <accessToken>

Başarı:

204 No Content

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

200 OK

Golden response:

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

Yanıt alanları:

AlanTürZorunluNull
itemsarrayEvetHayır
items[].idintegerEvetHayır
items[].usernamestringEvetHayır
items[].displayNamestringEvetHayır
items[].avatarUrlstringEvetEvet
items[].blockedAtUTC ISO 8601 stringEvetHayır

Empty state:

{
  "items": []
}

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

{
  "targetType": "Post",
  "targetId": 15,
  "reason": "Harassment",
  "details": "Repeated targeted insults."
}

Golden user-report request:

{
  "targetType": "User",
  "targetId": 22,
  "reason": "Impersonation",
  "details": null
}

Alternatif request alanları geçersizdir: postId, userId, reportType, categoryCode, targetIdentifier.

Başarı:

201 Created

Golden response:

{
  "id": 41,
  "targetType": "Post",
  "targetId": 15,
  "reason": "Harassment",
  "details": "Repeated targeted insults.",
  "status": "Pending",
  "createdAt": "2026-08-08T12:15:00Z"
}

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

Authorization: Bearer <accessToken>

ve Moderator rolü gerektirir.

Normal User rolü:

403 Forbidden

19.1 GET /api/v1/moderation/reports

Auth: Moderator

İstek gövdesi: Yok

Opsiyonel status query değeri paylaşılan ReportStatus enum'undan biri olmalıdır:

Pending

Resolved

Dismissed

Query verilmezse varsayılan durum Pending olur.

Başarı:

200 OK

Golden response:

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

{
  "items": []
}

Boş kuyruk 404 değildir.
19.2 GET /api/v1/moderation/reports/{reportId}

Auth: Moderator

İstek gövdesi: Yok

Başarı:

200 OK

Golden response:

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

Report bulunamazsa:

404 Not Found

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

{
  "action": "RemovePost",
  "note": "Content violates harassment policy."
}

Golden NoAction request:

{
  "action": "NoAction",
  "note": null
}

Başarı:

200 OK

Golden response:

{
  "id": 41,
  "status": "Resolved",
  "action": "RemovePost",
  "resolvedAt": "2026-08-08T12:30:00Z",
  "resolvedByUserId": 3
}

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

RemovePost yalnız targetType=Post için geçerlidir.

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

{
  "note": "No policy violation found."
}

Başarı:

200 OK

Golden response:

{
  "id": 41,
  "status": "Dismissed",
  "resolvedAt": "2026-08-08T12:35:00Z",
  "resolvedByUserId": 3
}

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

GET /api/v1/feed

GET /api/v1/profiles/{username}

GET /api/v1/profiles/{username}/posts

GET /api/v1/profiles/{username}/followers

GET /api/v1/profiles/{username}/following

POST /api/v1/profiles/{username}/follow

POST /api/v1/posts/{postId}/likes

GET /api/v1/posts/{postId}/replies

POST /api/v1/posts/{postId}/replies

Kurallar:

Engelli hesapların postları feed'den filtrelenir.

İki kullanıcı arasında block varsa yeni follow oluşturulamaz.

Block nedeniyle görünmeyen profile erişim 404 döndürür.

Block nedeniyle görünmeyen profilin post/follower/following collection'ları 404 döndürür.

Followers/following listelerinde oturum sahibine block nedeniyle görünmeyen kullanıcılar items sonucundan filtrelenir.

Block nedeniyle görünmeyen post üzerinde like/reply oluşturma 404 döndürür.

Block nedeniyle görünmeyen postun reply collection'ı 404 döndürür.

Reply collection içindeki block nedeniyle görünmeyen reply author'larının kayıtları sonuçtan filtrelenir.

Response block ilişkisinin varlığını ayrıca açıklamaz.

Block oluşturulduğunda iki yöndeki mevcut follow ilişkileri kaldırılır.

Unblock eski follow ilişkisini geri getirmez.

21. Moderasyon ile kaldırılmış gönderi semantiği

RemovePost sonucunda moderasyonla gizlenmiş post:

feed'de dönmez,

profil gönderileri collection'ında dönmez,

normal görünür post kabul edilmez,

reply collection'ı okunamaz,

yeni like kabul etmez,

yeni reply kabul etmez.

Görünmeyen post için ilişkili kaynak işlemleri 404 Not Found döndürülür.

Mobil istemci moderasyon kaldırması için standart DELETE /api/v1/posts/{postId} endpoint'ini kullanmaz.

Standart DELETE endpoint'inin gönderi sahipliği semantiği değişmez.

22. HTTP Create / Update / Read kuralları

Create

Yeni kaynak create işlemi collection/action POST semantiğini kullanır.

Gövdede server tarafından üretilecek kaynak kimliği bulunmaz.

Bu kural:

register,

posts,

replies,

block,

reports

create akışları için geçerlidir.

Bir create endpoint'i kullanıcı tarafından yeniden görüntülenebilir içerik oluşturuyorsa aynı kaynağın canonical GET yolu da sözleşmede bulunmalıdır.

Replies için zorunlu mutation ↔ read çifti:

POST /api/v1/posts/{postId}/replies
GET /api/v1/posts/{postId}/replies

Başarılı reply create sonrası aynı kayıt GET collection içinde okunabilir olmalıdır.

Update

Mevcut kaynağın güncellenmesi canonical path üzerinden yapılır.

Örnek:

PUT /api/v1/me

Moderasyon state transition işlemleri action endpoint'leri üzerinden gerçekleştirilir:

POST /api/v1/moderation/reports/{reportId}/resolve

POST /api/v1/moderation/reports/{reportId}/dismiss

Request body içinde path kimliği tekrar edilmez.

Read

Tek kaynağın path ile seçildiği GET endpoint'lerinde kayıt bulunamazsa 404 Not Found döndürülür.

Profile bağlı collection endpoint'lerinde önce hedef profil görünürlüğü doğrulanır.

Hedef profil bulunamaz veya block nedeniyle görünmezse:

404 Not Found

Hedef profil mevcut fakat collection boşsa:

200 OK

{
  "items": []
}

Bu empty-state davranışı özellikle:

GET /api/v1/feed

GET /api/v1/blocks

GET /api/v1/moderation/reports

GET /api/v1/profiles/{username}/posts

GET /api/v1/profiles/{username}/followers

GET /api/v1/profiles/{username}/following

GET /api/v1/posts/{postId}/replies

için geçerlidir.

Reply collection'ında parent post mevcut ve görünür olduğu halde reply bulunmaması 404 değildir; 200 ve {"items":[]} döner.

23. Golden sample kuralı

Backend integration testindeki PostAsJsonAsync ve PutAsJsonAsync request gövdeleri bu dokümandaki golden JSON ile aynı alan adlarını kullanmalıdır.

Post:

{
  "content": "Merhaba Pulse."
}

Reply:

{
  "content": "Katılıyorum."
}

Reply read:

{
  "items": [
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
  ]
}

Profile update:

{
  "displayName": "İlkan Kişi",
  "bio": "Pulse kullanıcısı",
  "avatarUrl": null
}

Report:

{
  "targetType": "Post",
  "targetId": 15,
  "reason": "Harassment",
  "details": "Repeated targeted insults."
}

Moderation resolve:

{
  "action": "RemovePost",
  "note": "Content violates harassment policy."
}

Mobil toJson() ve request body testleri bu golden gövdelerle aynı alan adlarını ve enum string değerlerini üretmelidir.

Backend integration test golden JSON ile mobil serializer/request body arasında aşağıdaki birebir eşleme canonical'dır:

GOLDEN_REQUEST_MATCH | POST /api/v1/auth/register | backend={username,displayName,password} | mobile={username,displayName,password}

GOLDEN_REQUEST_MATCH | POST /api/v1/auth/login | backend={username,password} | mobile={username,password}

GOLDEN_REQUEST_MATCH | PUT /api/v1/me | backend={displayName,bio,avatarUrl} | mobile={displayName,bio,avatarUrl}

GOLDEN_REQUEST_MATCH | POST /api/v1/posts | backend={content} | mobile={content}

GOLDEN_REQUEST_MATCH | POST /api/v1/posts/{postId}/replies | backend={content} | mobile={content}

GOLDEN_REQUEST_MATCH | POST /api/v1/reports | backend={targetType,targetId,reason,details} | mobile={targetType,targetId,reason,details}

GOLDEN_REQUEST_MATCH | POST /api/v1/moderation/reports/{reportId}/resolve | backend={action,note} | mobile={action,note}

GOLDEN_REQUEST_MATCH | POST /api/v1/moderation/reports/{reportId}/dismiss | backend={note} | mobile={note}

Bu kayıtlarda backend ve mobile alan kümeleri sıralamadan bağımsız olarak birebir aynı olmalıdır.

GOLDEN_JSON_PARITY | backend-integration-test | mobile-toJson/request-body | EXACT

Mobil toJson() veya repository request body içinde ilgili backend golden request'e göre alan eklenemez, alan çıkarılamaz, alan adı değiştirilemez ve alias kullanılamaz.

Optional/null alan golden request içinde null olarak gönderiliyorsa mobil request de aynı canonical alanı null olarak üretir; farklı property adına map edilmez.

Enum değerleri §24'teki case-sensitive canonical string değerlerini birebir kullanır.

Backend golden request ile mobil request body arasında property adı, null semantiği veya enum string değeri farkı kontrat ihlalidir.
Reply repository ve backend integration testleri GET /api/v1/posts/{postId}/replies response'unu items: PostResponse[] olarak doğrulamalı; sıralama createdAt ASC, eşitlikte id ASC olmalıdır.

Aynı paylaşılan enum/tip için istemci tarafında tek canonical serializer kullanılmalıdır. Endpoint'e göre alternatif enum casing veya farklı serializer tanımlanamaz.

24. Enum casing ve serializer kuralı

Enum string değerleri case-sensitive canonical değerlerdir.

ReportTargetType:

Post

User

ReportReason:

Spam

Harassment

HateSpeech

Violence

SexualContent

Impersonation

Other

ReportStatus:

Pending

Resolved

Dismissed

ModerationAction:

NoAction

RemovePost

Küçük harfli veya farklı biçimli enum alias'ları geçersizdir.

Örneğin post, user, spam, harassment, pending, resolved, remove_post ve removePost canonical enum string'i değildir.

Backend integration testlerindeki enum string'leri golden referanstır.

Mobil aynı enum için tek serializer fonksiyonu kullanmalı ve yukarıdaki canonical değerleri birebir üretmelidir.
25. Kimlik kararı

Güncel Pulse MVP kaynak kimlikleri integer'dır.

Backend modeli:

int Id

Mobil modeli:

final int id;

API örneği:

{
  "id": 1
}

UUID string kullanılmaz.

26. Gönderi alan adları

Bir gönderinin canonical temel JSON property adları id, author, content, parentPostId, createdAt, likeCount, replyCount ve isLikedByMe şeklindedir.

Kullanıcı tarafından oluşturulan gönderi metninin canonical JSON property adı content'tir.

content bir enum string değeri değildir ve camelCase JSON property adı olarak kalmalıdır.

Geçersiz alternatif JSON property adları title, description, text ve body'dir.

Mobil UI bir gönderi başlığı benzeri görsel öğe üretse bile backend request/response alanını title olarak değiştirmez.

§24 içindeki PascalCase zorunluluğu yalnızca paylaşılan enum string değerlerine uygulanır; JSON property adlarına uygulanmaz.

27. Profil ve sosyal graf alan adları

Canonical profile response alanları:

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

Canonical SocialGraphUserResponse alanları:

id

username

displayName

avatarUrl

isFollowedByCurrentUser

isFollowedByCurrentUser, oturum sahibinin response'ta temsil edilen kullanıcıyı takip edip etmediğini ifade eder.

Bu alan yerine ikinci bir alias kullanılmaz.

Özellikle aşağıdaki alternatif alan adları canonical değildir:

isFollowing

followedByMe

followingByCurrentUser

isCurrentUserFollowing

Profile response içindeki postCount, yalnız görünür kök gönderilerin sayısıdır.

followerCount ve followingCount, canonical follow ilişkilerinden hesaplanır.

Followers ve following collection'ları aynı SocialGraphUserResponse alan setini kullanır.

Profil gönderileri için ayrı bir post JSON şeması oluşturulmaz; PostResponse yeniden kullanılır.

28. Güvenlik ve moderasyon hata örnekleri

Self-block:

{
  "error": "You cannot block yourself.",
  "field": null
}

Duplicate pending report:

{
  "error": "A pending report already exists for this target.",
  "field": null
}

Geçersiz report reason:

{
  "error": "Invalid report reason.",
  "field": "reason"
}

Geçersiz moderation action:

{
  "error": "Invalid moderation action.",
  "field": "action"
}

Moderator rolü yok:

{
  "error": "You are not authorized to perform this action.",
  "field": null
}

Daha önce sonuçlandırılmış report:

{
  "error": "The report has already been resolved.",
  "field": null
}

29. Authorization özeti

Anonim:

GET /health

POST /api/v1/auth/register

POST /api/v1/auth/login

Bearer:

GET /api/v1/me

PUT /api/v1/me

GET /api/v1/profiles/{username}

GET /api/v1/profiles/{username}/posts

GET /api/v1/profiles/{username}/followers

GET /api/v1/profiles/{username}/following

POST /api/v1/profiles/{username}/follow

DELETE /api/v1/profiles/{username}/follow

GET /api/v1/feed

POST /api/v1/posts

DELETE /api/v1/posts/{postId}

GET /api/v1/posts/{postId}/replies

POST /api/v1/posts/{postId}/replies

POST /api/v1/posts/{postId}/likes

DELETE /api/v1/posts/{postId}/likes

POST /api/v1/profiles/{username}/block

DELETE /api/v1/profiles/{username}/block

GET /api/v1/blocks

POST /api/v1/reports

Bearer + Moderator:

GET /api/v1/moderation/reports

GET /api/v1/moderation/reports/{reportId}

POST /api/v1/moderation/reports/{reportId}/resolve

POST /api/v1/moderation/reports/{reportId}/dismiss

30. Sosyal Graf collection semantiği

Aşağıdaki endpoint'ler profile bağlı collection endpoint'leridir:

GET /api/v1/profiles/{username}/posts

GET /api/v1/profiles/{username}/followers

GET /api/v1/profiles/{username}/following

Ortak kurallar:

Bearer token zorunludur.

Hedef kullanıcı path içindeki username ile çözülür.

Hedef profil bulunamazsa 404.

Hedef profil block nedeniyle görünmezse 404.

Hedef profil mevcut ve collection boşsa 200.

Boş response kesin olarak {"items":[]} semantiğini kullanır.

Block nedeniyle oturum sahibine görünmeyen sosyal graf kullanıcıları listeye dahil edilmez.

İstemci 404 sonucundan kullanıcının gerçekten bulunmadığı veya block nedeniyle gizlendiği sonucunu ayırt etmeye çalışmaz.

30.1 Profil gönderileri sıralaması

Profil gönderileri:

createdAt DESC
id DESC

sırasını kullanır.

Yalnız kök gönderiler döndürülür.

Reply kayıtları profil ana gönderi collection'ına dahil edilmez.

30.2 Followers sıralaması

Followers collection'ı follow ilişkisinin oluşturulma zamanına göre:

createdAt DESC

sıralanır.

Eşitlik durumunda response kullanıcısının integer kimliği:

id DESC

ile deterministik sıra sağlanır.

30.3 Following sıralaması

Following collection'ı follow ilişkisinin oluşturulma zamanına göre:

createdAt DESC

sıralanır.

Eşitlik durumunda response kullanıcısının integer kimliği:

id DESC

ile deterministik sıra sağlanır.

30.4 Reply collection sıralaması

Reply collection profile bağlı değildir; parent post path içindeki postId ile seçilir.

Canonical sıra:

createdAt ASC
id ASC

Bu sıra kullanıcıya yanıtları eski→yeni gösterir.

Parent post mevcut ve görünür olduğu halde reply bulunmaması:

200 OK

ve:

{
  "items": []
}

ile temsil edilir.

31. Sosyal Graf ve reply golden response özeti

31.1 Profile

{
  "id": 2,
  "username": "ada",
  "displayName": "Ada",
  "bio": null,
  "avatarUrl": null,
  "createdAt": "2026-07-20T09:00:00Z",
  "postCount": 8,
  "followerCount": 20,
  "followingCount": 8,
  "isFollowedByCurrentUser": true
}

31.2 Profile posts

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
      "content": "Profilimdeki gönderi.",
      "parentPostId": null,
      "createdAt": "2026-08-08T12:00:00Z",
      "likeCount": 4,
      "replyCount": 1,
      "isLikedByMe": false
    }
  ]
}

31.3 Followers

{
  "items": [
    {
      "id": 3,
      "username": "deniz",
      "displayName": "Deniz",
      "avatarUrl": null,
      "isFollowedByCurrentUser": true
    }
  ]
}

31.4 Following

{
  "items": [
    {
      "id": 4,
      "username": "ece",
      "displayName": "Ece",
      "avatarUrl": null,
      "isFollowedByCurrentUser": false
    }
  ]
}

31.5 Replies

{
  "items": [
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
  ]
}

Backend integration testleri ve mobil model/request-response testleri bu alan adlarını birebir kullanmalıdır.

32. Tek kaynak ve read-after-write kuralı

Bu doküman backend ve mobil arasında API sözleşmesinin tek human-readable kaynağıdır.

PIPELINE_GATE | architect | read-after-write-contract | READY_FOR_BACKEND

Architect read-after-write kararı bu dokümandaki canonical endpoint tanımlarıdır. Backend route/handler wiring'i ve contract testleri bu route setine hizalanır; backend implementasyonu canonical sözleşmeyi yeniden tanımlamaz.
docs/api-contract.openapi.json aynı canonical sözleşmenin machine-readable OpenAPI 3.0.x karşılığıdır.

Backend DTO alanı ile mobil model alanı farklı isim kullanamaz.

PRODUCT_COMPLETENESS_GATE | contract | REQUIRED

Build ve testlerin başarılı olması tek başına API ürün bütünlüğü kabulü değildir.

Canonical endpoint, request/response alanları, mutation ↔ read eşleşmeleri ve golden JSON ↔ mobile request/toJson eşleşmeleri bu dokümanla uyumlu değilse contract katmanı kırmızı kabul edilir ve görev tamamlanmış sayılmaz.
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

Mutation ile kullanıcı tarafından okunabilir içerik üretiliyorsa ilgili read endpoint'i aynı canonical kaynak bölümünde tanımlanmalıdır.

Özellikle reply kaynağı için canonical çift:

GET /api/v1/posts/{postId}/replies
POST /api/v1/posts/{postId}/replies

şeklindedir.

POST /api/v1/posts/{postId}/replies ile oluşturulan reply yalnız response içinde dönmekle kalmaz; sonraki GET /api/v1/posts/{postId}/replies çağrısında persisted collection öğesi olarak okunabilir olmalıdır.

Reply listesi createdAt ASC, eşitlikte id ASC sıralanır.

Sosyal Graf & Profil Tamamlama için canonical read endpoint'leri:

GET /api/v1/profiles/{username}/posts
GET /api/v1/profiles/{username}/followers
GET /api/v1/profiles/{username}/following

Reply read-after-write için canonical read endpoint'i:

GET /api/v1/posts/{postId}/replies

Bu kaynaklar için /api/v1/users/..., farklı profile route alias'ları veya farklı reply route alias'ları oluşturulmaz.
action: update
Bu karar değiştirilmedikçe backend, mobile veya test katmanı GET reply route'unu kaldıramaz ya da alternatif bir reply read path tanımlayamaz.

34. Deterministik mutation ↔ read sınıflandırması

Bu bölüm CONTRACT_MUTATION_WITHOUT_READ doğrulaması için canonical sınıflandırmadır.

REQUIRED, mutation'ın kullanıcı tarafından daha sonra yeniden okunabilir yeni persisted içerik oluşturduğunu ve canonical bir GET gerektirdiğini belirtir.

EXEMPT, mutation'ın yeni okunabilir içerik oluşturmadığını; delete, ilişki toggle'ı veya mevcut kaynağın state transition işlemi olduğunu belirtir. EXEMPT mutation için yalnız taramayı susturmak amacıyla yeni aynı-path GET endpoint'i oluşturulmaz.

Makine tarafından okunabilir kayıt biçimi:

READ_AFTER_WRITE | <METHOD> <PATH> | REQUIRED | GET <PATH>

veya:

READ_AFTER_WRITE | <METHOD> <PATH> | EXEMPT | <CANONICAL_READ veya NONE>

Canonical kayıtlar:

READ_AFTER_WRITE | POST /api/v1/posts/{postId}/replies | REQUIRED | GET /api/v1/posts/{postId}/replies

READ_AFTER_WRITE | POST /api/v1/moderation/reports/{reportId}/resolve | REQUIRED | GET /api/v1/moderation/reports/{reportId}/resolve

READ_AFTER_WRITE | POST /api/v1/moderation/reports/{reportId}/dismiss | REQUIRED | GET /api/v1/moderation/reports/{reportId}/dismiss

READ_AFTER_WRITE | DELETE /api/v1/posts/{postId} | REQUIRED | GET /api/v1/posts/{postId}

READ_AFTER_WRITE | POST /api/v1/posts/{postId}/likes | REQUIRED | GET /api/v1/posts/{postId}/likes

READ_AFTER_WRITE | DELETE /api/v1/posts/{postId}/likes | REQUIRED | GET /api/v1/posts/{postId}/likes

READ_AFTER_WRITE | POST /api/v1/profiles/{username}/block | REQUIRED | GET /api/v1/profiles/{username}/block

READ_AFTER_WRITE | DELETE /api/v1/profiles/{username}/block | REQUIRED | GET /api/v1/profiles/{username}/block

READ_AFTER_WRITE | POST /api/v1/profiles/{username}/follow | REQUIRED | GET /api/v1/profiles/{username}/follow

READ_AFTER_WRITE | DELETE /api/v1/profiles/{username}/follow | REQUIRED | GET /api/v1/profiles/{username}/follow

34.1 Moderation action endpoint'leri

POST /api/v1/moderation/reports/{reportId}/resolve ve POST /api/v1/moderation/reports/{reportId}/dismiss yeni alt kaynak oluşturmaz.

Her ikisi de mevcut report kaynağının durumunu değiştirir.

İşlemden sonraki canonical same-path read endpoint'leri:

GET /api/v1/moderation/reports/{reportId}/resolve

GET /api/v1/moderation/reports/{reportId}/dismiss

şeklindedir.

Bu GET endpoint'leri Moderator auth gerektirir. Kesin response gövdesi için upstream gereksinim bulunmadığından response şeması CANONICAL_REQUIREMENT_UNRESOLVED durumundadır; backend ve mobile alan uydurmamalıdır.

34.2 Post delete

DELETE /api/v1/posts/{postId} mevcut kaynağı görünmez/silinmiş duruma getirir ve yeni okunabilir bir kaynak üretmez.

Canonical same-path read:

GET /api/v1/posts/{postId}

Auth: Bearer

Başarı: 200 OK ve mevcut PostResponse.

Post bulunamaz, silinmiş veya görünmez ise 404 Not Found.

34.3 Like ilişki mutation'ları

POST /api/v1/posts/{postId}/likes ve DELETE /api/v1/posts/{postId}/likes bağımsız kullanıcı içeriği oluşturmaz; oturum sahibi ile post arasındaki like ilişkisini toggle eder.

Mutation response'u postId, isLiked ve likeCount ile yeni durumu doğrudan döndürür.

Canonical same-path read:

GET /api/v1/posts/{postId}/likes

Auth: Bearer

Başarı: 200 OK.

Kesin response gövdesi upstream gereksinimlerde tanımlı değildir: CANONICAL_REQUIREMENT_UNRESOLVED.

34.4 Block ilişki mutation'ları

POST /api/v1/profiles/{username}/block ve DELETE /api/v1/profiles/{username}/block bağımsız kullanıcı içeriği oluşturmaz; block ilişkisini oluşturur veya kaldırır.

Canonical same-path read:

GET /api/v1/profiles/{username}/block

Auth: Bearer

Başarı: 200 OK.

Kesin response gövdesi upstream gereksinimlerde tanımlı değildir: CANONICAL_REQUIREMENT_UNRESOLVED.

34.5 Follow ilişki mutation'ları

POST /api/v1/profiles/{username}/follow ve DELETE /api/v1/profiles/{username}/follow bağımsız kullanıcı içeriği oluşturmaz; follow ilişkisini oluşturur veya kaldırır.

Canonical same-path read:

GET /api/v1/profiles/{username}/follow

Auth: Bearer

Başarı: 200 OK.

Kesin response gövdesi upstream gereksinimlerde tanımlı değildir: CANONICAL_REQUIREMENT_UNRESOLVED.

34.6 Tarama kuralı

CONTRACT_MUTATION_WITHOUT_READ doğrulamasında yukarıdaki REQUIRED mutation kayıtlarının her biri için aynı resource path üzerinde canonical GET bulunmalıdır.

Canonical same-path GET listesi:

GET /api/v1/posts/{postId}
GET /api/v1/posts/{postId}/likes
GET /api/v1/posts/{postId}/replies
GET /api/v1/profiles/{username}/block
GET /api/v1/profiles/{username}/follow
GET /api/v1/moderation/reports/{reportId}/resolve
GET /api/v1/moderation/reports/{reportId}/dismiss