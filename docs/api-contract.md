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

Origin: http://127.0.0.1:8080

Header: Authorization

Header: Content-Type

Method: GET

Method: POST

Method: PUT

Method: DELETE

Method: OPTIONS

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

GET /health

POST /api/v1/auth/register

POST /api/v1/auth/login

Diğer endpoint'ler Bearer token gerektirir.

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
404Path ile seçilen kaynak bulunamadı
409Benzersizlik veya ilişki çakışması
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

8. Health

GET /health

Auth: Anonim

İstek gövdesi: Yok

Başarı: 200 OK

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

expiresAt kullanılmaz.

9.3 PostAuthorResponse

```
{
  "id": 1,
  "username": "ilkan",
  "displayName": "İlkan",
  "avatarUrl": null
}
```

9.4 PostResponse

```
{
  "id": 10,
  "author": {
    "id": 1,
    "username": "ilkan",
    "displayName": "İlkan",
    "avatarUrl": null
  },
  "content": "Pulse üzerindeki ilk gönderim.",
  "parentPostId": null,
  "createdAt": "2026-08-05T10:20:00Z",
  "likeCount": 3,
  "replyCount": 1,
  "isLikedByCurrentUser": false
}
```

AlanTürNull
idintegerHayır
authorPostAuthorResponseHayır
contentstringHayır
parentPostIdintegerEvet
createdAtstring date-timeHayır
likeCountintegerHayır
replyCountintegerHayır
isLikedByCurrentUserbooleanHayır

Aşağıdaki alanlar güncel PostResponse tipinde bulunmaz:

description

media

replyToPostId

repostCount

isReposted

isBookmarked

updatedAt

9.5 ProfileResponse

```
{
  "id": 1,
  "username": "ilkan",
  "displayName": "İlkan",
  "bio": "Flutter ve .NET geliştiricisi",
  "avatarUrl": null,
  "createdAt": "2026-08-05T10:00:00Z",
  "postCount": 4,
  "followerCount": 12,
  "followingCount": 8,
  "isFollowedByCurrentUser": false
}
```

AlanTürNull
idintegerHayır
usernamestringHayır
displayNamestringHayır
biostringEvet
avatarUrlstringEvet
createdAtstring date-timeHayır
postCountintegerHayır
followerCountintegerHayır
followingCountintegerHayır
isFollowedByCurrentUserbooleanHayır

10. Auth

10.1 POST /api/v1/auth/register

Auth: Anonim

Create semantiği:

Gövdede kullanıcı kimliği bulunmaz.

Davet kodu bulunmaz.

Yönetici onayı gerekmez.

İstek:

```
{
  "username": "ilkan",
  "email": "ilkan@example.com",
  "password": "StrongPassword123!",
  "displayName": "İlkan"
}
```

AlanTürZorunlu
usernamestringEvet
emailstringEvet
passwordstringEvet
displayNamestringEvet

Başarı: 201 Created

Yanıt: AuthResponse

Hatalar:

400: validation

409: username veya e-posta kullanımda

10.2 POST /api/v1/auth/login

Auth: Anonim

İstek:

```
{
  "login": "ilkan",
  "password": "StrongPassword123!"
}
```

AlanTürZorunlu
loginstringEvet
passwordstringEvet

login alanı kullanıcı adı veya e-posta kabul eder.

Mobil aşağıdaki alternatif isteği göndermemelidir:

```
{
  "email": "ilkan@example.com",
  "password": "StrongPassword123!"
}
```

Başarı: 200 OK

Yanıt: AuthResponse

Hata:

401: kullanıcı bilgileri geçersiz

11. Profile

11.1 GET /api/v1/me

Auth: Bearer

İstek gövdesi: Yok

Başarı: 200 OK

Yanıt: ProfileResponse

Hatalar:

401: token yok veya geçersiz

404: oturum kullanıcısı bulunamadı

Bu endpoint için 404 empty state değildir.

11.2 PUT /api/v1/me

Auth: Bearer

İstek:

```
{
  "displayName": "İlkan Kişi",
  "bio": "Flutter ve .NET geliştiricisi",
  "avatarUrl": null
}
```

AlanTürZorunlu
displayNamestringEvet
biostring veya nullHayır
avatarUrlstring veya nullHayır

Gövdede bulunmaması gereken alanlar:

id

username

email

userId

Başarı: 200 OK

Yanıt: güncel ProfileResponse

11.3 GET /api/v1/profiles/{username}

Auth: Bearer

İstek gövdesi: Yok

Başarı: 200 OK

Yanıt: ProfileResponse

Hata:

404: kullanıcı bulunamadı

12. Follow

12.1 POST /api/v1/profiles/{username}/follow

Auth: Bearer

İstek gövdesi: Yok

Başarı: 200 OK

```
{
  "userId": 2,
  "isFollowing": true,
  "followerCount": 13
}
```

AlanTür
userIdinteger
isFollowingboolean
followerCountinteger

Hatalar:

400: kullanıcı kendisini takip etmeye çalıştı

404: hedef kullanıcı bulunamadı

12.2 DELETE /api/v1/profiles/{username}/follow

Auth: Bearer

İstek gövdesi: Yok

Başarı: 200 OK

```
{
  "userId": 2,
  "isFollowing": false,
  "followerCount": 12
}
```

Mobil 204 veya gövdesiz response beklememelidir.

13. Feed

GET /api/v1/feed

Auth: Bearer

İstek gövdesi: Yok

Başarı: 200 OK

Response doğrudan PostResponse dizisidir:

