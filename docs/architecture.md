# Pulse Teknik Mimarisi

## 1. Amaç

Pulse; kullanıcıların açık kayıt ile hesap oluşturabildiği, kronolojik bir akışta kısa metin gönderileri paylaşabildiği ve diğer kullanıcılarla etkileşime geçebildiği sosyal paylaşım uygulamasıdır.

Bu doküman güncel Pulse MVP mimarisinin tek referansıdır. Backend, mobil uygulama ve testler bu doküman ile `docs/api-contract.md` içindeki kararları kullanmalıdır.

## 2. Güncel MVP kapsamı

MVP aşağıdaki yetenekleri kapsar:

- Kayıt olma
- Giriş yapma
- JWT tabanlı oturum yönetimi
- Oturum sahibinin profilini görüntüleme
- Profil bilgilerini güncelleme
- Başka kullanıcı profilini görüntüleme
- Kullanıcı takip etme
- Kullanıcıyı takipten çıkarma
- Kronolojik ana akış
- En fazla 280 karakterlik gönderi oluşturma
- Gönderi silme
- Gönderi beğenme
- Beğeniyi kaldırma
- Bir gönderiye tek seviyeli yanıt yazma
- Loading, empty, unauthorized ve error durumları

Aşağıdaki özellikler güncel MVP endpoint matrisine dahil değildir:

- Arama
- Bildirimler
- Yer imleri
- Yeniden paylaşım
- Kullanıcı engelleme
- Şikâyet yönetimi
- Medya yükleme
- Çok seviyeli yanıt ağacı

Bu özellikler ayrı bir mimari ve API kontratı oluşturulmadan backend veya mobil uygulamada zorunlu kabul edilmez.

## 3. Teknoloji yığını

### 3.1 Backend

- .NET 8
- ASP.NET Core Web API
- Entity Framework Core
- PostgreSQL
- ASP.NET Core JWT Bearer Authentication
- FluentValidation veya eşdeğer application validation
- BCrypt tabanlı şifre hashleme
- xUnit
- Microsoft.AspNetCore.Mvc.Testing

### 3.2 Mobil istemci

- Flutter 3.8 veya üzeri
- Dart
- Dio
- Riverpod
- GoRouter
- flutter_secure_storage
- json_serializable veya eşdeğer JSON modelleme

## 4. Yerel çalışma adresleri

- Flutter web istemcisi: `http://127.0.0.1:8080`
- Backend API: `http://127.0.0.1:5000`

Mobil API base URL değeri yalnızca backend host adresini temsil eder. Repository katmanları canonical `/api/v1/...` yollarını açık şekilde kullanır.

Örnek:

```text
API_BASE_URL=http://127.0.0.1:5000
```

5. CORS

Backend aşağıdaki origin için CORS desteği sağlamalıdır:

```
http://127.0.0.1:8080
```

İzin verilen başlıklar en az:

Authorization

Content-Type

İzin verilen metotlar en az:

GET

POST

PUT

DELETE

OPTIONS

Tarayıcı preflight OPTIONS istekleri başarılı şekilde cevaplanmalıdır.

6. Sistem bileşenleri

```
Flutter Mobile / Flutter Web
            |
            | JSON + Bearer JWT
            v
ASP.NET Core Web API
            |
            +-- Health
            +-- Auth
            +-- Profile
            +-- Feed
            +-- Posts
            +-- Replies
            +-- Likes
            +-- Follows
            |
            v
       PostgreSQL
```

Sistem ilk sürümde modüler monolit olarak geliştirilir.

7. Backend katmanları

Önerilen yapı:

```
backend/
  src/
    Pulse.Api/
      Endpoints/
      Authentication/
      Middleware/
      Configuration/
      Program.cs
      appsettings.json
      appsettings.Development.json

    Pulse.Application/
      Auth/
      Profiles/
      Feed/
      Posts/
      Follows/
      Common/

    Pulse.Domain/
      Entities/
      Exceptions/

    Pulse.Infrastructure/
      Persistence/
      Authentication/
      Repositories/

  tests/
    Pulse.UnitTests/
    Pulse.IntegrationTests/
```

