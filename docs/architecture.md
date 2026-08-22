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

Canonical API kaynağı `docs/api-contract.md`, canonical veri modeli `docs/database-model.md` dosyasıdır. Backend ve Mobile ajanları bu dokümanları uygulama görevi kapsamında değiştirmez; kontrat değişikliği ayrı Architect görevidir.

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
- Redis: bu faz için zorunlu değil

`docker-compose.yml` Infra Agent sorumluluğundadır. Architect yalnız altyapı gereksinimini tanımlar.

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

Development başlatması production secret yokluğu nedeniyle çökmemelidir.

Production

Production Jwt:Key repository içinde tutulmaz. Environment variable veya secret store zorunludur.

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

Backend:

JWT doğrular

ownership kontrol eder

canonical camelCase JSON üretir/tüketir

sosyal ilişki uniqueness kurallarını uygular

block filtrelerini uygular

mention ve hashtag çözümlemesini yapar

notification üretir

medya ownership kontrolü yapar

MinIO/PostgreSQL koordinasyonunu yönetir

Flutter:

canonical JSON alanlarını birebir parse eder

alternatif wire alan adı üretmez

token'ı Bearer header ile gönderir

loading/empty/not-found/error/success state'lerini gösterir

canonical cursor bilgisini kullanır

@username → Profile

#tag → Hashtag Posts

post notification → Post Detail

follow notification → Profile

UI etiketi wire-format alanından farklı olabilir; bu yalnız presentation mapping'dir.

7. Post modeli ve geriye uyumluluk

Canonical post türleri:

Post

Repost

Quote

Normal text-only gönderi davranışı korunur.

text maksimum 280 karakterdir.

medya zorunlu değildir

mention zorunlu değildir

hashtag zorunlu değildir

repost/quote kullanımı normal post oluşturmayı değiştirmez

Feed ve Post Detail aynı canonical PostResponse modelini kullanır.

8. Repost ve Quote

Repost

Repost mevcut gönderiyi yeniden paylaşır.

Invariant:

kind = Repost

originalPost hedef gönderiyi gösterir

aynı kullanıcı + aynı original post için tek aktif repost bulunabilir

retry/double-tap duplicate repost üretmez

Quote

Quote yeni bir posttur.

Invariant:

kind = Quote

quote sahibinin text alanı vardır

originalPost hedef gönderiyi gösterir

quote kendi like/reply/bookmark durumuna sahiptir

9. Bookmark

Bookmark kullanıcıya özeldir.

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

Notification recipient kullanıcıya aittir ve read/unread durumu backend'de kalıcıdır.

Aynı source interaction retry edildiğinde duplicate notification üretilmemelidir.

11. Mention

Canonical gösterim:

@username

Kurallar:

backend username'i çözümler

geçerli kullanıcı mention ilişkisi oluşturur

recipient author'dan farklıysa Mention notification üretilebilir

aynı postta aynı kullanıcı tekrar mention edilirse tek ilişki ve tek notification oluşur

bulunmayan username notification üretmez

12. Hashtag

Canonical gösterim:

#tag

Backend normalize edilmiş hashtag ilişkisini oluşturur.

Hashtag ekranı seçili tag ile ilişkili gönderileri listeler.

Bu fazda:

trend endpoint'i yoktur

trend skoru yoktur

popularity-based hashtag sıralaması yoktur

13. Media

Binary içerik PostgreSQL'e yazılmaz.

MinIO:

image/video binary

PostgreSQL:

owner

object key

media type

content type

dimensions

post ilişkisi

Upload sonucu canonical media id üretir. Mobile id tahmin etmez.

Başka kullanıcıya ait media id bir post/quote içine bağlanamaz.

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

Anonim:

Login

Register

Token gerektiren:

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

Moderator:

Moderation Queue

Moderation Report Detail

16. Ekran state matrisi

EkranLoadingEmpty / Not FoundErrorSuccess
Feedzorunluemptyzorunluzorunlu
Post Detailzorunlu404 not-foundzorunluzorunlu
Notificationszorunluemptyzorunluzorunlu
Kaydedilenlerzorunluemptyzorunluzorunlu
Hashtag Postszorunluemptyzorunluzorunlu
Profile postszorunluemptyzorunluzorunlu
Composer/mediauploading/submittingmedya yokluğu normalupload/submit errorready/submitted

HTTP-state eşlemesi:

collection 200 + items: [] → empty

tekil resource 404 → not-found

401 → Login

5xx → error; empty değildir

17. Kullanıcı akışı

Mermaid

Token yoksa korumalı ekran Login'e düşer. Moderator ekranı ayrıca Moderator rolü gerektirir.

18. Presentation tekrar kullanımı

Feed, Profile, Kaydedilenler ve Hashtag Posts aynı canonical post-card modelini kullanır.

Post → normal içerik

Repost → original post gösterimi

Quote → quote text + original post önizlemesi

Notification satırı canonical Like, Reply, Follow, Mention değerlerinden birini kullanır.

19. API governance

Tüm uygulama kaynakları /api/v1 altındadır.

GET /health versioned CRUD alanından ayrıdır.

JSON:

camelCase

integer kimlik

UTC ISO 8601 tarih/zaman

Kesin route, alan adı, enum, status ve golden JSON yalnız docs/api-contract.md ile belirlenir.

Backend integration testlerindeki PostAsJsonAsync ve PutAsJsonAsync gövdeleri canonical golden sample'larla aynı alan adlarını kullanmalıdır.

Backend/Mobile:

alternatif route ekleyemez

alternatif JSON alan adı uyduramaz

enum casing değiştiremez

canonical doc'u uygulama görevi içinde patch edemez