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
- Profil sahibinin gönderilerini görüntüleme
- Profilin takipçilerini görüntüleme
- Profilin takip ettiği kullanıcıları görüntüleme
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
- Moderasyon sonucu kaldırılan gönderiler fiziksel olarak silinmez.
- Moderasyon kararları denetlenebilir bir kayıt olarak saklanır.

### 2.2 Sosyal Graf ve Profil Tamamlama kapsamı

Sosyal Graf & Profil Tamamlama fazı mevcut `users`, `posts`, `follows` ve `user_blocks` modellerinin read tarafını tamamlar.

Bu faz:

- profil oluşturulma zamanını göstermeyi,
- görünür gönderi sayısını göstermeyi,
- takipçi sayısını göstermeyi,
- takip edilen kullanıcı sayısını göstermeyi,
- oturum sahibinin hedef profili takip edip etmediğini göstermeyi,
- profil sahibinin kök gönderilerini listelemeyi,
- profil sahibinin takipçilerini listelemeyi,
- profil sahibinin takip ettiği kullanıcıları listelemeyi

kapsar.

Bu faz yeni sosyal graf mikroservisi, graph database veya ayrı profil-post ilişki tablosu gerektirmez.

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

~~~text
API_BASE_URL=http://127.0.0.1:5000
~~~

## 5. CORS

Backend aşağıdaki origin için CORS desteği sağlamalıdır:

~~~text
http://127.0.0.1:8080
~~~

İzin verilen başlıklar en az:

- Authorization
- Content-Type

İzin verilen metotlar en az:

- GET
- POST
- PUT
- DELETE
- OPTIONS

Tarayıcı preflight `OPTIONS` istekleri başarılı şekilde cevaplanmalıdır.

Flutter web istemcisinden `http://127.0.0.1:5000` API adresine yapılan Bearer token içeren isteklerin CORS nedeniyle engellenmemesi zorunludur.

## 6. Sistem bileşenleri

~~~text
Flutter Mobile / Flutter Web
            |
            | JSON + Bearer JWT
            v
ASP.NET Core Web API
            |
            +-- Health
            +-- Auth
            +-- Profile
            +-- Social Graph
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
~~~

Sistem ilk sürümde modüler monolit olarak geliştirilir.

Güvenlik & Moderasyon veya Sosyal Graf & Profil Tamamlama fazı için ayrı mikroservis zorunlu değildir.

## 7. Backend katmanları

Önerilen yapı:

~~~text
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
      SocialGraph/
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
~~~

Bağımlılık yönü:

~~~text
Pulse.Api -> Pulse.Application -> Pulse.Domain
Pulse.Api -> Pulse.Infrastructure
Pulse.Infrastructure -> Pulse.Application
Pulse.Infrastructure -> Pulse.Domain
~~~

Domain katmanı ASP.NET Core, Entity Framework Core veya HTTP ayrıntılarına bağımlı olmamalıdır.

### 7.1 Güvenlik ve moderasyon backend sorumlulukları

Backend:

- Kullanıcı kimliğini JWT üzerinden belirler.
- Block ilişkisini kalıcı olarak saklar.
- Block görünürlük ve etkileşim kurallarını server-side uygular.
- Kullanıcı kendisini engellemeye çalıştığında isteği reddeder.
- Yeni block oluşturulduğunda iki kullanıcı arasındaki mevcut follow ilişkilerini kaldırır.
- Şikâyet request doğrulamasını yapar.
- Aynı reporter ve aynı target için ikinci açık şikâyeti engeller.
- Moderasyon endpoint'lerinde `Moderator` rolünü doğrular.
- Moderasyon kararını ve audit kaydını aynı transaction sınırında işler.
- Moderasyonla kaldırılan postları feed ve etkileşim sorgularından filtreler.
- Mobil istemcinin UI tabanlı güvenlik kararlarına güvenmez.

### 7.2 Sosyal graf ve profil backend sorumlulukları

Backend:

- Profil read modelini canonical alanlarla üretir.
- Profil sayaçlarını server-side hesaplar.
- Profil gönderilerini mevcut post read modeliyle döndürür.
- Takipçi ve takip edilen listelerini mevcut follow ilişkilerinden üretir.
- Sosyal graf sonuçlarında block görünürlüğünü uygular.
- Oturum sahibinin takip durumunu server-side hesaplar.
- Olmayan profil ile boş collection durumunu birbirinden ayırır.
- API kontratında tanımlanmayan ikinci bir profil, post veya follow DTO alan adı üretmez.