```
[
  {
    "id": 10,
    "author": {
      "id": 1,
      "username": "ilkan",
      "displayName": "İlkan",
      "avatarUrl": null
    },
    "content": "Pulse üzerindeki ilk gönderim.",
    "parentPostId": null,
    "createdAt": "2026-08-05T10:20:00Z",
    "likeCount": 3,
    "replyCount": 1,
    "isLikedByCurrentUser": false
  }
]
```

Boş feed:

```
[]
```

Empty/error kuralları:

200 ve []: empty state

200 ve dolu dizi: success

401: unauthorized

403: error

404: route veya API error

500: server error

Connection failure: error

JSON parse failure: error

Mobil repository 404 yanıtını boş listeye dönüştürmemelidir.

Mobil repository aşağıdaki fallback yollarını çağırmamalıdır:

```
/api/v1/posts
/feed
/posts
```

14. Posts

14.1 POST /api/v1/posts

Auth: Bearer

İstek:

```
{
  "content": "Pulse üzerindeki ilk gönderim."
}
```

AlanTürZorunluKural
contentstringEvetTrim sonrası 1–280 karakter

Gövdede bulunmaması gereken alanlar:

id

authorId

parentPostId

likeCount

replyCount

Başarı: 201 Created

Yanıt: PostResponse

Hatalar:

400: content boş veya 280 karakterden uzun

401: token geçersiz

Golden request:

```
{
  "content": "Pulse üzerindeki ilk gönderim."
}
```

14.2 DELETE /api/v1/posts/{postId}

Auth: Bearer

İstek gövdesi: Yok

Başarı: 204 No Content

Hatalar:

403: gönderi başka kullanıcıya ait

404: gönderi bulunamadı

15. Replies

POST /api/v1/posts/{postId}/replies

Auth: Bearer

İstek:

```
{
  "content": "Bu gönderiye katılıyorum."
}
```

AlanTürZorunluKural
contentstringEvetTrim sonrası 1–280 karakter

Başarı: 201 Created

Yanıt: PostResponse

Yanıtta:

```
{
  "parentPostId": 10
}
```

Kurallar:

Üst gönderi kimliği path'ten alınır.

Request gövdesinde parentPostId bulunmaz.

Üst gönderi bulunamazsa 404.

Üst gönderi zaten bir yanıtsa 400.

İkinci seviye yanıt desteklenmez.

Golden request:

```
{
  "content": "Bu gönderiye katılıyorum."
}
```

16. Likes

16.1 POST /api/v1/posts/{postId}/likes

Auth: Bearer

İstek gövdesi: Yok

Başarı: 200 OK

```
{
  "postId": 10,
  "isLiked": true,
  "likeCount": 4
}
```

AlanTür
postIdinteger
isLikedboolean
likeCountinteger

16.2 DELETE /api/v1/posts/{postId}/likes

Auth: Bearer

İstek gövdesi: Yok

Başarı: 200 OK

```
{
  "postId": 10,
  "isLiked": false,
  "likeCount": 3
}
```

Mobil like ve unlike işlemlerinde 204 beklememelidir.

17. Golden JSON örnekleri

Register

```
{
  "username": "ilkan",
  "email": "ilkan@example.com",
  "password": "StrongPassword123!",
  "displayName": "İlkan"
}
```

Login

```
{
  "login": "ilkan",
  "password": "StrongPassword123!"
}
```

Profil güncelleme

```
{
  "displayName": "İlkan Kişi",
  "bio": "Flutter ve .NET geliştiricisi",
  "avatarUrl": null
}
```

Gönderi oluşturma

```
{
  "content": "Pulse üzerindeki ilk gönderim."
}
```

Yanıt oluşturma

```
{
  "content": "Bu gönderiye katılıyorum."
}
```

18. Backend Agent düzeltme aktarımı

Dosya veya alanDüzeltme
Program.csDuplicate ve unprefixed route map edilmemeli
Endpoints/MvpEndpoints.csLegacy /me, /feed, /posts, /profiles kaldırılmalı
Endpoints/AuthEndpoints.csRegister/login anonim kalmalı
Endpoints/ProfileEndpoints.csCanonical me/profile/follow yolları kullanılmalı
Endpoints/FeedEndpoints.cs/api/v1/feed, Bearer auth ve doğrudan JSON dizi
Endpoints/PostEndpointRoutes.csCreate/delete/reply/like yolları matrise uymalı
Contracts/ApiContracts.cscontent, integer ID, login, expiresIn alanları kullanılmalı

19. Mobile Agent düzeltme aktarımı

AlanDüzeltme
Auth requestlogin alanını kullan
Auth responseexpiresIn alanını parse et
Profile repository/api/v1/me ve /api/v1/profiles/{username}
Feed repositoryYalnızca /api/v1/feed
Feed fallbackKaldır
Feed 404Empty değil error
Post modelicontent, parentPostId, integer ID
Like response200 + response gövdesini parse et
Follow response200 + response gövdesini parse et

20. Sözleşme doğrulama kriterleri

/health anonim olarak 200 döndürür.

Health gövdesi tam olarak {"status":"ok"} olur.

Register ve login anonimdir.

Diğer endpoint'ler Bearer token ister.

Canonical olmayan yollar çalışmaz.

Tüm kimlikler integer'dır.

Gönderi alanı content olur.

content en fazla 280 karakterdir.

İkinci seviye yanıt reddedilir.

Feed response'u doğrudan JSON dizisidir.

Feed empty state yalnızca 200 ve [] ile oluşur.

Mobil feed fallback route kullanmaz.

Login isteği login alanını kullanır.

Token süresi expiresIn alanından okunur.

Like ve follow işlemleri 200 response gövdelerini parse eder.
