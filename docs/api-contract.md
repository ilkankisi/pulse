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

~~~json
{
  "id": "225ebeca-5e61-4327-83d3-c8ffc6d29410"
}
~~~

Geçerli kimlik biçimi:

~~~json
{
  "id": 1
}
~~~

## 3. Yerel adresler ve CORS

Flutter web:

~~~text
http://127.0.0.1:8080
~~~

Backend API:

~~~text
http://127.0.0.1:5000
~~~

Backend aşağıdakileri desteklemelidir:

~~~text
Origin: http://127.0.0.1:8080
Header: Authorization
Header: Content-Type
Method: GET
Method: POST
Method: PUT
Method: DELETE
Method: OPTIONS
~~~

Tarayıcı `OPTIONS` preflight istekleri başarılı cevaplanmalıdır.

## 4. JWT yapılandırması

Orchestrator başlangıcı:

~~~text
dotnet run --no-launch-profile
ASPNETCORE_ENVIRONMENT=Development
~~~

Development ayarları:

~~~json
{
  "Jwt": {
    "Key": "development-only-key-at-least-32-bytes",
    "Issuer": "Pulse.Api",
    "Audience": "Pulse.Client"
  }
}
~~~

Kurallar:

- `Jwt:Key` en az 32 byte olmalıdır.
- Development ortamı production secret eksikliği nedeniyle çökmemelidir.
- Production anahtarı environment variable veya secret store üzerinden sağlanmalıdır.
- Production secret repoda bulunmamalıdır.

Anonim endpoint'ler:

~~~text
GET /health
POST /api/v1/auth/register
POST /api/v1/auth/login
~~~

Diğer endpoint'ler Bearer token gerektirir.

`/api/v1/moderation/**` endpoint'leri ayrıca `Moderator` rolü gerektirir.

## 5. Ortak HTTP kuralları

### 5.1 JSON Content-Type

~~~http
Content-Type: application/json
~~~

### 5.2 Authorization

~~~http
Authorization: Bearer <accessToken>
~~~

### 5.3 Hata response'u

~~~json
{
  "error": "Açıklayıcı hata mesajı.",
  "field": null
}
~~~

Belirli alan hatası:

~~~json
{
  "error": "Content must not exceed 280 characters.",
  "field": "content"
}
~~~

Standart durum kodları:

| Kod | Anlam |
|---|---|
| 400 | Validation, geçersiz JSON veya iş kuralı |
| 401 | Token yok, geçersiz veya süresi dolmuş |
| 403 | Kaynak sahipliği veya yetki hatası |
| 404 | Path ile seçilen kaynak bulunamadı veya güvenlik nedeniyle görünmez |
| 409 | Benzersizlik veya durum/ilişki çakışması |
| 500 | Beklenmeyen sunucu hatası |

Geçersiz JSON:

~~~json
{
  "error": "Request body contains invalid JSON.",
  "field": null
}
~~~

## 6. Canonical endpoint matrisi

| Modül | HTTP | Path | Auth | Başarı |
|---|---|---|---|---|
| Health | GET | `/health` | Anonim | 200 |
| Auth | POST | `/api/v1/auth/register` | Anonim | 201 |
| Auth | POST | `/api/v1/auth/login` | Anonim | 200 |
| Profile | GET | `/api/v1/me` | Bearer | 200 |
| Profile | PUT | `/api/v1/me` | Bearer | 200 |
| Profile | GET | `/api/v1/profiles/{username}` | Bearer | 200 |
| Profile | GET | `/api/v1/profiles/{username}/posts` | Bearer | 200 |
| SocialGraph | GET | `/api/v1/profiles/{username}/followers` | Bearer | 200 |
| SocialGraph | GET | `/api/v1/profiles/{username}/following` | Bearer | 200 |
| Follow | POST | `/api/v1/profiles/{username}/follow` | Bearer | 200 |
| Follow | DELETE | `/api/v1/profiles/{username}/follow` | Bearer | 200 |
| Feed | GET | `/api/v1/feed` | Bearer | 200 |
| Posts | POST | `/api/v1/posts` | Bearer | 201 |
| Posts | DELETE | `/api/v1/posts/{postId}` | Bearer | 204 |
| Replies | POST | `/api/v1/posts/{postId}/replies` | Bearer | 201 |
| Likes | POST | `/api/v1/posts/{postId}/likes` | Bearer | 200 |
| Likes | DELETE | `/api/v1/posts/{postId}/likes` | Bearer | 200 |
| Blocks | POST | `/api/v1/profiles/{username}/block` | Bearer | 200 |
| Blocks | DELETE | `/api/v1/profiles/{username}/block` | Bearer | 204 |
| Blocks | GET | `/api/v1/blocks` | Bearer | 200 |
| Reports | POST | `/api/v1/reports` | Bearer | 201 |
| Moderation | GET | `/api/v1/moderation/reports` | Moderator | 200 |
| Moderation | GET | `/api/v1/moderation/reports/{reportId}` | Moderator | 200 |
| Moderation | POST | `/api/v1/moderation/reports/{reportId}/resolve` | Moderator | 200 |
| Moderation | POST | `/api/v1/moderation/reports/{reportId}/dismiss` | Moderator | 200 |