## 8. Mobil katmanlar

Önerilen yapı:

~~~text
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

      social_graph/
        data/
        domain/
        presentation/

      moderation/
        data/
        domain/
        presentation/
~~~

Mobil istemci backend kontratındaki camelCase alanları birebir kullanır.

Mobil katman:

- endpoint isimleri uydurmaz,
- canonical endpoint yerine legacy fallback kullanmaz,
- backend alanlarını yeniden adlandırmaz,
- token yoksa korumalı kaynağa anonim istek göndermez,
- server-side authorization yerine yalnızca UI gizlemeye güvenmez.

### 8.1 Güvenlik ve moderasyon mobil sorumlulukları

Mobil:

- Profil üzerinden kullanıcıyı engelleme aksiyonunu sunabilir.
- Engelli kullanıcı için engeli kaldırma aksiyonunu sunabilir.
- Engellenen kullanıcıları listeleyebilir.
- Profil üzerinden kullanıcı şikâyeti formunu açabilir.
- Gönderi üzerinden gönderi şikâyeti formunu açabilir.
- Başarılı şikâyet oluşturulmasını hedef içeriğin kaldırıldığı şeklinde yorumlamaz.
- `401` durumunda mevcut oturum yenileme/login davranışını kullanır.
- `403` durumunu yetki hatası olarak işler.
- `404` durumunda gizlenen veya bulunamayan kaynağın nedenini istemci tarafında tahmin etmez.
- Moderasyon ekranlarının görünürlüğünü rol bilgisi mevcutsa sınırlandırabilir; nihai karar yine backend'indir.

### 8.2 Sosyal graf ve profil mobil sorumlulukları

Mobil:

- Profil response alanlarını canonical isimleriyle parse eder.
- Profil gönderileri için mevcut post modelini yeniden kullanır.
- Takipçi ve takip edilen listeleri için tek canonical sosyal graf liste öğesi modeli kullanır.
- Takip durumunu backend'in döndürdüğü alan üzerinden gösterir.
- Takip durumunu local tahminle canonical response'un üzerine yazmaz.
- Boş gönderi/takipçi/takip edilen listesini hata kabul etmez.
- Profil gönderisine dokunulduğunda mevcut gönderi detay akışına gider.
- Takipçi veya takip edilen kullanıcıya dokunulduğunda mevcut profil ekranına gider.

## 9. Health endpoint

Orchestrator backend'i aşağıdaki endpoint ile kontrol eder:

~~~http
GET /health
~~~

Başarı:

~~~http
200 OK
~~~

Gövde:

~~~json
{
  "status": "ok"
}
~~~

Kurallar:

- `/health` `/api/v1` altında değildir.
- Kimlik doğrulama gerektirmez.
- JWT doğrulamasına bağımlı değildir.
- Kullanıcı CRUD endpoint'lerinden ayrı bir orchestrator sağlık kontrolüdür.
- Workspace başlangıcı bu endpoint'in başarılı olmasına bağlıdır.

## 10. JWT ve yerel orchestrator başlangıcı

Orchestrator backend'i aşağıdaki çalışma biçimiyle başlatır:

~~~text
dotnet run --no-launch-profile
ASPNETCORE_ENVIRONMENT=Development
~~~

Development ortamında `appsettings.Development.json` içinde aşağıdaki ayarlar bulunmalıdır:

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
- Development ortamı production secret bulunmadığı için çökmemelidir.
- Development değeri yalnızca yerel geliştirme içindir.
- Production ortamında `Jwt:Key` environment variable veya secret store üzerinden verilmelidir.
- Production secret repoya commit edilmez.
- `GET /health` anonimdir.
- `POST /api/v1/auth/register` anonimdir.
- `POST /api/v1/auth/login` anonimdir.
- Diğer kullanıcı kaynakları Bearer token gerektirir.
- `/api/v1/moderation/**` kaynakları ayrıca `Moderator` rolü gerektirir.

Korumalı istek:

~~~http
Authorization: Bearer <token>
~~~

### 10.1 Roller

Canonical roller:

- `User`
- `Moderator`

`User` standart uygulama kullanıcısıdır.

