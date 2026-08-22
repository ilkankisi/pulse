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

Standart hata gövdesi:

{"error":"message"}

HTTP status kodu endpoint bölümünde aksi belirtilmedikçe gövdenin anlamını belirler.

2. Health

GET /health

Auth: anonim.

Başarı: 200

{"status":"ok"}

Bu endpoint /api/v1 CRUD kaynaklarından ayrıdır.

Orchestrator workspace sağlık kontrolü doğrudan GET /health endpoint'ine bağlıdır.

3. Auth

POST /api/v1/auth/register

Auth: anonim.

Request alanları:

username: string, required

email: string, required

password: string, required

Golden request:

{"username":"ada","email":"ada@example.com","password":"Password123!"}

Başarı: 201

Golden response:

{"userId":1,"username":"ada","email":"ada@example.com","accessToken":"<jwt>"}

POST /api/v1/auth/login

Auth: anonim.

Request alanları:

email: string, required

password: string, required

Golden request:

{"email":"ada@example.com","password":"Password123!"}

Başarı: 200

Golden response:

{"userId":1,"username":"ada","email":"ada@example.com","accessToken":"<jwt>"}

Development JWT gereksinimleri:

appsettings.Development.json içinde Jwt:Key

Jwt:Key en az 32 byte

Jwt:Issuer

Jwt:Audience

Orchestrator backend'i ASPNETCORE_ENVIRONMENT=Development ile başlattığından development JWT configuration hazır olmalıdır.

Production'da Jwt:Key repository içinde tutulmaz; environment variable veya secret store zorunludur.

4. Paylaşılan tipler

PostKind

Canonical string değerleri:

Post

Repost

Quote

MediaType

Canonical string değerleri:

Image

Video

AuthorResponse

Alanlar:

id: integer

username: string

displayName: string

avatarUrl: string|null

PostMediaResponse

Alanlar:

id: integer

url: string

mediaType: Image | Video

contentType: string

width: integer|null

height: integer|null

PostResponse

Alanlar:

id: integer

content: string

createdAt: string

author: AuthorResponse

likeCount: integer

replyCount: integer

repostCount: integer

isLikedByMe: boolean

isBookmarked: boolean

parentPostId: integer|null

kind: Post | Repost | Quote

originalPost: PostResponse | null

media: PostMediaResponse[]

Backward compatibility kuralı:

Sosyal Etkileşim Fazı mevcut /api/v1 post DTO alanlarını yeniden adlandırmaz.

Gönderi metninin canonical wire alanı yalnızca content'tir.

Aşağıdaki alternatifler geçersizdir:

text

title

description

body

Normal post golden response:

{
  "id":10,
  "content":"Merhaba Pulse",
  "createdAt":"2026-08-18T20:00:00Z",
  "author":{
    "id":1,
    "username":"ada",
    "displayName":"Ada",
    "avatarUrl":null
  },
  "likeCount":2,
  "replyCount":1,
  "repostCount":0,
  "isLikedByMe":false,
  "isBookmarked":false,
  "parentPostId":null,
  "kind":"Post",
  "originalPost":null,
  "media":[]
}

Feed ve Post Detail aynı PostResponse shape'ini kullanır.

5. Feed

GET /api/v1/feed

Auth: Bearer.

Query:

cursor: string, optional

limit: integer, optional

Başarı: 200

Response alanları:

items: PostResponse[]

nextCursor: string|null

Golden response:

{
  "items":[
    {
      "id":10,
      "content":"Merhaba Pulse",
      "createdAt":"2026-08-18T20:00:00Z",
      "author":{
        "id":1,
        "username":"ada",
        "displayName":"Ada",
        "avatarUrl":null
      },
      "likeCount":2,
      "replyCount":1,
      "repostCount":0,
      "isLikedByMe":false,
      "isBookmarked":false,
      "parentPostId":null,
      "kind":"Post",
      "originalPost":null,
      "media":[]
    }
  ],
  "nextCursor":null
}

Empty golden response:

{"items":[],"nextCursor":null}

Feed boşken 404 kullanılmaz.

Feed kronolojiktir. Algoritmik “For You”, trend skoru veya trend sıralaması bu fazda yoktur.

6. Post detail

GET /api/v1/posts/{postId}

Auth: Bearer.

Başarı: 200

Response: tam PostResponse.

Golden response:

{
  "id":10,
  "content":"Merhaba Pulse",
  "createdAt":"2026-08-18T20:00:00Z",
  "author":{
    "id":1,
    "username":"ada",
    "displayName":"Ada",
    "avatarUrl":null
  },
  "likeCount":2,
  "replyCount":1,
  "repostCount":0,
  "isLikedByMe":false,
  "isBookmarked":false,
  "parentPostId":null,
  "kind":"Post",
  "originalPost":null,
  "media":[]
}