Bağımlılık yönü:

```
Pulse.Api -> Pulse.Application -> Pulse.Domain
Pulse.Api -> Pulse.Infrastructure
Pulse.Infrastructure -> Pulse.Application
Pulse.Infrastructure -> Pulse.Domain
```

Domain katmanı ASP.NET Core, Entity Framework Core veya HTTP ayrıntılarına bağımlı olmamalıdır.

8. Mobil katmanlar

Önerilen yapı:

```
mobile/
  lib/
    app/
      router/
      bootstrap/
      theme/

    core/
      api/
      auth/
      storage/
      errors/
      widgets/

    features/
      auth/
        data/
        domain/
        presentation/

      feed/
        data/
        domain/
        presentation/

      posts/
        data/
        domain/
        presentation/

      profile/
        data/
        domain/
        presentation/
```

Mobil istemci backend JSON alanlarını yeniden adlandırmaz.

Güncel Pulse gönderi alanı:

```
content
```

Mobil modelde description, title, text veya body alanı oluşturulmaz.

9. Orchestrator sağlık kontrolü

Workspace başlatma işlemi aşağıdaki endpoint'e bağlıdır:

```
GET /health
```

Başarı:

```
{
  "status": "ok"
}
```

Kurallar:

HTTP durum kodu 200 olmalıdır.

Endpoint /api/v1 altında değildir.

Endpoint anonimdir.

Bearer token istemez.

CRUD endpoint'lerinden bağımsızdır.

10. JWT yapılandırması

Orchestrator backend'i şu ortamda başlatır:

```
dotnet run --no-launch-profile
ASPNETCORE_ENVIRONMENT=Development
```

appsettings.Development.json aşağıdaki ayarları içermelidir:

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

Development anahtarı en az 32 byte olmalıdır.

Development ortamı production secret eksikliği nedeniyle çökmemelidir.

Production ortamında Jwt:Key environment variable veya secret store üzerinden sağlanmalıdır.

Production secret repoda tutulmamalıdır.

Anonim endpoint'ler:

GET /health

POST /api/v1/auth/register

POST /api/v1/auth/login

Diğer tüm güncel Pulse endpoint'leri Bearer token gerektirir.

11. Canonical endpoint sınırı

Uygulamanın canonical endpoint grupları:

```
/health
/api/v1/auth/*
/api/v1/me
/api/v1/profiles/*
/api/v1/feed
/api/v1/posts/*
```

Aşağıdaki legacy yollar map edilmemelidir:

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

Aynı davranış için birden fazla route tanımlanması yasaktır.

12. Kimlik kararı

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

13. Gönderi modeli

Bir gönderi aşağıdaki temel alanlardan oluşur:

id

author

content

parentPostId

createdAt

likeCount

replyCount

isLikedByCurrentUser

Kurallar:

content zorunludur.

Trim sonrası boş olamaz.

En fazla 280 karakterdir.

Ana gönderide parentPostId null olur.

Yanıtta parentPostId üst gönderinin kimliğidir.

Bir yanıta tekrar yanıt oluşturulamaz.

14. Feed mimarisi

Mobil feed repository'sinin tek kaynağı:

```
GET /api/v1/feed
Authorization: Bearer <token>
```

Başarılı response doğrudan JSON dizisidir:

```
[]
```

Durum ayrımı:

Loading: istek devam ediyor.

Success: 200 ve en az bir gönderi.

Empty: yalnızca 200 ve boş JSON dizisi.

Unauthorized: 401.

Error: 403, 404, 500, bağlantı veya parse hatası.

Mobil feed repository aşağıdaki fallback yollarını denemez:

/api/v1/posts

/feed

/posts

404 yanıtının boş listeye dönüştürülmesi yasaktır. Bu davranış backend ile mobil arasındaki route hatasını gizler.

15. Auth akışı

