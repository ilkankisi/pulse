POST /api/v1/posts/{postId}/likes
DELETE /api/v1/posts/{postId}/likes
Like mutation read-after-write kontratı:
- POST /api/v1/posts/{postId}/likes request body taşımaz. Başarılı mutation sonrasında aynı post canonical olarak yeniden okunduğunda isLiked=true olmalı ve kullanıcının like'ı daha önce yoksa likeCount önceki canonical değere göre tam +1 değişmelidir.
- DELETE /api/v1/posts/{postId}/likes request body taşımaz. Başarılı mutation sonrasında aynı post canonical olarak yeniden okunduğunda isLiked=false olmalı ve kullanıcının like'ı daha önce varsa likeCount önceki canonical değere göre tam -1 değişmelidir.
- Like/unlike başarısı yalnızca mutation HTTP sonucuyla doğrulanmaz; persisted like ilişkisi ile yeniden okunan post'un isLiked ve likeCount alanları aynı state'i göstermelidir. Sayaç hiçbir durumda aynı kullanıcı için yinelenen mutation nedeniyle ikinci kez artırılıp azaltılmamalıdır.
POST / PUT sonrasında dönen kaynak tekrar okunduğunda, yazma isteğinde ifade edilen kontratla tutarlı olmalıdır.
- Build ve testlerin geçmesi tek başına read-after-write bütünlüğü için yeterli kabul edilmez; backend wire contract, mobil toJson / request body ve yazma sonrası yeniden okunan response aynı alan semantiğini korumalıdır.
- Bu katmanlardan herhangi birinde alan adı, JSON tipi, null/omission davranışı veya yazılan değerin yeniden okunması farklıysa kontrat kırılmış kabul edilir.
Build ve testlerin geçmesi tek başına read-after-write bütünlüğü için yeterli kabul edilmez. Aşağıdaki katmanlar birbirinden bağımsız doğrulanır: backend wire contract, mobil `toJson` / gerçek HTTP request body, backend persisted state ve yazma sonrasında canonical GET response ile yeniden okunan state. Bu katmanlardan herhangi biri property adı, JSON tipi, null/omission davranışı veya değer semantiğinde canonical kontrattan saparsa read-after-write bütünlüğü kırmızı kabul edilir.
Bu katmanlardan herhangi birinde alan adı, JSON tipi, null/omission davranışı veya yazılan değerin yeniden okunması farklıysa kontrat kırılmış kabul edilir.
- Read-after-write kontrolünde yalnızca HTTP başarı kodu veya geçen build/test sonucu yeterli değildir: mobil toJson / gerçek request body ile gönderilen değer, backend'de kalıcı hale gelen state ve sonraki GET response içinde gözlenen değer aynı kontrat semantiğini taşımalıdır.
- Bu üç katmandan herhangi biri diğerlerinden sapıyorsa ürün bütünlüğü kırmızı kabul edilir; testlerin yeşil olması bu uyumsuzluğu geçerli kılmaz.
- Backend'in kabul edip normalize ettiği alanlar varsa normalizasyon davranışı kontratta açık olmalı; mobil taraf yeniden okunan normalize edilmiş değeri geçerli canonical state olarak kabul etmelidir.
Backend integration testlerinde kullanılan golden JSON canonical wire-format kaynağıdır. Mobil `toJson` çıktısı ve HTTP'ye gönderilen gerçek request body, golden JSON ile property adı, JSON tipi, null/omission semantiği ve enum string değerlerinde birebir eşleşmelidir. Golden JSON'da bulunmayan alanın eklenmesi, bulunan alanın atlanması, anahtarın yeniden adlandırılması, alias kullanılması veya değer tipinin/string case'inin değiştirilmesi hem serializer hem de gerçek request katmanında kontrat ihlalidir.
GET /api/v1/profiles/{username}
GET /api/v1/profiles/{username}/followers
GET /api/v1/profiles/{username}/following
GET /api/v1/profiles/{username}/posts
Bu üç katmandan herhangi biri diğerlerinden sapıyorsa ürün bütünlüğü kırmızı kabul edilir; testlerin yeşil olması bu uyumsuzluğu geçerli kılmaz.
- Katman kontrolü mobil toJson, HTTP'ye çıkan gerçek request body, backend persisted state ve read-after-write GET response için ayrı ayrı uygulanmalıdır; bu katmanlardan tek birinin bile canonical wire-format veya beklenen semantikten sapması, build ve testler geçse dahi bütünlük hatasıdır.
- Orchestrator pipeline_gate backend katmanı için engel raporlamasa bile canonical kontrat ile mobil serialization/request body arasındaki read-after-write uyumu architect katmanında ayrıca sağlanmalıdır; pipeline geçişi bu kontrat doğrulamasının yerine geçmez.