Post bulunamazsa 404.

Bu 404 collection empty-state değildir.

7. Post oluşturma

POST /api/v1/posts

Auth: Bearer.

Create gövdesinde resource kimliği bulunmaz.

Request alanları:

content: string, required, maksimum 280 karakter

mediaIds: integer[], optional

Mevcut text-only golden request:

{"content":"İlk gönderim"}

Bu request backward-compatible kalır.

Media alanı kullanmayan istemcinin mediaIds göndermesi zorunlu değildir.

Media post golden request:

{"content":"Merhaba #pulse @ada","mediaIds":[12]}

Başarı: 201

Response: PostResponse.

content 280 karakteri aşarsa validation error döner.

Media, mention, hashtag, repost veya quote normal text-only post oluşturmak için zorunlu değildir.

8. Post silme

DELETE /api/v1/posts/{postId}

Auth: Bearer.

Yalnız resource owner silebilir.

Başarı: 204

Post bulunamazsa 404.

9. Replies

GET /api/v1/posts/{postId}/replies

Auth: Bearer.

Başarı: 200

Response:

items: PostResponse[]

nextCursor: string|null

Empty golden response:

{"items":[],"nextCursor":null}

POST /api/v1/posts/{postId}/replies

Auth: Bearer.

Request:

content: string, required, maksimum 280 karakter

Golden request:

{"content":"Katılıyorum"}

Başarı: 201

Reply response canonical post/reply DTO shape'ini kullanır.

Bu fazda reply-to-reply nesting yoktur.

10. Likes

POST /api/v1/posts/{postId}/likes

Auth: Bearer.

Request body yoktur.

Başarı: 204

Aynı user + post için duplicate aktif like oluşturulamaz.

DELETE /api/v1/posts/{postId}/likes

Auth: Bearer.

Başarı: 204

İlişki yoksa 404.

11. Repost

POST /api/v1/posts/{postId}/reposts

Auth: Bearer.

Request body yoktur.

Golden request:

POST /api/v1/posts/10/reposts
Authorization: Bearer <token>
<empty body>

Başarı: 201

Golden response:

{
  "id":50,
  "content":"",
  "createdAt":"2026-08-19T00:00:00Z",
  "author":{
    "id":7,
    "username":"ilkan",
    "displayName":"İlkan",
    "avatarUrl":null
  },
  "likeCount":0,
  "replyCount":0,
  "repostCount":0,
  "isLikedByMe":false,
  "isBookmarked":false,
  "parentPostId":null,
  "kind":"Repost",
  "originalPost":{
    "id":10,
    "content":"Merhaba",
    "createdAt":"2026-08-18T20:00:00Z",
    "author":{
      "id":1,
      "username":"ada",
      "displayName":"Ada",
      "avatarUrl":null
    },
    "likeCount":2,
    "replyCount":1,
    "repostCount":1,
    "isLikedByMe":false,
    "isBookmarked":false,
    "parentPostId":null,
    "kind":"Post",
    "originalPost":null,
    "media":[]
  },
  "media":[]
}

Aynı current user + postId için ikinci aktif repost oluşturulamaz.

DELETE /api/v1/posts/{postId}/reposts

Auth: Bearer.

Request body yoktur.

Başarı: 204

İlişki yoksa 404.

12. Quote post

POST /api/v1/posts/{postId}/quotes

Auth: Bearer.

Request alanları:

content: string, required, maksimum 280 karakter

mediaIds: integer[], optional

Golden request:

{"content":"Buna katılıyorum"}

Başarı: 201

Golden response:

{
  "id":51,
  "content":"Buna katılıyorum",
  "createdAt":"2026-08-19T00:05:00Z",
  "author":{
    "id":7,
    "username":"ilkan",
    "displayName":"İlkan",
    "avatarUrl":null
  },
  "likeCount":0,
  "replyCount":0,
  "repostCount":0,
  "isLikedByMe":false,
  "isBookmarked":false,
  "parentPostId":null,
  "kind":"Quote",
  "originalPost":{
    "id":10,
    "content":"Merhaba",
    "createdAt":"2026-08-18T20:00:00Z",
    "author":{
      "id":1,
      "username":"ada",
      "displayName":"Ada",
      "avatarUrl":null
    },
    "likeCount":2,
    "replyCount":1,
    "repostCount":1,
    "isLikedByMe":false,
    "isBookmarked":false,
    "parentPostId":null,
    "kind":"Post",
    "originalPost":null,
    "media":[]
  },
  "media":[]
}