```
Mermaid
```

Register ve login yanıtı token ile kullanıcı özetini birlikte döndürür.

Mobil:

accessToken değerini güvenli storage'a yazar.

tokenType değerinin Bearer olduğunu kabul eder.

Token süresini expiresIn saniye alanından hesaplar.

401 durumunda token'ı temizler.

16. Ekran envanteri

16.1 Anonim ekranlar

Auth Gate

Giriş

Kayıt

16.2 Token gerektiren ekranlar

Ana Feed

Gönderi Oluşturma

Yanıt Oluşturma

Kendi Profili

Başka Kullanıcı Profili

Profil Düzenleme

17. Ekran geçişleri

```
Mermaid
```

Kurallar:

Token yoksa korumalı ekran giriş ekranına yönlendirilir.

Geçerli token varken giriş ve kayıt ekranı açılmaz.

401 yanıtında oturum kapatılır.

403 oturumu kapatmaz.

Liste empty state'i hata ekranı değildir.

18. Backend sorumlulukları

Canonical endpoint mapping

JWT doğrulama

Kaynak sahipliği kontrolü

Şifre hashleme

Request validation

280 karakter doğrulaması

Tek seviyeli yanıt kuralı

Follow ve like ilişki yönetimi

Sayaç üretimi

Tutarlı hata response'u

Feed için 200 ve JSON dizi response'u

Kullanıcı izolasyonu

19. Mobil sorumlulukları

Canonical endpoint'leri kullanma

DTO alanlarını birebir parse etme

Integer kimlik kullanma

Token'ı güvenli saklama

Loading, empty, unauthorized ve error durumlarını ayırma

401 durumunda auth gate'e dönme

Feed fallback uygulamama

Optimistic like/follow işlemi uygulanıyorsa hata halinde state'i geri alma

20. Backend dosya bazlı hizalama

Backend Agent aşağıdaki alanları kontrol etmelidir:

Dosya veya alanGereken davranış
Program.csDuplicate ve unprefixed route kaydı bulunmamalı
Endpoints/MvpEndpoints.csLegacy /me, /feed, /posts, /profiles route'ları kaldırılmalı
Endpoints/AuthEndpoints.csYalnızca register ve login anonim olmalı
Endpoints/ProfileEndpoints.cs/api/v1/me ve /api/v1/profiles/{username} kullanılmalı
Endpoints/FeedEndpoints.cs/api/v1/feed, Bearer auth, 200 JSON dizi
Endpoints/PostEndpointRoutes.csCreate, delete, reply ve like yolları canonical olmalı
Contracts/ApiContracts.csInteger kimlik, content, login, expiresIn alanları kullanılmalı

21. Mobil dosya bazlı hizalama

Mobile Agent aşağıdaki alanları kontrol etmelidir:

AlanGereken davranış
Auth repositoryLogin request alanı login olmalı
Auth response modeliToken süresi expiresIn alanından okunmalı
Profile repository/api/v1/me ve /api/v1/profiles/{username} kullanılmalı
Feed repositoryYalnızca /api/v1/feed çağırmalı
Feed hata eşleme404 error state olmalı
Post modelicontent, parentPostId, integer id kullanılmalı
Like repository200 + LikeResponse parse edilmeli
Follow repository200 + FollowResponse parse edilmeli

22. Mimari doğrulama kriterleri

/health anonim olarak 200 ve {"status":"ok"} döndürür.

Flutter web origin'i için CORS ve OPTIONS çalışır.

Development JWT ayarları production secret gerektirmeden yüklenir.

Register ve login anonimdir.

Diğer endpoint'ler Bearer token ister.

Yalnızca canonical /api/v1 route'ları çalışır.

Kimlikler backend, mobil ve JSON içinde integer'dır.

Gönderi alanı content değeridir.

Gönderi 280 karakteri aşamaz.

İkinci seviye yanıt oluşturulamaz.

Feed empty state yalnızca 200 ve [] ile oluşur.

Feed repository fallback route kullanmaz.