`Moderator`, standart kullanıcı haklarına ek olarak moderasyon kuyruğunu okuyabilir ve şikâyet sonuçlandırabilir.

Geçerli Bearer token olup gerekli rol bulunmadığında backend `403 Forbidden` döndürür.

## 11. Kimlik modeli

Pulse kaynak kimlikleri integer'dır.

Backend:

~~~text
int Id
~~~

Mobil:

~~~text
final int id;
~~~

API:

~~~json
{
  "id": 1
}
~~~

UUID string kaynak kimliği olarak kullanılmaz.

## 12. Gönderi modeli

Bir gönderinin temel alanları:

- id
- author
- content
- parentPostId
- createdAt
- likeCount
- replyCount
- isLikedByMe

Gönderinin kullanıcı tarafından girilen metin alanı yalnızca `content` adını kullanır.

Maksimum uzunluk:

~~~text
280 karakter
~~~

Alternatif alan isimleri kullanılmaz:

- title
- description
- text
- body

Tek seviyeli reply modeli kullanılır.

Yeni reply yalnızca kök gönderiye bağlıdır. Çok seviyeli reply ağacı bu kapsamda yoktur.

## 13. Profil modeli

Profil oturum sahibi veya başka bir kullanıcı için görüntülenebilir.

Canonical temel kaynak yolları:

~~~text
GET /api/v1/me
PUT /api/v1/me
GET /api/v1/profiles/{username}
~~~

Sosyal Graf & Profil Tamamlama read yolları:

~~~text
GET /api/v1/profiles/{username}/posts
GET /api/v1/profiles/{username}/followers
GET /api/v1/profiles/{username}/following
~~~

Legacy `/api/v1/users/...` yolları kullanılmaz.

Profil alanlarının HTTP sözleşmesi `docs/api-contract.md` içinde tanımlanır.

### 13.1 Profil read modeli

Profil read modeli en az:

- kullanıcı kimliği,
- username,
- display name,
- bio,
- avatar URL,
- hesap oluşturulma zamanı,
- görünür kök gönderi sayısı,
- takipçi sayısı,
- takip edilen hesap sayısı,
- oturum sahibinin profili takip edip etmediği

bilgilerini taşır.

HTTP JSON alanlarının kesin adları yalnız `docs/api-contract.md` tarafından belirlenir.

Profil sayaçları persistence'ta ayrı zorunlu sütunlar değildir; mevcut tablolar üzerinden hesaplanabilir.

### 13.2 Profil gönderileri

Profil gönderileri:

- hedef kullanıcıya ait olmalıdır,
- yalnız kök gönderileri içermelidir,
- soft-delete kayıtları içermemelidir,
- moderasyonla gizlenen kayıtları içermemelidir,
- `createdAt DESC` sıralı olmalıdır.

Profil gönderilerinde mevcut post read modeli yeniden kullanılır.

Yeni bir profil-post response modeli uydurulmaz.

Profil var ancak görünür gönderisi yoksa collection empty state döner.

### 13.3 Takipçiler

Takipçi listesi mevcut follow ilişkilerinden türetilir.

Hedef kullanıcının takipçileri, hedef kullanıcının follow ilişkisinde takip edilen taraf olduğu kayıtlardır.

Block nedeniyle oturum sahibine görünmeyen kullanıcılar sonuçtan filtrelenir.

Liste öğesinde oturum sahibinin ilgili kullanıcıyı takip edip etmediği backend tarafından hesaplanır.

### 13.4 Takip edilen kullanıcılar

Takip edilen listesi mevcut follow ilişkilerinden türetilir.

Hedef kullanıcının takip ettiği hesaplar, hedef kullanıcının follow ilişkisinde takip eden taraf olduğu kayıtlardır.

Block nedeniyle oturum sahibine görünmeyen kullanıcılar sonuçtan filtrelenir.

Followers ve following aynı liste öğesi read modelini kullanır.

## 14. Feed

Feed kronolojiktir.

Temel sıra:

~~~text
createdAt DESC
~~~

Feed yalnızca kullanıcının görmeye yetkili olduğu gönderileri döndürür.

Aşağıdaki gönderiler feed'den filtrelenir:

- soft-delete edilmiş gönderiler,
- moderasyonla gizlenmiş gönderiler,
- oturum sahibi ile arasında block ilişkisi bulunan kullanıcıların gönderileri.