Quote yeni bir Post resource'dur; repost toggle ilişkisi değildir.

13. Bookmark / Kaydedilenler

POST /api/v1/posts/{postId}/bookmarks

Auth: Bearer.

Request body yoktur.

Başarı: 204

Aynı user + post için duplicate aktif bookmark oluşturulamaz.

DELETE /api/v1/posts/{postId}/bookmarks

Auth: Bearer.

Başarı: 204

İlişki yoksa 404.

GET /api/v1/bookmarks

Auth: Bearer.

Query:

cursor: string, optional

limit: integer, optional

Başarı: 200

Response alanları:

items: PostResponse[]

nextCursor: string|null

Golden response:

{"items":[],"nextCursor":null}

Boş liste 200 + boş items döndürür.

14. Notifications

NotificationType

Canonical string değerleri yalnızca:

Like

Reply

Follow

Mention

Alternatif casing veya token geçersizdir.

NotificationResponse

Alanlar:

id: integer

type: Like | Reply | Follow | Mention

actorUserId: integer

actorUsername: string

postId: integer|null

isRead: boolean

createdAt: string

GET /api/v1/notifications

Auth: Bearer.

Query:

cursor: string, optional

limit: integer, optional

Başarı: 200

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

Empty:

{"items":[],"nextCursor":null}

PUT /api/v1/notifications/{notificationId}/read

Auth: Bearer.

Read request:

{"isRead":true}

Unread request:

{"isRead":false}

Başarı: 200

Golden response:

{
  "id":41,
  "type":"Mention",
  "actorUserId":1,
  "actorUsername":"ada",
  "postId":88,
  "isRead":true,
  "createdAt":"2026-08-19T00:10:00Z"
}

Notification bulunamazsa veya current user'a ait değilse 404.

Read/unread update aynı notification resource'unu değiştirir; yeni notification oluşturmaz.

15. Mention

Mention ayrı create endpoint değildir.

Post ve quote content alanındaki @username backend tarafından çözümlenir.

Kesin davranış:

username mevcutsa mention relation oluşturulur

mention edilen kullanıcı author'dan farklıysa Mention notification üretilir

aynı post içinde aynı recipient birden fazla kez mention edilirse tek relation ve tek notification oluşur

bulunmayan/geçersiz username notification üretmez

Golden request:

{"content":"Merhaba @ada"}

Mention seçimi istemcide ilgili Profile ekranına yönlenir; bu presentation davranışıdır ve wire alanını değiştirmez.

16. Hashtag

Hashtag ayrı create endpoint değildir.

Post ve quote content alanındaki #tag backend tarafından normalize edilir.

GET /api/v1/hashtags/{tag}/posts

Auth: Bearer.

Query:

cursor: string, optional

limit: integer, optional

Başarı: 200

Golden response:

{"tag":"flutter","items":[],"nextCursor":null}

Response:

tag: string

items: PostResponse[]

nextCursor: string|null

Boş hashtag sonucu 200 + boş items döndürür.

Hashtag özelliği yalnız ilgili normalize tag'e bağlı gönderileri listeler.

Bu fazda:

trend endpoint'i yoktur

trend skoru yoktur

trend/ranking listesi yoktur

popularity-based hashtag sıralaması yoktur

17. Media

POST /api/v1/media

Auth: Bearer.

Content-Type: multipart/form-data

Request alanı:

file: binary, required

Golden request:

POST /api/v1/media
Authorization: Bearer <token>
Content-Type: multipart/form-data

file=<binary>

Desteklenen MediaType değerleri:

Image

Video

Başarı: 201

Image golden response:

{"id":12,"url":"http://127.0.0.1:5000/api/v1/media/12/content","mediaType":"Image","contentType":"image/jpeg","width":1200,"height":800}

Video golden response:

{"id":13,"url":"http://127.0.0.1:5000/api/v1/media/13/content","mediaType":"Video","contentType":"video/mp4","width":1920,"height":1080}

Media current user'a aittir.

Başka kullanıcıya ait media id POST /api/v1/posts veya quote create içinde kullanılamaz.

Binary MinIO'da, metadata PostgreSQL'de tutulur.

Tek görselli post golden akışı

POST /api/v1/media başarılı olur ve media id = 12 döner.

Mobile bu id'yi post create gövdesinde kullanır:

{"content":"Görselli gönderi","mediaIds":[12]}

POST /api/v1/posts → 201

