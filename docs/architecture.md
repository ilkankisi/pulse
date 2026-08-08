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
- Kullanıcı engelleme
- Kullanıcı engelini kaldırma
- Engellenen kullanıcıları listeleme
- Gönderi şikâyeti oluşturma
- Kullanıcı şikâyeti oluşturma
- Moderatör şikâyet kuyruğu
- Moderatör şikâyet detayı
- Moderasyon kararı verme
- Loading, empty, unauthorized ve error durumları

Aşağıdaki özellikler güncel MVP endpoint matrisine dahil değildir:

- Arama
- Bildirimler
- Yer imleri
- Yeniden paylaşım
- Medya yükleme
- Çok seviyeli yanıt ağacı
- Otomatik yapay zekâ moderasyonu
- Otomatik medya tarama
- IP tabanlı engelleme

Bu özellikler ayrı bir mimari ve API kontratı oluşturulmadan backend veya mobil uygulamada zorunlu kabul edilmez.

### 2.1 Güvenlik ve moderasyon kapsamı

Güvenlik ve Moderasyon fazının amacı kullanıcıların istenmeyen hesaplarla etkileşimini sonlandırabilmesi ve topluluk kurallarını ihlal ettiği düşünülen kullanıcı veya gönderileri moderasyon kuyruğuna iletebilmesidir.

Bu fazda:

- Engelleme işlemi kullanıcılar arasında yönlü bir ilişki oluşturur.
- Şikâyet oluşturulması hedef kaynağı otomatik kaldırmaz.
- Moderasyon kararı yalnızca `Moderator` rolüne sahip kullanıcı tarafından verilebilir.
- Moderasyon işlemleri server-side yetkilendirilir.
- Moderasyon sonucu kaldırılan gönderiler fiziksel olarak silinmez; audit gereksinimi nedeniyle soft-delete uygulanır.
- Moderasyon kararları denetlenebilir bir kayıt olarak saklanır.

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

Flutter web istemcisinden http://127.0.0.1:5000 API adresine yapılan Bearer token içeren isteklerin CORS nedeniyle engellenmemesi zorunludur.

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
            +-- Blocks
            +-- Reports
            +-- Moderation
            |
            v
       PostgreSQL
```

Sistem ilk sürümde modüler monolit olarak geliştirilir.

Güvenlik ve Moderasyon fazı için ayrı mikroservis zorunlu değildir.

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
      Blocks/
      Reports/
      Moderation/
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

7.1 Güvenlik ve moderasyon backend sorumlulukları

Backend:

Kullanıcı kimliğini JWT üzerinden belirler.

Block ilişkisini kalıcı olarak saklar.

Block görünürlük ve etkileşim kurallarını server-side uygular.

Kullanıcı kendisini engellemeye çalıştığında isteği reddeder.

Yeni block oluşturulduğunda iki kullanıcı arasındaki mevcut follow ilişkilerini kaldırır.

Şikâyet request doğrulamasını yapar.

Aynı reporter ve aynı target için ikinci Pending şikâyeti engeller.

Moderasyon endpoint'lerinde Moderator rolünü doğrular.

Moderasyon kararını ve audit kaydını aynı transaction sınırında işler.

Moderasyonla kaldırılan postları feed ve etkileşim sorgularından filtreler.

Mobil istemcinin UI tabanlı güvenlik kararlarına güvenmez.

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

      moderation/
        data/
        domain/
        presentation/
```

Mobil istemci backend kontratındaki camelCase alanları birebir kullanır.

Mobil katman:

endpoint isimleri uydurmaz,

canonical endpoint yerine legacy fallback kullanmaz,

backend alanlarını yeniden adlandırmaz,

token yoksa korumalı kaynağa anonim istek göndermez,

server-side authorization yerine yalnızca UI gizlemeye güvenmez.

8.1 Güvenlik ve moderasyon mobil sorumlulukları

Mobil:

Profil üzerinden kullanıcıyı engelleme aksiyonunu sunabilir.

Engelli kullanıcı için engeli kaldırma aksiyonunu sunabilir.

Engellenen kullanıcıları listeleyebilir.