`Moderator`, geçerli Bearer token ile birlikte `Moderator` rolünün zorunlu olduğunu ifade eder.

## 7. Yasak legacy yollar

Aşağıdaki yollar backend tarafından map edilmemelidir:

~~~text
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
~~~

Mobil repository bu yolları fallback olarak kullanmamalıdır.

Aynı davranış için birden fazla route tanımlanması yasaktır.

## 8. Health

### GET /health

Auth: Anonim

İstek gövdesi: Yok

Başarı:

~~~http
200 OK
~~~

Yanıt:

~~~json
{
  "status": "ok"
}
~~~

Response kesin olarak küçük harfli `status` alanını ve `"ok"` değerini içermelidir.

## 9. Paylaşılan tipler

### 9.1 AuthUserResponse

~~~json
{
  "id": 1,
  "username": "ilkan",
  "displayName": "İlkan",
  "avatarUrl": null
}
~~~

| Alan | Tür | Null |
|---|---|---|
| `id` | integer | Hayır |
| `username` | string | Hayır |
| `displayName` | string | Hayır |
| `avatarUrl` | string | Evet |

### 9.2 AuthResponse

~~~json
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
~~~

| Alan | Tür | Null |
|---|---|---|
| `accessToken` | string | Hayır |
| `tokenType` | string | Hayır |
| `expiresIn` | integer | Hayır |
| `user` | AuthUserResponse | Hayır |

`tokenType` değeri `Bearer`'dır.

### 9.3 AuthorResponse

~~~json
{
  "id": 2,
  "username": "ada",
  "displayName": "Ada",
  "avatarUrl": null
}
~~~

| Alan | Tür | Null |
|---|---|---|
| `id` | integer | Hayır |
| `username` | string | Hayır |
| `displayName` | string | Hayır |
| `avatarUrl` | string | Evet |

### 9.4 PostResponse

~~~json
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
~~~

| Alan | Tür | Null |
|---|---|---|
| `id` | integer | Hayır |
| `author` | AuthorResponse | Hayır |
| `content` | string | Hayır |
| `parentPostId` | integer | Evet |
| `createdAt` | UTC ISO 8601 string | Hayır |
| `likeCount` | integer | Hayır |
| `replyCount` | integer | Hayır |
| `isLikedByMe` | boolean | Hayır |
### 9.5 ReportTargetType

Tam canonical string değerleri:

- `Post`
- `User`

Başka casing veya alias kullanılmaz.

### 9.6 ReportReason

Tam canonical string değerleri:

- `Spam`
- `Harassment`
- `HateSpeech`
- `Violence`
- `SexualContent`
- `Impersonation`
- `Other`

### 9.7 ReportStatus

Tam canonical string değerleri:

- `Pending`
- `Resolved`
- `Dismissed`

### 9.8 ModerationAction

Tam canonical string değerleri:

- `NoAction`
- `RemovePost`

### 9.9 SocialGraphUserResponse

Followers ve following collection'ları aynı canonical liste öğesi tipini kullanır.

~~~json
{
  "id": 3,
  "username": "deniz",
  "displayName": "Deniz",
  "avatarUrl": null,
  "isFollowedByCurrentUser": true
}
~~~

| Alan | Tür | Null |
|---|---|---|
| `id` | integer | Hayır |
| `username` | string | Hayır |
| `displayName` | string | Hayır |
| `avatarUrl` | string | Evet |
| `isFollowedByCurrentUser` | boolean | Hayır |

`isFollowedByCurrentUser`, oturum sahibinin response'taki kullanıcıyı takip edip etmediğini belirtir.

Followers ve following için ikinci bir JSON alan seti tanımlanmaz.

## 10. Auth

### 10.1 POST /api/v1/auth/register

Auth: Anonim

Create semantiği:

- Gövdede kullanıcı kimliği bulunmaz.
- Backend yeni integer id üretir.

İstek gövdesi:

| Alan | Tür | Zorunlu |
|---|---|---|
| `username` | string | Evet |
| `displayName` | string | Evet |
| `password` | string | Evet |

Golden request:

~~~json
{
  "username": "ilkan",
  "displayName": "İlkan",
  "password": "ExamplePassword123!"
}
~~~

Başarı:

~~~http
201 Created
~~~

Golden response:

~~~json
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
~~~

Username benzersizlik çakışması:

~~~http
409 Conflict
~~~

### 10.2 POST /api/v1/auth/login

Auth: Anonim

İstek gövdesi:

| Alan | Tür | Zorunlu |
|---|---|---|
| `username` | string | Evet |
| `password` | string | Evet |

Golden request:

~~~json
{
  "username": "ilkan",
  "password": "ExamplePassword123!"
}
~~~

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

Geçersiz credential:

~~~http
401 Unauthorized
~~~

## 11. Profile

### 11.1 GET /api/v1/me

Auth: Bearer

İstek gövdesi: Yok

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