{
  "id":52,
  "content":"Görselli gönderi",
  "createdAt":"2026-08-19T00:15:00Z",
  "author":{
    "id":7,
    "username":"ilkan",
    "displayName":"İlkan",
    "avatarUrl":null
  },
  "likeCount":0,
  "replyCount":0,
  "repostCount":0,
  "isLikedByMe":false,
  "isBookmarked":false,
  "parentPostId":null,
  "kind":"Post",
  "originalPost":null,
  "media":[
    {
      "id":12,
      "url":"http://127.0.0.1:5000/api/v1/media/12/content",
      "mediaType":"Image",
      "contentType":"image/jpeg",
      "width":1200,
      "height":800
    }
  ]
}

Bu akış Sosyal Etkileşim Fazı için en az tek görselli post acceptance örneğidir.

18. Follow

POST /api/v1/profiles/{username}/follow

Auth: Bearer.

Request body yoktur.

Başarı: 204

Duplicate aktif follow oluşturulamaz.

DELETE /api/v1/profiles/{username}/follow

Auth: Bearer.

Başarı: 204

19. Followers removal

DELETE /api/v1/profiles/{username}/followers/{followerId}

Auth: Bearer.

Profile owner yetkisi gerekir.

Başarı: 204

20. HTTP semantiği

Create:

POST

create request body içinde resource id bulunmaz

Update:

PUT

notification read/unread state bu semantiği kullanır

Read:

collection boşsa 200 + boş items

tekil resource bulunamazsa 404

Delete:

başarı 204

kontratta belirtilen bulunamama durumları 404

Auth:

401 auth/session error

Mobile Login akışına döner

Server failure:

5xx error state

empty state değildir

21. Mobile / Design state kontratı

Canonical API davranışından türeyen zorunlu state'ler:

Feed: loading / empty / error / success

Post Detail: loading / not-found / error / success

Notifications: loading / empty / error / success

Kaydedilenler: loading / empty / error / success

Hashtag Posts: loading / empty / error / success

Composer/Media: idle / uploading / upload-error / ready / submitting / submit-error

HTTP eşlemesi:

collection 200 + items: [] → empty

tekil resource 404 → not-found

401 → Login

5xx → error

Feed, Profile, Kaydedilenler ve Hashtag Posts aynı PostResponse alanlarını kullanır.

kind = Repost ve kind = Quote için original içerik originalPost üzerinden parse edilir.

Media post media alanından parse edilir.

22. CORS

Flutter Web origin:

http://127.0.0.1:8080

API:

http://127.0.0.1:5000

Backend:

CORS sağlar

preflight OPTIONS destekler

Authorization header'a izin verir

Content-Type header'a izin verir

gerekli REST metotlarına izin verir

23. Golden sample governance

Backend integration testlerindeki PostAsJsonAsync ve PutAsJsonAsync gövdeleri bu dokümandaki kesin camelCase alan adlarıyla eşleşmelidir.

Mobile canonical kontratta bulunmayan alternatif alan adlarını kullanamaz.

Gönderi metninin tek canonical JSON alanı:

content

Geçersiz alternatifler:

text

title

description

body

Canonical docs/api-contract.md Backend veya Mobile uygulama görevi kapsamında patch edilmez.

Kontrat değişikliği ayrı Architect görevidir.

24. Acceptance doğrulama matrisi

Sosyal Etkileşim Fazı canonical kanıtları:

DavranışCanonical kanıt
Text-only postPOST /api/v1/posts, {"content":"..."}, maksimum 280 karakter
Feed DTOGET /api/v1/feed → PostResponse[]
Post-detail DTOGET /api/v1/posts/{postId} → PostResponse
Repost createPOST /api/v1/posts/{postId}/reposts, empty body, 201
Repost removeDELETE /api/v1/posts/{postId}/reposts, 204
QuotePOST /api/v1/posts/{postId}/quotes, content, 201
Bookmark savePOST /api/v1/posts/{postId}/bookmarks
Bookmark removeDELETE /api/v1/posts/{postId}/bookmarks
Bookmark listGET /api/v1/bookmarks
NotificationsGET /api/v1/notifications
Notification readPUT .../read, {"isRead":true}
Notification unreadPUT .../read, {"isRead":false}
Notification typesLike, Reply, Follow, Mention
Valid mentionexisting @username → relation + eligible Mention notification
Invalid mentionnotification yok
Duplicate mentiontek relation + tek notification
Hashtagilgili postları listeler; trend/ranking yok
Mediaupload → media id → mediaIds → populated media[]
Backward compatibilitymevcut content field ve 280 karakter korunur