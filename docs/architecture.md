# Pulse — Teknik Mimari

## 1. Amaç ve kapsam

Pulse, .NET 8 ASP.NET Core backend ile Flutter mobile/web istemcisinden oluşan sosyal etkileşim uygulamasıdır.

Bu faz aşağıdaki yetenekleri kapsar:

- kayıt ve giriş
- kullanıcı profili
- takip / takipten çıkarma
- kronolojik feed
- en fazla 280 karakter text-only gönderi
- yanıt
- beğeni
- repost
- quote post
- bookmark / Kaydedilenler
- notification
- mention
- hashtag
- gönderi medyası
- engelleme
- şikâyet
- moderasyon

Bu faz DM, poll, trend, trend skoru veya algoritmik “For You” feed içermez.

Canonical API kaynağı `docs/api-contract.md`, canonical veri modeli `docs/database-model.md` dosyasıdır.

Backend ve Mobile ajanları canonical dokümanları uygulama görevi kapsamında değiştirmez; kontrat değişikliği ayrı Architect görevidir.

## 2. Teknoloji ve altyapı

Backend:

- .NET 8
- ASP.NET Core
- Entity Framework Core
- PostgreSQL
- JWT Bearer authentication

Mobile/Web:

- Flutter
- Dart
- REST/JSON istemcisi

Altyapı:

- PostgreSQL: kalıcı ilişkisel veri
- MinIO: görsel/video binary nesneleri
- Redis: bu faz için zorunlu değildir

`docker-compose.yml` Infra Agent sorumluluğundadır.

Architect yalnız altyapı gereksinimini tanımlar; compose dosyasını üretmez.

## 3. Orchestrator health

Orchestrator backend'i:

- `dotnet run --no-launch-profile`
- `ASPNETCORE_ENVIRONMENT=Development`

ile başlatır.

API:

`http://127.0.0.1:5000`

Health endpoint'i CRUD kaynaklarından ayrı canonical sistem endpoint'idir:

`GET /health`

Başarı:

```json
{"status":"ok"}

HTTP status 200 olmalıdır.

GET /health anonimdir ve workspace başlangıç sağlık kontrolü buna bağlıdır.

4. JWT

Anonim endpoint'ler:

GET /health

POST /api/v1/auth/register

POST /api/v1/auth/login

Korumalı endpoint'ler:

Authorization: Bearer <token>

Development

appsettings.Development.json şu ayarları sağlamalıdır:

Jwt:Key: en az 32 byte

Jwt:Issuer

Jwt:Audience

Orchestrator Development ortamında çalıştığından local JWT configuration hazır olmalıdır.

Development başlatması production secret yokluğu nedeniyle çökmemelidir.

Production

Production Jwt:Key repository içinde tutulmaz.

Jwt:Key environment variable veya secret store üzerinden sağlanmalıdır.

5. CORS

Flutter Web origin:

http://127.0.0.1:8080

Backend:

http://127.0.0.1:5000

Backend CORS policy:

Flutter Web origin'ine izin verir

Authorization başlığına izin verir

Content-Type başlığına izin verir

gerekli HTTP metotlarına izin verir

preflight OPTIONS isteklerini destekler

CORS authorization yerine geçmez.

6. Backend ve Mobile sorumluluk sınırı

Backend

Backend:

JWT doğrular

ownership kontrol eder

canonical camelCase JSON üretir/tüketir

sosyal ilişki uniqueness kurallarını uygular

block filtrelerini uygular

mention ve hashtag çözümlemesini yapar

notification üretir

notification read/unread state'ini kalıcı tutar

medya ownership kontrolü yapar

MinIO/PostgreSQL koordinasyonunu yönetir

Flutter

Flutter:

canonical JSON alanlarını birebir parse eder

alternatif wire alan adı üretmez

token'ı Bearer header ile gönderir

loading/empty/not-found/error/success state'lerini gösterir

canonical pagination bilgisini kullanır

@username → Profile

#tag → Hashtag Posts

post ilişkili notification → Post Detail

Follow notification → Profile

UI etiketi wire-format alanından farklı olabilir; bu yalnız presentation mapping'dir.

7. Post modeli ve backward compatibility

Canonical post türleri:

Post

Repost

Quote

Mevcut text-only gönderi davranışı korunur.

Canonical post metni wire alanı:

content

Kurallar:

content maksimum 280 karakter

media zorunlu değildir

mention zorunlu değildir

hashtag zorunlu değildir

repost/quote kullanımı normal post create akışını bozmaz

mevcut { "content": "..." } request shape'i backward-compatible kalır

Feed ve Post Detail aynı canonical PostResponse modelini kullanır.

Yeni sosyal alanlar additive'dir:

repostCount

isBookmarked

kind

originalPost

media

8. Repost ve Quote

Repost

Repost mevcut gönderiyi yeniden paylaşır.

Invariant:

kind = Repost

originalPost hedef gönderiyi gösterir

aynı kullanıcı + aynı original post için tek aktif repost bulunabilir

retry/double-tap duplicate repost üretmez

Quote

Quote yeni bir Post resource'dur.

Invariant:

kind = Quote

quote sahibinin content alanı vardır

originalPost hedef gönderiyi gösterir

quote kendi like/reply/bookmark durumuna sahiptir

repost uniqueness kuralı quote'a uygulanmaz

9. Bookmark

Bookmark kullanıcıya özeldir.

Kurallar:

public sayaç değildir

başka kullanıcıya gösterilmez

aynı user + post için tek aktif bookmark vardır

Kaydedilenler ekranının server-side veri kaynağıdır

10. Notification

Canonical notification tipleri:

Like

Reply

Follow

Mention

Notification recipient kullanıcıya aittir.

Read/unread durumu backend'de kalıcıdır.

Aynı source interaction retry edildiğinde duplicate notification üretilmemelidir.

11. Mention

Canonical gösterim:

@username

Kurallar:

backend username'i çözümler

yalnız mevcut/geçerli kullanıcı mention relation oluşturur

recipient author'dan farklıysa Mention notification üretilir

aynı postta aynı kullanıcı tekrar mention edilirse tek relation ve tek notification oluşur

bulunmayan/geçersiz username notification üretmez

12. Hashtag

Canonical gösterim:

#tag

Backend normalize edilmiş hashtag ilişkisini oluşturur.

Hashtag ekranı seçili tag ile ilişkili gönderileri listeler.

Bu fazda:

trend endpoint'i yoktur

trend skoru yoktur

trend/ranking listesi yoktur

popularity-based hashtag sıralaması yoktur

13. Media

Binary içerik PostgreSQL'e yazılmaz.

MinIO:

image/video binary

PostgreSQL:

media owner

object key

media type

content type

dimensions

post ilişkisi

Upload sonucu canonical media id üretir.

Mobile media id tahmin etmez.

Başka kullanıcıya ait media id post/quote içine bağlanamaz.

En az tek görselli post akışı:

media upload

canonical media id alınması

post create mediaIds

response media[]

şeklindedir.

14. Feed ve pagination

Feed kronolojiktir.

Algoritmik “For You” feed yoktur.

Pagination server-driven'dır:

cursor

limit

nextCursor

Mobile alternatif offset/cursor kontratı uydurmaz.

Block ilişkileri feed/profile görünürlüğünde backend tarafından uygulanır.

15. Ekran envanteri

Anonim ekranlar:

Login

Register

Token gerektiren ekranlar:

Feed

Post Detail

Create Post / Composer

Profile

Followers / Following

Notifications

Kaydedilenler

Hashtag Posts

Blocked Users

Report

Account/Profile yönetimi

Moderator rolü gerektiren ekranlar:

Moderation Queue

Moderation Report Detail

16. Ekran state matrisi

Ekran / yüzeyLoadingEmpty / Not FoundErrorSuccess
Feedzorunluemptyzorunluzorunlu
Post Detailzorunlu404 not-foundzorunluzorunlu
Notificationszorunluemptyzorunluzorunlu
Kaydedilenlerzorunluemptyzorunluzorunlu
Hashtag Postszorunluemptyzorunluzorunlu
Profile postszorunluemptyzorunluzorunlu
Composer / Mediauploading/submittingmedia olmaması normalupload/submit errorready/submitted

HTTP-state eşlemesi:

collection 200 + items: [] → empty

tekil resource 404 → not-found

401 → Login

5xx → error; empty değildir

17. Kullanıcı akışı

Mermaid

Token yoksa veya session geçersizse korumalı ekran Login'e düşer.

Moderator ekranı ayrıca Moderator rolü gerektirir.

18. Presentation tekrar kullanımı

Feed, Profile, Kaydedilenler ve Hashtag Posts aynı canonical post-card modelini kullanır.

Varyantlar:

Post → normal content

Repost → originalPost görünür

Quote → quote content + originalPost önizlemesi

media post → media içeriği görünür

Notification satırı canonical:

Like

Reply

Follow

Mention

tiplerinden birini kullanır.

19. Design Agent feature/state gereksinimleri

Architect yalnız feature/state/navigation gereksinimini tanımlar; pixel-level görsel tasarım Design Agent sorumluluğundadır.

Design Agent aşağıdaki davranışları destekleyecek tasarım üretmelidir:

Feed, Profile posts, Kaydedilenler ve Hashtag Posts ortak Social Post Card kullanır

Social Post Card Post, Repost, Quote varyantlarını destekler

Repost original içeriği ayırt edilebilir biçimde gösterir

Quote, quote content ile original post önizlemesini birlikte gösterir

media boş değilse en az tek görselli media post varyantı desteklenir

Bookmark action server isBookmarked state'ini yansıtır

Notifications Like, Reply, Follow, Mention varyantlarını destekler

Notification read/unread görünümü server isRead değerini yansıtır

Mention seçimi Profile ekranına gider

Hashtag seçimi Hashtag Posts ekranına gider

post ilişkili notification Post Detail'a gider

Follow notification Profile'a gider

Composer media state'leri idle, uploading, upload-error, ready, submitting, submit-error olarak temsil edilir

Feed/Notifications/Kaydedilenler/Hashtag ekranlarında loading/empty/error/success ayrımı görünürdür

Post Detail'da loading/not-found/error/success ayrımı görünürdür

Architect bu dokümanda renk, typography, spacing, ikonografi veya pixel ölçüsü belirlemez.

20. API governance

Tüm uygulama kaynakları /api/v1 altındadır.

GET /health versioned CRUD alanından ayrıdır.

JSON kuralları:

camelCase

integer kimlik

UTC ISO 8601 tarih/zaman

Kesin route, request/response alan adı, enum, status ve golden JSON yalnız docs/api-contract.md ile belirlenir.

Backend integration testlerindeki PostAsJsonAsync ve PutAsJsonAsync gövdeleri canonical golden sample'larla aynı alan adlarını kullanmalıdır.

Backend/Mobile:

alternatif route ekleyemez

alternatif JSON alan adı uyduramaz

post metninde canonical content yerine text, title, description veya body kullanamaz

enum casing değiştiremez

canonical doc'u uygulama görevi içinde patch edemez

21. Acceptance kanıt özeti

Canonical mimari aşağıdaki acceptance davranışlarını açıkça tanımlar:

text-only post content alanı ve maksimum 280 karakter ile backward-compatible kalır

feed ve Post Detail aynı PostResponse shape'ini kullanır

repost originalPost ile temsil edilir

quote current content + originalPost ile temsil edilir

media media[] ile temsil edilir

notification tipleri yalnız Like, Reply, Follow, Mention

yalnız geçerli @username Mention notification üretebilir

hashtag yalnız ilgili gönderileri listeler; trend/ranking içermez

PostgreSQL ilişkisel veriyi taşır

MinIO media binary'yi taşır

Design Agent feature/state/navigation gereksinimleri açıkça tanımlıdır

visual implementation Architect kapsamı dışında bırakılmıştır