| Alan | Tür | Null |
|---|---|---|
| `id` | integer | Hayır |
| `username` | string | Hayır |
| `displayName` | string | Hayır |
| `bio` | string | Evet |
| `avatarUrl` | string | Evet |
| `createdAt` | UTC ISO 8601 string | Hayır |
| `postCount` | integer | Hayır |
| `followerCount` | integer | Hayır |
| `followingCount` | integer | Hayır |
| `isFollowedByCurrentUser` | boolean | Hayır |

Kendi profilinde `isFollowedByCurrentUser` değeri `false` olur; self-follow desteklenmez.

`postCount` yalnız görünür kök gönderileri sayar.

### 11.2 PUT /api/v1/me

Auth: Bearer

Update semantiği:

- Oturum sahibi güncellenir.
- Gövdede id bulunmaz.
- Gövdede username bulunmaz.

İstek alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `displayName` | string | Evet | Hayır |
| `bio` | string | Evet | Evet |
| `avatarUrl` | string | Evet | Evet |

Golden request:

~~~json
{
  "displayName": "İlkan Kişi",
  "bio": "Pulse kullanıcısı",
  "avatarUrl": null
}
~~~

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

### 11.3 GET /api/v1/profiles/{username}

Auth: Bearer

İstek gövdesi: Yok

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

Canonical profile response alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `id` | integer | Evet | Hayır |
| `username` | string | Evet | Hayır |
| `displayName` | string | Evet | Hayır |
| `bio` | string | Evet | Evet |
| `avatarUrl` | string | Evet | Evet |
| `createdAt` | UTC ISO 8601 string | Evet | Hayır |
| `postCount` | integer | Evet | Hayır |
| `followerCount` | integer | Evet | Hayır |
| `followingCount` | integer | Evet | Hayır |
| `isFollowedByCurrentUser` | boolean | Evet | Hayır |

Kullanıcı bulunamazsa:

~~~http
404 Not Found
~~~

Oturum sahibi ile hedef arasında block ilişkisi nedeniyle profil görünmezse:

~~~http
404 Not Found
~~~

Response block ilişkisinin varlığını ayrıca açıklamaz.

### 11.4 GET /api/v1/profiles/{username}/posts

Auth: Bearer

İstek gövdesi: Yok

Read semantiği:

- Hedef profil path içindeki `username` ile belirlenir.
- Yalnız hedef kullanıcıya ait kök gönderiler döndürülür.
- Mevcut `PostResponse` şeması yeniden kullanılır.

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

Yanıt alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `items` | PostResponse array | Evet | Hayır |

Kurallar:

- Sıralama `createdAt DESC`, eşitlikte `id DESC` olur.
- Yalnız `parentPostId=null` gönderiler döner.
- Soft-delete edilmiş gönderiler döndürülmez.
- Moderasyonla gizlenmiş gönderiler döndürülmez.
- Hedef kullanıcı bulunamazsa `404`.
- Block nedeniyle hedef profil görünmezse `404`.

Empty state:

~~~json
{
  "items": []
}
~~~

Mevcut profilin hiç görünür kök gönderisi olmaması `404` değildir.

### 11.5 GET /api/v1/profiles/{username}/followers

Auth: Bearer

İstek gövdesi: Yok

Read semantiği:

- Hedef profil path içindeki `username` ile belirlenir.
- Hedef kullanıcıyı takip eden kullanıcılar döndürülür.

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

`items` elemanları `SocialGraphUserResponse` tipidir.

Kurallar:

- Hedef profil bulunamazsa `404`.
- Hedef profil block nedeniyle görünmezse `404`.
- Oturum sahibine block nedeniyle görünmeyen hesaplar sonuçtan filtrelenir.
- `isFollowedByCurrentUser` her liste öğesi için oturum sahibine göre hesaplanır.
- Sıralama follow ilişkisinin `createdAt DESC` değerine göre yapılır.
- Eşitlikte kullanıcı `id DESC` sırası kullanılır.

Empty state:

~~~json
{
  "items": []
}
~~~

Takipçi bulunmaması `404` değildir.

### 11.6 GET /api/v1/profiles/{username}/following

Auth: Bearer

İstek gövdesi: Yok

Read semantiği:

- Hedef profil path içindeki `username` ile belirlenir.
- Hedef kullanıcının takip ettiği kullanıcılar döndürülür.

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

`items` elemanları `SocialGraphUserResponse` tipidir.

Kurallar:

- Hedef profil bulunamazsa `404`.
- Hedef profil block nedeniyle görünmezse `404`.
- Oturum sahibine block nedeniyle görünmeyen hesaplar sonuçtan filtrelenir.
- `isFollowedByCurrentUser` her liste öğesi için oturum sahibine göre hesaplanır.
- Sıralama follow ilişkisinin `createdAt DESC` değerine göre yapılır.
- Eşitlikte kullanıcı `id DESC` sırası kullanılır.

Empty state:

~~~json
{
  "items": []
}
~~~

Takip edilen kullanıcı bulunmaması `404` değildir.
## 12. Follows

### 12.1 POST /api/v1/profiles/{username}/follow

Auth: Bearer

Create semantiği:

- Hedef path içindeki `username` ile belirlenir.
- İstek gövdesi yoktur.
- Takip eden kullanıcı JWT üzerinden belirlenir.

Golden request:

~~~http
POST /api/v1/profiles/ada/follow
Authorization: Bearer <accessToken>
~~~

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
{
  "username": "ada",
  "isFollowing": true
}
~~~

Kullanıcı bulunamazsa:

~~~http
404 Not Found
~~~

Block ilişkisi varsa:

~~~http
404 Not Found
~~~

Self-follow:

~~~http
400 Bad Request
~~~

Aynı follow ilişkisini tekrar oluşturma idempotent davranabilir ve duplicate persistence kaydı oluşturmaz.

### 12.2 DELETE /api/v1/profiles/{username}/follow

Auth: Bearer

İstek gövdesi: Yok

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
{
  "username": "ada",
  "isFollowing": false
}
~~~

Follow kaydı bulunmasa da işlem idempotent olarak başarılı kabul edilebilir.

## 13. Feed

### 13.1 GET /api/v1/feed

Auth: Bearer

İstek gövdesi: Yok

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

Boş feed:

~~~json
{
  "items": []
}
~~~

Boş feed `404` değildir.

Feed:

- kronolojik olarak `createdAt DESC` sıralanır,
- eşitlikte `id DESC` kullanılır,
- soft-delete postları içermez,
- moderasyonla gizlenmiş postları içermez,
- block ilişkisi bulunan kullanıcıların postlarını içermez.

## 14. Posts

### 14.1 POST /api/v1/posts

Auth: Bearer

Create semantiği:

- Gövdede id yoktur.
- Author id gövdeden alınmaz; token üzerinden belirlenir.

İstek alanları:

| Alan | Tür | Zorunlu |
|---|---|---|
| `content` | string | Evet |

Golden request:

~~~json
{
  "content": "Merhaba Pulse."
}
~~~

Geçersiz request:

~~~json
{
  "title": "Merhaba Pulse."
}
~~~

Başarı:

~~~http
201 Created
~~~

Golden response:

~~~json
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
~~~

Validation:

- `content` boş olamaz.
- `content` 280 karakteri aşamaz.

### 14.2 DELETE /api/v1/posts/{postId}

Auth: Bearer

İstek gövdesi: Yok

Yalnızca gönderi sahibi kendi gönderisini silebilir.

Başarı:

~~~http
204 No Content
~~~

Post bulunamazsa:

~~~http
404 Not Found
~~~

Başkasının postunu silme:

~~~http
403 Forbidden
~~~

Bu endpoint standart kullanıcı sahiplik silmesidir.

Moderasyon kaldırması için bu endpoint kullanılmaz.

## 15. Replies

### POST /api/v1/posts/{postId}/replies

Auth: Bearer

Create semantiği:

- Parent post path içindeki `postId` ile belirlenir.
- Gövdede id veya `parentPostId` bulunmaz.

İstek alanları:

| Alan | Tür | Zorunlu |
|---|---|---|
| `content` | string | Evet |

Golden request:

~~~json
{
  "content": "Katılıyorum."
}
~~~

Başarı:

~~~http
201 Created
~~~

Golden response:

~~~json
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
~~~

Kurallar:

- `content` maksimum 280 karakter.
- Parent bulunamazsa `404`.
- Soft-delete edilmiş parent için `404`.
- Moderasyonla gizlenmiş parent için `404`.
- Block nedeniyle görünmeyen parent için `404`.
- Parent'ın kendisi reply ise yeni nested reply oluşturulamaz.

## 16. Likes

### 16.1 POST /api/v1/posts/{postId}/likes

Auth: Bearer

İstek gövdesi: Yok

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
{
  "postId": 15,
  "isLiked": true,
  "likeCount": 5
}
~~~

Post bulunamaz veya görünmezse:

~~~http
404 Not Found
~~~

Aynı kullanıcının tekrar like isteği idempotenttir.

### 16.2 DELETE /api/v1/posts/{postId}/likes

Auth: Bearer

İstek gövdesi: Yok

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
{
  "postId": 15,
  "isLiked": false,
  "likeCount": 4
}
~~~

Like bulunmasa da işlem idempotent olarak başarılı kabul edilir.

## 17. Blocks

### 17.1 POST /api/v1/profiles/{username}/block

Auth: Bearer

Create semantiği:

- Hedef path içindeki `username` ile belirlenir.
- İstek gövdesi yoktur.
- Gövdede id veya username gönderilmez.

Golden request:

~~~http
POST /api/v1/profiles/otheruser/block
Authorization: Bearer <accessToken>
~~~

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
{
  "username": "otheruser",
  "isBlocked": true
}
~~~

Yanıt alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `username` | string | Evet | Hayır |
| `isBlocked` | boolean | Evet | Hayır |

Kurallar:

- Kullanıcı kendisini engellerse `400`.
- Hedef kullanıcı bulunamazsa `404`.
- Aynı block tekrar oluşturulursa ikinci kayıt açılmaz.
- Tekrarlanan create yine `200` döndürür.
- Block oluşturulduğunda iki kullanıcı arasındaki mevcut follow ilişkileri kaldırılır.

### 17.2 DELETE /api/v1/profiles/{username}/block

Auth: Bearer

İstek gövdesi: Yok

Golden request:

~~~http
DELETE /api/v1/profiles/otheruser/block
Authorization: Bearer <accessToken>
~~~