Profil üzerinden kullanıcı şikâyeti formunu açabilir.

Gönderi üzerinden gönderi şikâyeti formunu açabilir.

Başarılı şikâyet oluşturulmasını hedef içeriğin kaldırıldığı şeklinde yorumlamaz.

401 durumunda mevcut oturum yenileme/login davranışını kullanır.

403 durumunu yetki hatası olarak işler.

404 durumunda gizlenen veya bulunamayan kaynağın nedenini istemci tarafında tahmin etmez.

Moderasyon ekranlarının görünürlüğünü rol bilgisi mevcutsa sınırlandırabilir; nihai karar yine backend'indir.

9. Health endpoint

Orchestrator backend'i aşağıdaki endpoint ile kontrol eder:

```
GET /health
```

Başarı:

```
200 OK
```

Gövde:

```
{
  "status": "ok"
}
```

Kurallar:

/health /api/v1 altında değildir.

Kimlik doğrulama gerektirmez.

JWT doğrulamasına bağımlı değildir.

Kullanıcı CRUD endpoint'lerinden ayrı bir orchestrator sağlık kontrolüdür.

Workspace başlangıcı bu endpoint'in başarılı olmasına bağlıdır.

10. JWT ve yerel orchestrator başlangıcı

Orchestrator backend'i aşağıdaki çalışma biçimiyle başlatır:

```
dotnet run --no-launch-profile
ASPNETCORE_ENVIRONMENT=Development
```

Development ortamında appsettings.Development.json içinde aşağıdaki ayarlar bulunmalıdır:

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

Development ortamı production secret bulunmadığı için çökmemelidir.

Development değeri yalnızca yerel geliştirme içindir.

Production ortamında Jwt:Key environment variable veya secret store üzerinden verilmelidir.

Production secret repoya commit edilmez.

GET /health anonimdir.

POST /api/v1/auth/register anonimdir.

POST /api/v1/auth/login anonimdir.

Diğer kullanıcı kaynakları Bearer token gerektirir.