Block filtresi iki yönlü görünürlük uygular. A kullanıcısının B'yi engellemiş olması halinde A ve B birbirlerinin gönderilerini feed içinde görmez.

## 15. Takip

Follow ilişkisi kullanıcılar arasında yönlüdür.

Canonical endpoint'ler:

~~~text
POST /api/v1/profiles/{username}/follow
DELETE /api/v1/profiles/{username}/follow
~~~

Block ilişkisi bulunan iki kullanıcı arasında yeni follow oluşturulamaz.

Yeni block oluşturulduğunda iki yönlü mevcut follow kayıtları kaldırılır.

Engelin kaldırılması silinen follow kayıtlarını otomatik geri getirmez.

Sosyal graf read endpoint'leri bu canonical follow ilişkisini kullanır; ikinci bir social graph ilişki kaynağı oluşturulmaz.

## 16. Beğeni

Bir kullanıcı aynı gönderiyi en fazla bir kez beğenebilir.

Canonical endpoint'ler:

~~~text
POST /api/v1/posts/{postId}/likes
DELETE /api/v1/posts/{postId}/likes
~~~

Aşağıdaki gönderilere yeni beğeni oluşturulamaz:

- soft-delete edilmiş gönderi,
- moderasyonla gizlenmiş gönderi,
- block nedeniyle kullanıcıya görünmeyen gönderi.

## 17. Yanıtlar

Canonical endpoint:

~~~text
POST /api/v1/posts/{postId}/replies
~~~

Yanıt alanı `content` olarak kalır.

Maksimum uzunluk 280 karakterdir.

Aşağıdaki gönderilere reply oluşturulamaz:

- soft-delete edilmiş gönderi,
- moderasyonla gizlenmiş gönderi,
- block nedeniyle kullanıcıya görünmeyen gönderi.

## 18. Kullanıcı engelleme

Engelleme yönlü bir ilişkidir.

Örnek:

~~~text
A -> B
~~~

A, B'yi engellediğinde:

- A ve B birbirlerinin gönderilerini feed içinde görmez.
- A ve B birbirini takip edemez.
- Mevcut A -> B ve B -> A follow ilişkileri kaldırılır.
- A ve B birbirlerinin gönderilerine yeni like veremez.
- A ve B birbirlerinin gönderilerine yeni reply oluşturamaz.
- Doğrudan görünmez profile erişim `404 Not Found` olarak değerlendirilir.
- Profile bağlı post/follower/following collection'ları da görünmez kabul edilir.

Görünürlük sebebi response içinde açıklanmaz.

Kullanıcı kendisini engelleyemez.

Aynı kullanıcıyı tekrar engelleme idempotenttir ve ikinci block kaydı oluşturmaz.

Engeli kaldırma da idempotenttir.

## 19. Şikâyet sistemi

Bir şikâyet tam olarak bir hedefe yönelir.

Canonical hedef tipleri:

- `Post`
- `User`

Canonical şikâyet nedenleri:

- `Spam`
- `Harassment`
- `HateSpeech`
- `Violence`
- `SexualContent`
- `Impersonation`
- `Other`

Canonical durumlar:

- `Pending`
- `Resolved`
- `Dismissed`

Kurallar:

- Kullanıcı kendi hesabını şikâyet edemez.
- Kullanıcı kendi gönderisini şikâyet edemez.
- Aynı reporter ve aynı hedef için açık şikâyet varken ikinci kayıt oluşturulamaz.
- Duplicate açık istek `409 Conflict` döndürür.
- `details` opsiyoneldir.
- `details` en fazla 500 karakterdir.
- Şikâyet oluşturulması hedef kaynağı otomatik kaldırmaz.

## 20. Moderasyon

Moderasyon endpoint'leri yalnızca `Moderator` rolüne açıktır.

Canonical moderasyon aksiyonları:

- `NoAction`
- `RemovePost`

### 20.1 NoAction

`NoAction`:

- raporu resolved duruma geçirir,
- hedef gönderi veya kullanıcı üzerinde değişiklik yapmaz,
- audit kaydı oluşturur.

### 20.2 RemovePost

`RemovePost` yalnızca post hedefli rapor için kullanılabilir.

Yanlış target tipi `400 Bad Request` döndürür.

`RemovePost` fiziksel DELETE uygulamaz.

