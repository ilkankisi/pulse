# Pulse API Contract

Canonical source: `docs/api-contract.md`.

Backend, Mobile ve QA bu kontrata uyar. JSON alanları camelCase'tir. Kontratta belirtilmeyen alternatif wire alan adları geçersizdir.

## 1. Ortak kurallar

Base URL:

`http://127.0.0.1:5000`

Korumalı endpoint:

```text
Authorization: Bearer <token>

Kimlikler integer'dır.

Tarih/zaman UTC ISO 8601'dir.

Standart hata:

{"error":"message"}

2. Health

GET /health

Auth: anonim

Başarı: 200

{"status":"ok"}

Orchestrator workspace sağlık kontrolü bu endpoint'e bağlıdır.

3. Auth

POST /api/v1/auth/register

Auth: anonim

Request:

username: string, required

email: string, required

password: string, required

Golden request:

{"username":"ada","email":"ada@example.com","password":"Password123!"}

Başarı: 201

Golden response:

{"userId":1,"username":"ada","email":"ada@example.com","accessToken":"<jwt>"}

POST /api/v1/auth/login

Auth: anonim

Request:

email: string, required

password: string, required

Golden request:

{"email":"ada@example.com","password":"Password123!"}

Başarı: 200

Golden response:

{"userId":1,"username":"ada","email":"ada@example.com","accessToken":"<jwt>"}

Development JWT:

Jwt:Key ≥32 byte

Jwt:Issuer

Jwt:Audience

Production secret repository'de tutulmaz.

4. Shared PostResponse

PostKind:

Post

Repost

Quote

MediaType:

Image

Video

PostMediaResponse:

id: integer

url: string

mediaType: Image | Video

contentType: string

width: integer|null

height: integer|null

PostResponse:

id: integer

authorId: integer

authorUsername: string

text: string

createdAt: string

likeCount: integer

replyCount: integer

repostCount: integer

isLiked: boolean

isBookmarked: boolean

kind: Post | Repost | Quote

originalPost: PostResponse | null

media: PostMediaResponse[]

Normal post golden response:

{
  "id":10,
  "authorId":1,
  "authorUsername":"ada",
  "text":"Merhaba Pulse",
  "createdAt":"2026-08-18T20:00:00Z",
  "likeCount":2,
  "replyCount":1,
  "repostCount":0,
  "isLiked":false,
  "isBookmarked":false,
  "kind":"Post",
  "originalPost":null,
  "media":[]
}

5. Feed

GET /api/v1/feed

Auth: Bearer

Query:

cursor: string, optional

limit: integer, optional

Başarı: 200

Response:

items: PostResponse[]

nextCursor: string|null

Golden response:

{
  "items":[
    {
      "id":10,
      "authorId":1,
      "authorUsername":"ada",
      "text":"Merhaba Pulse",
      "createdAt":"2026-08-18T20:00:00Z",
      "likeCount":2,
      "replyCount":1,
      "repostCount":0,
      "isLiked":false,
      "isBookmarked":false,
      "kind":"Post",
      "originalPost":null,
      "media":[]
    }
  ],
  "nextCursor":null
}

Empty:

{"items":[],"nextCursor":null}

Feed empty durumunda 404 kullanılmaz.

Feed kronolojiktir; trend/For You sıralaması yoktur.

6. Post detail

GET /api/v1/posts/{postId}

Auth: Bearer

Başarı: 200, tam PostResponse.

Golden response:

{
  "id":10,
  "authorId":1,
  "authorUsername":"ada",
  "text":"Merhaba Pulse",
  "createdAt":"2026-08-18T20:00:00Z",
  "likeCount":2,
  "replyCount":1,
  "repostCount":0,
  "isLiked":false,
  "isBookmarked":false,
  "kind":"Post",
  "originalPost":null,
  "media":[]
}

Bulunamazsa 404; bu empty collection değildir.

7. Post create

POST /api/v1/posts

Auth: Bearer

Create gövdesinde kimlik yoktur.

Request:

text: string, required, maksimum 280 karakter

mediaIds: integer[], required; text-only için boş olabilir

Golden text-only request:

{"text":"İlk gönderim","mediaIds":[]}

Golden media request:

{"text":"Merhaba #pulse @ada","mediaIds":[12]}

Başarı: 201, PostResponse.

Text-only post geriye uyumludur. Media, mention, hashtag, repost veya quote zorunlu değildir.

8. Delete post

DELETE /api/v1/posts/{postId}

Auth: Bearer

Yalnız owner silebilir.

Başarı: 204.

Bulunamazsa 404.

9. Replies

GET /api/v1/posts/{postId}/replies

Auth: Bearer

Başarı: 200

{"items":[],"nextCursor":null}

Empty collection 200 döner.

POST /api/v1/posts/{postId}/replies

Auth: Bearer

Request:

text: string, required

Golden request:

{"text":"Katılıyorum"}

Başarı: 201.

Reply nesting bu fazda yoktur.

10. Likes

POST /api/v1/posts/{postId}/likes

Auth: Bearer

Body yok.

Başarı: 204.

Aynı user + post duplicate aktif like üretmez.

DELETE /api/v1/posts/{postId}/likes

Auth: Bearer

Başarı: 204.

İlişki yoksa 404.

11. Repost

POST /api/v1/posts/{postId}/reposts

Auth: Bearer

Body yok.

Golden request:

POST /api/v1/posts/10/reposts
Authorization: Bearer <token>
<empty body>

Başarı: 201.

Golden response:

{
  "id":50,
  "authorId":7,
  "authorUsername":"ilkan",
  "text":"",
  "createdAt":"2026-08-19T00:00:00Z",
  "likeCount":0,
  "replyCount":0,
  "repostCount":0,
  "isLiked":false,
  "isBookmarked":false,
  "kind":"Repost",
  "originalPost":{
    "id":10,
    "authorId":1,
    "authorUsername":"ada",
    "text":"Merhaba",
    "createdAt":"2026-08-18T20:00:00Z",
    "likeCount":2,
    "replyCount":1,
    "repostCount":1,
    "isLiked":false,
    "isBookmarked":false,
    "kind":"Post",
    "originalPost":null,
    "media":[]
  },
  "media":[]
}

Aynı current user + postId için ikinci aktif repost oluşturulamaz.

DELETE /api/v1/posts/{postId}/reposts

Auth: Bearer

Başarı: 204.

İlişki yoksa 404.

12. Quote

POST /api/v1/posts/{postId}/quotes

Auth: Bearer

Request:

text: string, required, maksimum 280 karakter

mediaIds: integer[], required

Golden request:

{"text":"Buna katılıyorum","mediaIds":[]}

Başarı: 201.

Golden response:

{
  "id":51,
  "authorId":7,
  "authorUsername":"ilkan",
  "text":"Buna katılıyorum",
  "createdAt":"2026-08-19T00:05:00Z",
  "likeCount":0,
  "replyCount":0,
  "repostCount":0,
  "isLiked":false,
  "isBookmarked":false,
  "kind":"Quote",
  "originalPost":{
    "id":10,
    "authorId":1,
    "authorUsername":"ada",
    "text":"Merhaba",
    "createdAt":"2026-08-18T20:00:00Z",
    "likeCount":2,
    "replyCount":1,
    "repostCount":1,
    "isLiked":false,
    "isBookmarked":false,
    "kind":"Post",
    "originalPost":null,
    "media":[]
  },
  "media":[]
}

13. Bookmark

POST /api/v1/posts/{postId}/bookmarks

Auth: Bearer

Body yok.

Başarı: 204.

Aynı user + post duplicate bookmark üretmez.

DELETE /api/v1/posts/{postId}/bookmarks

Auth: Bearer

Başarı: 204.

İlişki yoksa 404.

GET /api/v1/bookmarks

Auth: Bearer

Query:

cursor: string, optional

limit: integer, optional

Response:

{"items":[],"nextCursor":null}

items: PostResponse[].

Empty: 200 + boş items.

14. Notifications

NotificationType canonical string değerleri yalnızca:

Like

Reply

Follow

Mention

NotificationResponse:

id: integer

type: NotificationType

actorUserId: integer

actorUsername: string

postId: integer|null

isRead: boolean

createdAt: string

GET /api/v1/notifications

Auth: Bearer

Golden response:

{
  "items":[
    {
      "id":41,
      "type":"Mention",
      "actorUserId":1,
      "actorUsername":"ada",
      "postId":88,
      "isRead":false,
      "createdAt":"2026-08-19T00:10:00Z"
    }
  ],
  "nextCursor":null
}

Empty: 200 + boş items.

PUT /api/v1/notifications/{notificationId}/read

Auth: Bearer

Request:

{"isRead":true}

Başarı:

{
  "id":41,
  "type":"Mention",
  "actorUserId":1,
  "actorUsername":"ada",
  "postId":88,
  "isRead":true,
  "createdAt":"2026-08-19T00:10:00Z"
}

Bulunamazsa veya current user'a ait değilse 404.

15. Mention

Mention ayrı create endpoint değildir.

Post/quote text içindeki @username backend tarafından çözülür.

Kesin davranış:

mevcut username → mention relation

recipient author'dan farklıysa → Mention notification

aynı postta aynı recipient tekrar mention edilirse → tek relation + tek notification

bulunmayan username → notification yok

Golden text:

{"text":"Merhaba @ada","mediaIds":[]}

16. Hashtag

Hashtag ayrı create endpoint değildir.

Post/quote text içindeki #tag normalize edilir.

GET /api/v1/hashtags/{tag}/posts

Auth: Bearer

Query:

cursor: string, optional

limit: integer, optional

Golden response:

{"tag":"flutter","items":[],"nextCursor":null}

items: PostResponse[].

Empty: 200.

Hashtag özelliğinde trend endpoint'i, trend skoru veya popularity-based sıralama yoktur.

17. Media

POST /api/v1/media

Auth: Bearer

Content-Type: multipart/form-data

Alan:

file: binary, required

Golden request:

POST /api/v1/media
Authorization: Bearer <token>
Content-Type: multipart/form-data

file=<binary>

Desteklenen media enum:

Image

Video

Image golden response:

{"id":12,"url":"http://127.0.0.1:5000/api/v1/media/12/content","mediaType":"Image","contentType":"image/jpeg","width":1200,"height":800}

Video golden response:

{"id":13,"url":"http://127.0.0.1:5000/api/v1/media/13/content","mediaType":"Video","contentType":"video/mp4","width":1920,"height":1080}

Başarı: 201.

Media current user'a aittir. Başka kullanıcıya ait mediaIds post/quote create içinde kabul edilmez.

Binary MinIO'da, metadata PostgreSQL'de tutulur.

18. Follow

POST /api/v1/profiles/{username}/follow

Auth: Bearer

Body yok.

Başarı: 204.

Duplicate aktif follow oluşturulamaz.

DELETE /api/v1/profiles/{username}/follow

Auth: Bearer

Başarı: 204.

19. Followers removal

DELETE /api/v1/profiles/{username}/followers/{followerId}

Auth: Bearer

Profile owner yetkisi gerekir.

Başarı: 204.

20. HTTP semantics

Create:

POST

create body içinde resource id yok

Update:

PUT

notification read state örneği yukarıda tanımlıdır

Read:

collection boşsa 200 + boş items

tekil resource yoksa 404

Delete:

başarı 204

kontratta tanımlanan bulunamama durumları 404

Auth:

401 → session/auth error

Mobile Login akışına döner

Server failure:

5xx → error state

empty state değildir

21. Mobile state contract

Zorunlu state'ler:

Feed: loading / empty / error / success

Post Detail: loading / not-found / error / success

Notifications: loading / empty / error / success

Kaydedilenler: loading / empty / error / success

Hashtag Posts: loading / empty / error / success

Composer/Media: idle / uploading / upload-error / ready / submitting / submit-error

Feed/Profile/Kaydedilenler/Hashtag yüzeyleri aynı PostResponse alanlarını kullanır.

Repost ve Quote için original içerik originalPost üzerinden parse edilir.

22. CORS

Flutter Web:

http://127.0.0.1:8080

API:

http://127.0.0.1:5000

Backend:

CORS sağlar

OPTIONS destekler

Authorization header'a izin verir

Content-Type header'a izin verir

23. Golden sample governance

Backend integration testlerindeki PostAsJsonAsync / PutAsJsonAsync gövdeleri bu dokümandaki kesin alan adlarıyla eşleşmelidir.

Mobile kontratta bulunmayan alternatif adlar kullanamaz.

Örneğin kontratta text varsa aşağıdakiler geçersizdir:

title

description

body

Canonical doküman Backend veya Mobile uygulama görevi içinde değiştirilmez.