Başarı:

~~~http
204 No Content
~~~

Yanıt gövdesi: Yok

Kurallar:

- Block yoksa işlem idempotent olarak yine `204` döndürür.
- Engelin kaldırılması eski follow ilişkilerini geri oluşturmaz.

### 17.3 GET /api/v1/blocks

Auth: Bearer

İstek gövdesi: Yok

Read semantiği:

- Yalnızca oturum sahibinin engellediği kullanıcılar döndürülür.

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

Yanıt alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `items` | array | Evet | Hayır |
| `items[].id` | integer | Evet | Hayır |
| `items[].username` | string | Evet | Hayır |
| `items[].displayName` | string | Evet | Hayır |
| `items[].avatarUrl` | string | Evet | Evet |
| `items[].blockedAt` | UTC ISO 8601 string | Evet | Hayır |

Empty state:

~~~json
{
  "items": []
}
~~~

Kayıt yokken `404` kullanılmaz.

## 18. Reports

### 18.1 POST /api/v1/reports

Auth: Bearer

Create semantiği:

- Gövdede report id bulunmaz.
- Reporter kimliği token üzerinden belirlenir.
- Hedef `targetType` ve `targetId` ile belirlenir.

İstek alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `targetType` | ReportTargetType | Evet | Hayır |
| `targetId` | integer | Evet | Hayır |
| `reason` | ReportReason | Evet | Hayır |
| `details` | string | Hayır | Evet |

`details` maksimum 500 karakterdir.

Golden post-report request:

~~~json
{
  "targetType": "Post",
  "targetId": 15,
  "reason": "Harassment",
  "details": "Repeated targeted insults."
}
~~~

Golden user-report request:

~~~json
{
  "targetType": "User",
  "targetId": 22,
  "reason": "Impersonation",
  "details": null
}
~~~

Alternatif request alanları geçersizdir: `postId`, `userId`, `reportType`, `categoryCode`, `targetIdentifier`.

Başarı:

~~~http
201 Created
~~~

Golden response:

~~~json
{
  "id": 41,
  "targetType": "Post",
  "targetId": 15,
  "reason": "Harassment",
  "details": "Repeated targeted insults.",
  "status": "Pending",
  "createdAt": "2026-08-08T12:15:00Z"
}
~~~

Yanıt alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `id` | integer | Evet | Hayır |
| `targetType` | ReportTargetType | Evet | Hayır |
| `targetId` | integer | Evet | Hayır |
| `reason` | ReportReason | Evet | Hayır |
| `details` | string | Evet | Evet |
| `status` | ReportStatus | Evet | Hayır |
| `createdAt` | UTC ISO 8601 string | Evet | Hayır |

HTTP semantiği:

- Target bulunamazsa `404`.
- Kullanıcı kendi hesabını şikâyet ederse `400`.
- Kullanıcı kendi postunu şikâyet ederse `400`.
- Aynı reporter ve target için `Pending` report varsa `409`.
- Geçersiz enum `400`.
- `details` 500 karakteri aşarsa `400`.
- Report oluşturulması hedefi otomatik kaldırmaz.
## 19. Moderation

Tüm endpoint'ler:

~~~http
Authorization: Bearer <accessToken>
~~~

ve `Moderator` rolü gerektirir.

Normal `User` rolü:

~~~http
403 Forbidden
~~~

### 19.1 GET /api/v1/moderation/reports

Auth: Moderator

İstek gövdesi: Yok

Opsiyonel `status` query değeri paylaşılan `ReportStatus` enum'undan biri olmalıdır:

- `Pending`
- `Resolved`
- `Dismissed`

Query verilmezse varsayılan durum `Pending` olur.

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

Yanıt alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `items` | array | Evet | Hayır |
| `items[].id` | integer | Evet | Hayır |
| `items[].reporterUserId` | integer | Evet | Hayır |
| `items[].targetType` | ReportTargetType | Evet | Hayır |
| `items[].targetId` | integer | Evet | Hayır |
| `items[].reason` | ReportReason | Evet | Hayır |
| `items[].details` | string | Evet | Evet |
| `items[].status` | ReportStatus | Evet | Hayır |
| `items[].createdAt` | UTC ISO 8601 string | Evet | Hayır |
| `items[].resolvedAt` | UTC ISO 8601 string | Evet | Evet |
| `items[].resolvedByUserId` | integer | Evet | Evet |

Empty state:

~~~json
{
  "items": []
}
~~~

Boş kuyruk `404` değildir.

### 19.2 GET /api/v1/moderation/reports/{reportId}

Auth: Moderator

İstek gövdesi: Yok

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
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
~~~

Report bulunamazsa:

~~~http
404 Not Found
~~~

### 19.3 POST /api/v1/moderation/reports/{reportId}/resolve

Auth: Moderator

Update semantiği:

- Report path içindeki `reportId` ile belirlenir.
- Gövdede report id bulunmaz.

İstek alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `action` | ModerationAction | Evet | Hayır |
| `note` | string | Hayır | Evet |

`note` maksimum 500 karakterdir.

Golden RemovePost request:

~~~json
{
  "action": "RemovePost",
  "note": "Content violates harassment policy."
}
~~~