Gönderi canonical persistence modeli üzerinden normal kullanıcı görünürlüğünden çıkarılır.

Gizlenmiş gönderi:

- feed'e girmez,
- profil gönderi listesine girmez,
- normal görünür kaynak olarak değerlendirilmez,
- yeni like kabul etmez,
- yeni reply kabul etmez.

### 20.3 Dismiss

Dismiss işlemi:

- raporu dismissed duruma geçirir,
- hedef kaynağı değiştirmez,
- audit kaydı oluşturur.

### 20.4 Moderasyon concurrency

Yalnızca açık durumdaki rapor sonuçlandırılabilir.

Daha önce sonuçlandırılmış rapor için yeni resolve/dismiss isteği `409 Conflict` döndürür.

## 21. Veritabanı

Ana kalıcı veri deposu PostgreSQL'dir.

Güncel model en az aşağıdaki kavramları içerir:

- users
- posts
- follows
- likes
- user blocks
- reports
- moderation actions

Sosyal Graf & Profil Tamamlama fazı yeni tablo gerektirmez.

Profil read modeli:

- `users`,
- `posts`,
- `follows`,
- `user_blocks`

üzerinden türetilir.

Profil sayaçları MVP için denormalize zorunlu sütunlar değildir.

## 22. Redis ve MinIO

Güvenlik & Moderasyon ve Sosyal Graf & Profil Tamamlama fazları için:

- Redis zorunlu değildir.
- MinIO zorunlu değildir.

PostgreSQL mevcut kalıcı veri gereksinimleri için yeterlidir.

İleride distributed cache, yüksek ölçekli sayaç cache'i veya medya moderasyonu eklenirse Redis/MinIO ihtiyacı ayrı görevde değerlendirilir.

Architect `docker-compose.yml` yazmaz.

Altyapı gereksinimlerinin compose karşılığı Infra Agent sorumluluğundadır.

## 23. HTTP hata semantiği

Genel anlamlar:

~~~text
400 Validation veya iş kuralı hatası
401 Token yok/geçersiz/süresi dolmuş
403 Kimliği doğrulanmış kullanıcının yetkisi yetersiz
404 Kaynak bulunamadı veya güvenlik nedeniyle görünmez
409 Mevcut durumla çakışan işlem
500 Beklenmeyen backend hatası
~~~

Block nedeniyle gizlenen bir kaynağın varlığını açıklamak yerine `404` kullanılabilir.

Profile bağlı sosyal graf collection'ında hedef profil yoksa veya görünmezse `404` kullanılır.

Hedef profil mevcut ancak collection boşsa `200` ve boş collection kullanılır.

Moderation rol eksikliği `403` olarak kalır.

## 24. Ekran envanteri

Anonim ekranlar:

- Login
- Register

Token gerektiren standart ekranlar:

- Feed
- Profil
- Profil gönderileri
- Takipçiler
- Takip edilenler
- Gönderi oluşturma
- Gönderi detayı
- Kullanıcı şikâyet formu
- Gönderi şikâyet formu
- Engellenen kullanıcılar

Moderator rolü gerektiren ekranlar:

- Moderasyon kuyruğu
- Moderasyon şikâyet detayı
- Moderasyon karar ekranı

## 25. Kullanıcı akışı

~~~mermaid
flowchart TD
    Start[Uygulama Açılışı] --> Token{Geçerli token var mı?}
    Token -- Hayır --> Login[Login]
    Login --> Register[Register]
    Register --> Login
    Login --> Feed[Feed]
    Token -- Evet --> Feed

    Feed --> Profile[Profil]
    Feed --> PostDetail[Gönderi Detayı]
    Feed --> Compose[Gönderi Oluştur]
    Compose --> Feed

    Profile --> ProfilePosts[Profil Gönderileri]
    Profile --> Followers[Takipçiler]
    Profile --> Following[Takip Edilenler]
    Profile --> Follow[Follow / Unfollow]
    Profile --> Block[Block / Unblock]
    Profile --> UserReport[Kullanıcı Şikâyeti]

    ProfilePosts --> PostDetail
    Followers --> OtherProfile[Profil]
    Following --> OtherProfile
    OtherProfile --> ProfilePosts
    OtherProfile --> Followers
    OtherProfile --> Following

    PostDetail --> Like[Like / Unlike]
    PostDetail --> Reply[Yanıt Yaz]
    PostDetail --> PostReport[Gönderi Şikâyeti]

    Settings[Ayarlar] --> BlockedUsers[Engellenen Kullanıcılar]
    BlockedUsers --> Profile

    Feed --> Logout[Çıkış]
    Logout --> Login

    ModeratorHome[Moderator Girişi] --> ModerationQueue[Moderasyon Kuyruğu]
    ModerationQueue --> ModerationDetail[Şikâyet Detayı]
    ModerationDetail --> ModerationDecision[Resolve / Dismiss]
    ModerationDecision --> ModerationQueue