/api/v1/moderation/** kaynakları ayrıca Moderator rolü gerektirir.

Korumalı istek:

```
Authorization: Bearer <token>
```

10.1 Roller

Canonical roller:

```
User
Moderator
```

User standart uygulama kullanıcısıdır.

Moderator, standart kullanıcı haklarına ek olarak moderasyon kuyruğunu okuyabilir ve şikâyet sonuçlandırabilir.

Geçerli Bearer token olup gerekli rol bulunmadığında backend 403 Forbidden döndürür.

11. Kimlik modeli

Pulse kaynak kimlikleri integer'dır.

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

UUID string kaynak kimliği olarak kullanılmaz.

12. Gönderi modeli

Bir gönderinin temel alanları:

id

author

content

parentPostId

createdAt

likeCount

replyCount

Gönderinin kullanıcı tarafından girilen metin alanı yalnızca content adını kullanır.

Maksimum uzunluk:

```
280 karakter
```

Alternatif alan isimleri kullanılmaz:

title

description

text

body

Tek seviyeli reply modeli kullanılır.

Yeni reply yalnızca kök gönderiye bağlıdır. Çok seviyeli reply ağacı bu kapsamda yoktur.

13. Profil modeli

Profil oturum sahibi veya başka bir kullanıcı için görüntülenebilir.

Canonical kaynak yolları:

```
GET /api/v1/me
PUT /api/v1/me
GET /api/v1/profiles/{username}
```

Legacy /api/v1/users/... yolları kullanılmaz.

Profil alanlarının HTTP sözleşmesi docs/api-contract.md içinde tanımlanır.

14. Feed

Feed kronolojiktir.

Temel sıra:

```
createdAt DESC
```

Feed yalnızca kullanıcının görmeye yetkili olduğu gönderileri döndürür.

Aşağıdaki gönderiler feed'den filtrelenir:

soft-delete edilmiş gönderiler,

oturum sahibi ile arasında block ilişkisi bulunan kullanıcıların gönderileri.

Block filtresi iki yönlü görünürlük uygular. A kullanıcısının B'yi engellemiş olması halinde A ve B birbirlerinin gönderilerini feed içinde görmez.

15. Takip

Follow ilişkisi kullanıcılar arasında yönlüdür.

Canonical endpoint'ler:

```
POST /api/v1/profiles/{username}/follow
DELETE /api/v1/profiles/{username}/follow
```

Block ilişkisi bulunan iki kullanıcı arasında yeni follow oluşturulamaz.

Yeni block oluşturulduğunda iki yönlü mevcut follow kayıtları kaldırılır.

Engelin kaldırılması silinen follow kayıtlarını otomatik geri getirmez.

16. Beğeni

Bir kullanıcı aynı gönderiyi en fazla bir kez beğenebilir.

Canonical endpoint'ler:

```
POST /api/v1/posts/{postId}/likes
DELETE /api/v1/posts/{postId}/likes
```

Aşağıdaki gönderilere yeni beğeni oluşturulamaz:

soft-delete edilmiş gönderi,

block nedeniyle kullanıcıya görünmeyen gönderi.

17. Yanıtlar

Canonical endpoint:

```
POST /api/v1/posts/{postId}/replies
```

Yanıt alanı:

```
content
```

Maksimum:

```
280 karakter
```

Aşağıdaki gönderilere reply oluşturulamaz:

soft-delete edilmiş gönderi,

block nedeniyle kullanıcıya görünmeyen gönderi.

18. Kullanıcı engelleme

Engelleme yönlü bir ilişkidir.

Örnek:

```
A -> B
```

A, B'yi engellediğinde:

A ve B birbirlerinin gönderilerini feed içinde görmez.

A ve B birbirini takip edemez.

Mevcut A -> B ve B -> A follow ilişkileri kaldırılır.

A ve B birbirlerinin gönderilerine yeni like veremez.

A ve B birbirlerinin gönderilerine yeni reply oluşturamaz.

Doğrudan görünmez profile erişim 404 Not Found olarak değerlendirilir.

Görünürlük sebebi response içinde açıklanmaz. Böylece başka kullanıcıya block ilişkisinin ayrıntıları gereksiz şekilde sızdırılmaz.

Kullanıcı kendisini engelleyemez.

Aynı kullanıcıyı tekrar engelleme idempotenttir ve ikinci block kaydı oluşturmaz.

Engeli kaldırma da idempotenttir.

18.1 Block veri modeli

```
user_blocks
  blocker_user_id
  blocked_user_id
  created_at
```

Anahtar:

```
PRIMARY KEY (blocker_user_id, blocked_user_id)
```

Foreign key'ler:

```
blocker_user_id -> users.id
blocked_user_id -> users.id
```

blocker_user_id ve blocked_user_id eşit olamaz.

19. Şikâyet sistemi

Bir şikâyet tam olarak bir hedefe yönelir.

Hedef tipleri:

```
Post
User
```

Canonical ReportReason değerleri:

```
Spam
Harassment
HateSpeech
Violence
SexualContent
Impersonation
Other
```

Canonical ReportStatus değerleri:

```
Pending
Resolved
Dismissed
```

Kurallar:

Kullanıcı kendi hesabını şikâyet edemez.

Kullanıcı kendi gönderisini şikâyet edemez.

Aynı reporter ve aynı hedef için açık Pending şikâyet varken ikinci kayıt oluşturulamaz.

Duplicate pending istek 409 Conflict döndürür.

details opsiyoneldir.

details en fazla 500 karakterdir.

Şikâyet oluşturulması hedef kaynağı otomatik kaldırmaz.

19.1 Report veri modeli

```
reports
  id
  reporter_user_id
  target_type
  target_post_id
  target_user_id
  reason
  details
  status
  created_at
  resolved_at
  resolved_by_user_id
```

Kurallar:

target_type=Post:

```
target_post_id NOT NULL
target_user_id NULL
```

target_type=User:

```
target_user_id NOT NULL
target_post_id NULL
```

Veritabanı constraint'i aynı report için iki hedefin birden dolu olmasını engeller.

20. Moderasyon

Moderasyon endpoint'leri yalnızca Moderator rolüne açıktır.

Canonical moderasyon aksiyonları:

```
NoAction
RemovePost
```

20.1 NoAction

NoAction:

raporu Resolved yapar,

hedef gönderi veya kullanıcı üzerinde değişiklik yapmaz,

audit kaydı oluşturur.

20.2 RemovePost

RemovePost yalnızca Post hedefli rapor için kullanılabilir.

Yanlış target tipi için:

```
400 Bad Request
```

RemovePost fiziksel DELETE uygulamaz.

Gönderi soft-delete edilir.

Önerilen alan:

```
posts.deleted_at timestamptz NULL
```

Soft-delete sonrası gönderi:

feed'e girmez,

doğrudan görünür kaynak olarak değerlendirilmez,

yeni like kabul etmez,

yeni reply kabul etmez.

20.3 Dismiss

Dismiss işlemi:

raporu Dismissed yapar,

hedef kaynağı değiştirmez,

audit kaydı oluşturur.

20.4 Moderasyon concurrency

Yalnızca Pending durumundaki rapor sonuçlandırılabilir.

Daha önce Resolved veya Dismissed olan rapor için yeni resolve/dismiss isteği:

```
409 Conflict
```

20.5 Moderasyon audit modeli

```
moderation_actions
  id
  report_id
  moderator_user_id
  action
  note
  created_at
```

note nullable ve en fazla 500 karakterdir.

Moderasyon kararı, report durum değişikliği ve gerekli post soft-delete işlemi aynı transaction sınırında gerçekleştirilmelidir.

21. Veritabanı

Ana kalıcı veri deposu PostgreSQL'dir.

Güvenlik ve Moderasyon için gereken ek tablolar:

```
user_blocks
reports
moderation_actions
```

Mevcut kullanıcı, gönderi, takip, beğeni ve reply tabloları korunur.

Önerilen ilişkiler:

```
users 1 --- * user_blocks (blocker)
users 1 --- * user_blocks (blocked)

users 1 --- * reports (reporter)
users 1 --- * reports (target user)
posts 1 --- * reports (target post)

reports 1 --- * moderation_actions
users 1 --- * moderation_actions (moderator)
```

Index gereksinimleri:

```
user_blocks(blocker_user_id, blocked_user_id) UNIQUE
reports(status, created_at)
reports(reporter_user_id, target_type, target_post_id)
reports(reporter_user_id, target_type, target_user_id)
moderation_actions(report_id)
```

Duplicate Pending report kontrolü application katmanında yapılmalı ve mümkün olan yerde veritabanı bütünlük mekanizmalarıyla desteklenmelidir.

22. Redis ve MinIO

Bu Güvenlik ve Moderasyon fazı için:

Redis zorunlu değildir.

MinIO zorunlu değildir.

PostgreSQL kalıcı block/report/moderation verileri için yeterlidir.

İleride rate limiting, distributed cache veya medya moderasyonu eklenirse Redis/MinIO ihtiyacı ayrı görevde yeniden değerlendirilir.

Architect docker-compose.yml yazmaz.

Altyapı gereksinimlerinin compose karşılığı Infra Agent sorumluluğundadır.

23. HTTP hata semantiği

Genel anlamlar:

```
400 Validation veya iş kuralı hatası
401 Token yok/geçersiz/süresi dolmuş
403 Kimliği doğrulanmış kullanıcının yetkisi yetersiz
404 Kaynak bulunamadı veya güvenlik nedeniyle görünmez
409 Mevcut durumla çakışan işlem
500 Beklenmeyen backend hatası
```

Block nedeniyle gizlenen bir kaynağın varlığını açıklamak yerine 404 kullanılabilir.

Moderation rol eksikliği 403 olarak kalır.

24. Ekran envanteri

Anonim ekranlar:

Login

Register

Token gerektiren standart ekranlar:

Feed

Profil

Gönderi oluşturma

Gönderi detayı

Kullanıcı şikâyet formu

Gönderi şikâyet formu

Engellenen kullanıcılar

Moderator rolü gerektiren ekranlar:

Moderasyon kuyruğu

Moderasyon şikâyet detayı

Moderasyon karar ekranı

25. Kullanıcı akışı

```
Mermaid
```

Geçiş kuralları:

Login -> Register

Register -> Login

Login -> Feed

Feed -> Profil

Feed -> Gönderi detayı

Feed -> Gönderi oluşturma

Profil -> Follow/Unfollow

Profil -> Block/Unblock

Profil -> Kullanıcı şikâyeti

Gönderi detayı -> Like/Unlike

Gönderi detayı -> Reply

Gönderi detayı -> Gönderi şikâyeti

Ayarlar -> Engellenen kullanıcılar

Engellenen kullanıcılar -> Profil

Feed -> Logout -> Login

Moderasyon kuyruğu -> Şikâyet detayı

Şikâyet detayı -> Moderasyon kararı

Moderasyon kararı -> Moderasyon kuyruğu

Token gerektiren route token olmadan açılmaya çalışılırsa login ekranına dönülür.

Moderator route'u standart User rolüyle açılmamalıdır. Backend erişim kontrolü yine zorunludur.

26. API kontratı tek kaynak kuralı

HTTP path, request body, response body, enum değeri veya JSON alan adı konusunda docs/api-contract.md tek kaynaktır.

Backend ve mobil:

alternatif alan adı üretemez,

endpoint alias/fallback tanımlayamaz,

farklı enum casing kullanamaz.

JSON alanları camelCase'dir.

Paylaşılan enum string değerleri API kontratındaki casing ile birebir kullanılır.

27. Test stratejisi

Backend integration testleri en az aşağıdakileri doğrulamalıdır:

/health anonim 200

register/login anonim

korumalı endpoint token gereksinimi

block create/remove

self-block reddi

block sonrası follow temizliği

block sonrası feed görünürlüğü

report create

self-report reddi

duplicate pending report 409

normal kullanıcının moderation endpoint'inden 403 alması

moderator pending queue

resolve NoAction

resolve RemovePost

dismiss

ikinci moderation kararında 409

soft-delete postun feed/like/reply akışından çıkarılması

Backend integration testlerindeki PostAsJsonAsync ve PutAsJsonAsync gövdeleri docs/api-contract.md golden JSON örnekleriyle aynı alan adlarını kullanmalıdır.

Mobil testleri en az:

block/unblock sonucu

report request alanları

unauthorized yönlendirme

forbidden moderasyon durumu

loading/empty/error durumları

üzerinde canonical kontratı doğrulamalıdır.

28. Güvenlik ilkeleri

Şifreler düz metin saklanmaz.

JWT production secret repoda tutulmaz.

Authorization yalnızca mobil UI ile uygulanmaz.

Moderasyon yetkisi backend'de role göre doğrulanır.

Block ilişkisi server-side sorgularda uygulanır.

Kullanıcı girdileri doğrulanır.

Moderasyon notu ve report details alanları güvenilmeyen kullanıcı girdisi kabul edilir.

SQL oluşturmak için kullanıcı girdisi birleştirilmez; EF Core parametreli sorgular kullanılır.

Hata response'ları gereksiz iç sistem ayrıntısı içermez.

Block nedeniyle gizlenen kaynağın varlığı kullanıcıya açık edilmez.

Moderasyon aksiyonları audit için kalıcı olarak saklanır.

29. Mimari karar özeti

Mimari: modüler monolit

Backend: .NET 8 ASP.NET Core

Mobil: Flutter

Veritabanı: PostgreSQL

Auth: JWT Bearer

Kimlik: integer

JSON: camelCase

Post metni: content

Maksimum post/reply: 280 karakter

Health: anonim GET /health

Development JWT fallback: zorunlu

Flutter web CORS origin: http://127.0.0.1:8080

API adresi: http://127.0.0.1:5000

Block ilişkisi: yönlü

Block görünürlüğü: iki taraf için etkileşim/görünürlük kısıtı

Report hedefleri: Post, User

Report durumları: Pending, Resolved, Dismissed

Moderator aksiyonları: NoAction, RemovePost

Moderasyon kaldırması: soft-delete

Redis: bu fazda zorunlu değil

MinIO: bu fazda zorunlu değil