Golden NoAction request:

~~~json
{
  "action": "NoAction",
  "note": null
}
~~~

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
{
  "id": 41,
  "status": "Resolved",
  "action": "RemovePost",
  "resolvedAt": "2026-08-08T12:30:00Z",
  "resolvedByUserId": 3
}
~~~

Yanıt alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `id` | integer | Evet | Hayır |
| `status` | ReportStatus | Evet | Hayır |
| `action` | ModerationAction | Evet | Hayır |
| `resolvedAt` | UTC ISO 8601 string | Evet | Hayır |
| `resolvedByUserId` | integer | Evet | Hayır |

Kurallar:

- Report bulunamazsa `404`.
- Report `Pending` değilse `409`.
- `RemovePost` yalnız `targetType=Post` için geçerlidir.
- `RemovePost` bir User report için kullanılırsa `400`.
- `RemovePost` fiziksel DELETE yapmaz.
- `NoAction` target kaynağı değiştirmez.
- Başarılı işlem audit kaydı oluşturur.

### 19.4 POST /api/v1/moderation/reports/{reportId}/dismiss

Auth: Moderator

Update semantiği:

- Report path içindeki `reportId` ile belirlenir.
- Gövdede id bulunmaz.

İstek alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `note` | string | Hayır | Evet |

`note` maksimum 500 karakterdir.

Golden request:

~~~json
{
  "note": "No policy violation found."
}
~~~

Başarı:

~~~http
200 OK
~~~

Golden response:

~~~json
{
  "id": 41,
  "status": "Dismissed",
  "resolvedAt": "2026-08-08T12:35:00Z",
  "resolvedByUserId": 3
}
~~~

Yanıt alanları:

| Alan | Tür | Zorunlu | Null |
|---|---|---|---|
| `id` | integer | Evet | Hayır |
| `status` | ReportStatus | Evet | Hayır |
| `resolvedAt` | UTC ISO 8601 string | Evet | Hayır |
| `resolvedByUserId` | integer | Evet | Hayır |

Kurallar:

- Report bulunamazsa `404`.
- Report `Pending` değilse `409`.
- Dismiss target kaynağını değiştirmez.
- Başarılı işlem audit kaydı oluşturur.

## 20. Block görünürlük semantiği

Block ilişkisi aşağıdaki mevcut kaynaklarda server-side uygulanır:

- `GET /api/v1/feed`
- `GET /api/v1/profiles/{username}`
- `GET /api/v1/profiles/{username}/posts`
- `GET /api/v1/profiles/{username}/followers`
- `GET /api/v1/profiles/{username}/following`
- `POST /api/v1/profiles/{username}/follow`
- `POST /api/v1/posts/{postId}/likes`
- `POST /api/v1/posts/{postId}/replies`

Kurallar:

- Engelli hesapların postları feed'den filtrelenir.
- İki kullanıcı arasında block varsa yeni follow oluşturulamaz.
- Block nedeniyle görünmeyen profile erişim `404` döndürür.
- Block nedeniyle görünmeyen profilin post/follower/following collection'ları `404` döndürür.
- Followers/following listelerinde oturum sahibine block nedeniyle görünmeyen kullanıcılar `items` sonucundan filtrelenir.
- Block nedeniyle görünmeyen post üzerinde like/reply `404` döndürür.
- Response block ilişkisinin varlığını ayrıca açıklamaz.
- Block oluşturulduğunda iki yöndeki mevcut follow ilişkileri kaldırılır.
- Unblock eski follow ilişkisini geri getirmez.

## 21. Moderasyon ile kaldırılmış gönderi semantiği

`RemovePost` sonucunda moderasyonla gizlenmiş post:

- feed'de dönmez,
- profil gönderileri collection'ında dönmez,
- normal görünür post kabul edilmez,
- yeni like kabul etmez,
- yeni reply kabul etmez.

Görünmeyen post için ilişkili kaynak işlemleri `404 Not Found` döndürür.

Mobil istemci moderasyon kaldırması için standart `DELETE /api/v1/posts/{postId}` endpoint'ini kullanmaz.

Standart DELETE endpoint'inin gönderi sahipliği semantiği değişmez.

## 22. HTTP Create / Update / Read kuralları

### Create

Yeni kaynak create işlemi collection/action `POST` semantiğini kullanır.

Gövdede server tarafından üretilecek kaynak kimliği bulunmaz.

Bu kural:

- register,
- posts,
- replies,
- block,
- reports

create akışları için geçerlidir.

### Update

Mevcut kaynağın güncellenmesi canonical path üzerinden yapılır.

Örnek:

~~~http
PUT /api/v1/me
~~~

Moderasyon state transition işlemleri action endpoint'leri üzerinden gerçekleştirilir:

- `POST /api/v1/moderation/reports/{reportId}/resolve`
- `POST /api/v1/moderation/reports/{reportId}/dismiss`

Request body içinde path kimliği tekrar edilmez.

### Read

Tek kaynağın path ile seçildiği GET endpoint'lerinde kayıt bulunamazsa `404 Not Found` döndürülür.

Profile bağlı collection endpoint'lerinde önce hedef profil görünürlüğü doğrulanır.