~~~

Geçiş kuralları:

- Login -> Register
- Register -> Login
- Login -> Feed
- Feed -> Profil
- Feed -> Gönderi detayı
- Feed -> Gönderi oluşturma
- Profil -> Profil gönderileri
- Profil -> Takipçiler
- Profil -> Takip edilenler
- Profil gönderileri -> Gönderi detayı
- Takipçiler -> Profil
- Takip edilenler -> Profil
- Profil -> Follow/Unfollow
- Profil -> Block/Unblock
- Profil -> Kullanıcı şikâyeti
- Gönderi detayı -> Like/Unlike
- Gönderi detayı -> Reply
- Gönderi detayı -> Gönderi şikâyeti
- Ayarlar -> Engellenen kullanıcılar
- Engellenen kullanıcılar -> Profil
- Feed -> Logout -> Login
- Moderasyon kuyruğu -> Şikâyet detayı
- Şikâyet detayı -> Moderasyon kararı
- Moderasyon kararı -> Moderasyon kuyruğu

Token gerektiren route token olmadan açılmaya çalışılırsa login ekranına dönülür.

Moderator route'u standart `User` rolüyle açılmamalıdır. Backend erişim kontrolü yine zorunludur.

Block nedeniyle görünmeyen profil veya profile bağlı alt ekran için canonical not-found akışı kullanılır.

## 26. API kontratı tek kaynak kuralı

HTTP path, request body, response body, enum değeri veya JSON alan adı konusunda `docs/api-contract.md` tek kaynaktır.

Backend ve mobil:

- alternatif alan adı üretemez,
- endpoint alias/fallback tanımlayamaz,
- farklı enum casing kullanamaz.

JSON alanları camelCase'dir.

Paylaşılan enum string değerleri API kontratındaki casing ile birebir kullanılır.

Profil, profil gönderileri ve sosyal graf listeleri için alan adları mobil tarafından tahmin edilmez.

## 27. Test stratejisi

Backend integration testleri en az aşağıdakileri doğrulamalıdır:

- `/health` anonim 200
- register/login anonim
- korumalı endpoint token gereksinimi
- profil read modeli alanları
- profil oluşturulma zamanı
- görünür post sayısı
- follower/following sayaçları
- oturum sahibinin takip durumu
- profil gönderilerinde yalnız görünür kök postlar
- profil gönderilerinde deterministic sıralama
- profil gönderileri empty state
- followers listesi
- following listesi
- sosyal graf listelerinde takip durumu
- sosyal graf listelerinde block görünürlüğü
- olmayan profil için sosyal graf `404`
- mevcut profil + boş collection için `200`
- block create/remove
- self-block reddi
- block sonrası follow temizliği
- block sonrası feed görünürlüğü
- report create
- self-report reddi
- duplicate açık report `409`
- normal kullanıcının moderation endpoint'inden `403` alması
- moderator queue
- resolve `NoAction`
- resolve `RemovePost`
- dismiss
- ikinci moderation kararında `409`
- gizlenmiş postun feed/like/reply/profil gönderileri akışından çıkarılması

Backend integration testlerindeki request gövdeleri `docs/api-contract.md` golden JSON örnekleriyle aynı alan adlarını kullanmalıdır.

Mobil testleri en az:

- profil response parse
- profil gönderileri parse
- followers/following parse
- takip durumu alanı
- collection empty state
- block/unblock sonucu
- report request alanları
- unauthorized yönlendirme
- forbidden moderasyon durumu
- loading/empty/error durumları

üzerinde canonical kontratı doğrulamalıdır.

## 28. Güvenlik ilkeleri