Hedef profil bulunamaz veya block nedeniyle görünmezse:

~~~http
404 Not Found
~~~

Hedef profil mevcut fakat collection boşsa:

~~~http
200 OK
~~~

~~~json
{
  "items": []
}
~~~

Bu empty-state davranışı özellikle:

- `GET /api/v1/feed`
- `GET /api/v1/blocks`
- `GET /api/v1/moderation/reports`
- `GET /api/v1/profiles/{username}/posts`
- `GET /api/v1/profiles/{username}/followers`
- `GET /api/v1/profiles/{username}/following`

için geçerlidir.

## 23. Golden sample kuralı

Backend integration testindeki `PostAsJsonAsync` ve `PutAsJsonAsync` request gövdeleri bu dokümandaki golden JSON ile aynı alan adlarını kullanmalıdır.

Post:

~~~json
{
  "content": "Merhaba Pulse."
}
~~~

Reply:

~~~json
{
  "content": "Katılıyorum."
}
~~~

Profile update:

~~~json
{
  "displayName": "İlkan Kişi",
  "bio": "Pulse kullanıcısı",
  "avatarUrl": null
}
~~~

Report:

~~~json
{
  "targetType": "Post",
  "targetId": 15,
  "reason": "Harassment",
  "details": "Repeated targeted insults."
}
~~~

Moderation resolve:

~~~json
{
  "action": "RemovePost",
  "note": "Content violates harassment policy."
}
~~~

Mobil `toJson()` ve request body testleri bu golden gövdelerle aynı alan adlarını ve enum string değerlerini üretmelidir.

Aynı paylaşılan enum/tip için istemci tarafında tek canonical serializer kullanılmalıdır. Endpoint'e göre alternatif enum casing veya farklı serializer tanımlanamaz.

## 24. Enum casing ve serializer kuralı

Enum string değerleri case-sensitive canonical değerlerdir.

`ReportTargetType`:

- `Post`
- `User`

`ReportReason`:

- `Spam`
- `Harassment`
- `HateSpeech`
- `Violence`
- `SexualContent`
- `Impersonation`
- `Other`

`ReportStatus`:

- `Pending`
- `Resolved`
- `Dismissed`

`ModerationAction`:

- `NoAction`
- `RemovePost`

Küçük harfli veya farklı biçimli enum alias'ları geçersizdir.

Örneğin `post`, `user`, `spam`, `harassment`, `pending`, `resolved`, `remove_post` ve `removePost` canonical enum string'i değildir.

Backend integration testlerindeki enum string'leri golden referanstır.

Mobil aynı enum için tek serializer fonksiyonu kullanmalı ve yukarıdaki canonical değerleri birebir üretmelidir.
## 25. Kimlik kararı

Güncel Pulse MVP kaynak kimlikleri integer'dır.

Backend modeli:

~~~text
int Id
~~~

Mobil modeli:

~~~text
final int id;
~~~

API örneği:

~~~json
{
  "id": 1
}
~~~

UUID string kullanılmaz.

## 26. Gönderi alan adları

Bir gönderinin canonical temel JSON property adları `id`, `author`, `content`, `parentPostId`, `createdAt`, `likeCount`, `replyCount` ve `isLikedByMe` şeklindedir.

Kullanıcı tarafından oluşturulan gönderi metninin canonical JSON property adı `content`'tir.

`content` bir enum string değeri değildir ve camelCase JSON property adı olarak kalmalıdır.

Geçersiz alternatif JSON property adları `title`, `description`, `text` ve `body`'dir.

Mobil UI bir gönderi başlığı benzeri görsel öğe üretse bile backend request/response alanını `title` olarak değiştirmez.

§24 içindeki PascalCase zorunluluğu yalnızca paylaşılan enum string değerlerine uygulanır; JSON property adlarına uygulanmaz.

## 27. Profil ve sosyal graf alan adları

Canonical profile response alanları:

- `id`
- `username`
- `displayName`
- `bio`
- `avatarUrl`
- `createdAt`
- `postCount`
- `followerCount`
- `followingCount`
- `isFollowedByCurrentUser`

Canonical `SocialGraphUserResponse` alanları:

- `id`
- `username`
- `displayName`
- `avatarUrl`
- `isFollowedByCurrentUser`

`isFollowedByCurrentUser`, oturum sahibinin response'ta temsil edilen kullanıcıyı takip edip etmediğini ifade eder.

Bu alan yerine ikinci bir alias kullanılmaz.

Özellikle aşağıdaki alternatif alan adları canonical değildir:

- `isFollowing`
- `followedByMe`
- `followingByCurrentUser`
- `isCurrentUserFollowing`

Profile response içindeki `postCount`, yalnız görünür kök gönderilerin sayısıdır.

`followerCount` ve `followingCount`, canonical follow ilişkilerinden hesaplanır.

Followers ve following collection'ları aynı `SocialGraphUserResponse` alan setini kullanır.

Profil gönderileri için ayrı bir post JSON şeması oluşturulmaz; `PostResponse` yeniden kullanılır.

## 28. Güvenlik ve moderasyon hata örnekleri

Self-block:

~~~json
{
  "error": "You cannot block yourself.",
  "field": null
}
~~~

Duplicate pending report:

~~~json
{
  "error": "A pending report already exists for this target.",
  "field": null
}
~~~

Geçersiz report reason:

~~~json
{
  "error": "Invalid report reason.",
  "field": "reason"
}
~~~

Geçersiz moderation action:

~~~json
{
  "error": "Invalid moderation action.",
  "field": "action"
}
~~~

Moderator rolü yok:

~~~json
{
  "error": "You are not authorized to perform this action.",
  "field": null
}
~~~

Daha önce sonuçlandırılmış report:

~~~json
{
  "error": "The report has already been resolved.",
  "field": null
}
~~~

## 29. Authorization özeti

Anonim:

- `GET /health`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`

Bearer:

- `GET /api/v1/me`
- `PUT /api/v1/me`
- `GET /api/v1/profiles/{username}`
- `GET /api/v1/profiles/{username}/posts`
- `GET /api/v1/profiles/{username}/followers`
- `GET /api/v1/profiles/{username}/following`
- `POST /api/v1/profiles/{username}/follow`
- `DELETE /api/v1/profiles/{username}/follow`
- `GET /api/v1/feed`
- `POST /api/v1/posts`
- `DELETE /api/v1/posts/{postId}`
- `POST /api/v1/posts/{postId}/replies`
- `POST /api/v1/posts/{postId}/likes`
- `DELETE /api/v1/posts/{postId}/likes`
- `POST /api/v1/profiles/{username}/block`
- `DELETE /api/v1/profiles/{username}/block`
- `GET /api/v1/blocks`
- `POST /api/v1/reports`

Bearer + Moderator:

- `GET /api/v1/moderation/reports`
- `GET /api/v1/moderation/reports/{reportId}`
- `POST /api/v1/moderation/reports/{reportId}/resolve`
- `POST /api/v1/moderation/reports/{reportId}/dismiss`

## 30. Sosyal Graf collection semantiği

Aşağıdaki endpoint'ler profile bağlı collection endpoint'leridir:

- `GET /api/v1/profiles/{username}/posts`
- `GET /api/v1/profiles/{username}/followers`
- `GET /api/v1/profiles/{username}/following`

Ortak kurallar:

- Bearer token zorunludur.
- Hedef kullanıcı path içindeki `username` ile çözülür.
- Hedef profil bulunamazsa `404`.
- Hedef profil block nedeniyle görünmezse `404`.
- Hedef profil mevcut ve collection boşsa `200`.
- Boş response kesin olarak `{"items":[]}` semantiğini kullanır.
- Block nedeniyle oturum sahibine görünmeyen sosyal graf kullanıcıları listeye dahil edilmez.
- İstemci `404` sonucundan kullanıcının gerçekten bulunmadığı veya block nedeniyle gizlendiği sonucunu ayırt etmeye çalışmaz.

### 30.1 Profil gönderileri sıralaması

Profil gönderileri:

~~~text
createdAt DESC
id DESC
~~~

sırasını kullanır.

Yalnız kök gönderiler döndürülür.

Reply kayıtları profil ana gönderi collection'ına dahil edilmez.

### 30.2 Followers sıralaması

Followers collection'ı follow ilişkisinin oluşturulma zamanına göre:

~~~text
createdAt DESC
~~~

sıralanır.

Eşitlik durumunda response kullanıcısının integer kimliği:

~~~text
id DESC
~~~

ile deterministik sıra sağlanır.

### 30.3 Following sıralaması

Following collection'ı follow ilişkisinin oluşturulma zamanına göre:

~~~text
createdAt DESC
~~~

sıralanır.

Eşitlik durumunda response kullanıcısının integer kimliği:

~~~text
id DESC
~~~

ile deterministik sıra sağlanır.

## 31. Sosyal Graf golden response özeti

### 31.1 Profile

~~~json
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
~~~

### 31.2 Profile posts

~~~json
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
~~~

### 31.3 Followers

~~~json
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
~~~

### 31.4 Following

~~~json
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
~~~

Backend integration testleri ve mobil model/request-response testleri bu alan adlarını birebir kullanmalıdır.

## 32. Tek kaynak kuralı

Bu doküman backend ve mobil arasında API sözleşmesinin tek kaynağıdır.

Backend DTO alanı ile mobil model alanı farklı isim kullanamaz.

Aynı davranış için ikinci route tanımlanamaz.

Legacy fallback kullanılamaz.

Yeni modül eklendiğinde:

- ayrı endpoint bölümü,
- HTTP method + path,
- auth,
- request body alanları,
- response body alanları,
- enum listeleri,
- golden request,
- golden response,
- HTTP semantiği,
- empty-state/404 anlamı

bu dosyada açık şekilde tanımlanmadan implementasyona başlanmamalıdır.

Sosyal Graf & Profil Tamamlama için canonical yeni read endpoint'leri yalnız şunlardır:

~~~text
GET /api/v1/profiles/{username}/posts
GET /api/v1/profiles/{username}/followers
GET /api/v1/profiles/{username}/following
~~~

Bu kaynaklar için `/api/v1/users/...` veya farklı profile route alias'ları oluşturulmaz.