- Şifreler düz metin saklanmaz.
- JWT production secret repoda tutulmaz.
- Authorization yalnızca mobil UI ile uygulanmaz.
- Moderasyon yetkisi backend'de role göre doğrulanır.
- Block ilişkisi server-side sorgularda uygulanır.
- Sosyal graf sorguları block görünürlüğünü server-side uygular.
- Kullanıcı girdileri doğrulanır.
- Moderasyon notu ve report details alanları güvenilmeyen kullanıcı girdisi kabul edilir.
- SQL oluşturmak için kullanıcı girdisi birleştirilmez; EF Core parametreli sorgular kullanılır.
- Hata response'ları gereksiz iç sistem ayrıntısı içermez.
- Block nedeniyle gizlenen kaynağın varlığı kullanıcıya açık edilmez.
- Moderasyon aksiyonları audit için kalıcı olarak saklanır.

## 29. Mimari karar özeti

- Mimari: modüler monolit
- Backend: .NET 8 ASP.NET Core
- Mobil: Flutter
- Veritabanı: PostgreSQL
- Auth: JWT Bearer
- Kimlik: integer
- JSON: camelCase
- Post metni: `content`
- Maksimum post/reply: 280 karakter
- Health: anonim `GET /health`
- Development JWT fallback: zorunlu
- Flutter web CORS origin: `http://127.0.0.1:8080`
- API adresi: `http://127.0.0.1:5000`
- Profil gönderileri: mevcut post read modeli
- Sosyal graf: mevcut follows ilişkisi
- Sosyal graf için yeni tablo: yok
- Profil sayaçları: mevcut veriden türetilir
- Block görünürlüğü: profil, post ve sosyal graf okumalarında uygulanır
- Block ilişkisi: yönlü
- Report hedefleri: `Post`, `User`
- Report durumları: `Pending`, `Resolved`, `Dismissed`
- Moderator aksiyonları: `NoAction`, `RemovePost`
- Moderasyon kaldırması: fiziksel DELETE değil
- Redis: bu fazlarda zorunlu değil
- MinIO: bu fazlarda zorunlu değil

## 30. Sosyal Graf ve Profil Tamamlama canonical kararları

### 30.1 Profil sayaçları

Profil read modelindeki sayaçlar backend tarafından hesaplanır.

Görünür gönderi sayısı yalnız:

- hedef kullanıcının gönderisi,
- kök gönderi,
- silinmemiş gönderi,
- moderasyonla gizlenmemiş gönderi

koşullarını sağlayan kayıtları kapsar.

Takipçi sayısı mevcut follow ilişkilerinden türetilir.

Takip edilen sayısı mevcut follow ilişkilerinden türetilir.

Yeni sayaç persistence sütunu bu görev için zorunlu değildir.

### 30.2 Profil gönderileri collection'ı

Profil gönderileri mevcut post response modelini kullanır.

Kurallar:

- target username canonical profile namespace üzerinden çözülür,
- yalnız kök gönderiler döner,
- görünürlük filtreleri server-side uygulanır,
- sıralama en yeni gönderiden eskiye doğrudur,
- boş liste hata değildir.

### 30.3 Followers ve following collection'ları

Followers ve following aynı sosyal graf liste öğesi modelini kullanır.

Liste öğesi:

- kullanıcı kimliği,
- username,
- displayName,
- avatarUrl,
- oturum sahibinin bu kullanıcıyı takip edip etmediği

bilgilerini taşır.

Kesin HTTP property adları `docs/api-contract.md` içinde tanımlanır.

Block nedeniyle görünmeyen hesaplar listeden çıkarılır.

### 30.4 Read HTTP semantiği

Profile bağlı collection için:

- hedef profil yoksa `404`,
- hedef profil block nedeniyle görünmezse `404`,
- hedef profil mevcut fakat collection boşsa `200` ve boş `items`.

Bu kural profil gönderileri, takipçiler ve takip edilenler için aynıdır.

### 30.5 Tek kaynak yaklaşımı

Sosyal graf verisi için yeni servis veya ikinci persistence modeli oluşturulmaz.

Canonical kaynaklar:

- kullanıcı: `users`
- gönderiler: `posts`
- takip ilişkisi: `follows`
- görünürlük: `user_blocks`

olarak kalır.

API alan isimleri, liste response'ları ve exact endpoint yolları yalnız `docs/api-contract.md` tarafından belirlenir.