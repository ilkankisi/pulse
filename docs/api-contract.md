---PATCH

@@

-GET /api/v1/posts/{postId}/likes

POST /api/v1/posts/{postId}/likes

DELETE /api/v1/posts/{postId}/likes

---END PATCH
POST / PUT sonrasında dönen kaynak tekrar okunduğunda, yazma isteğinde ifade edilen kontratla tutarlı olmalıdır.
- Build ve testlerin geçmesi tek başına read-after-write bütünlüğü için yeterli kabul edilmez; backend wire contract, mobil toJson / request body ve yazma sonrası yeniden okunan response aynı alan semantiğini korumalıdır.
- Bu katmanlardan herhangi birinde alan adı, JSON tipi, null/omission davranışı veya yazılan değerin yeniden okunması farklıysa kontrat kırılmış kabul edilir.
Build ve testlerin geçmesi tek başına read-after-write bütünlüğü için yeterli kabul edilmez; backend wire contract, mobil toJson / request body ve yazma sonrası yeniden okunan response aynı alan semantiğini korumalıdır.
Bu katmanlardan herhangi birinde alan adı, JSON tipi, null/omission davranışı veya yazılan değerin yeniden okunması farklıysa kontrat kırılmış kabul edilir.
- Read-after-write kontrolünde yalnızca HTTP başarı kodu veya geçen build/test sonucu yeterli değildir: mobil toJson / gerçek request body ile gönderilen değer, backend'de kalıcı hale gelen state ve sonraki GET response içinde gözlenen değer aynı kontrat semantiğini taşımalıdır.
- Bu üç katmandan herhangi biri diğerlerinden sapıyorsa ürün bütünlüğü kırmızı kabul edilir; testlerin yeşil olması bu uyumsuzluğu geçerli kılmaz.
- Backend'in kabul edip normalize ettiği alanlar varsa normalizasyon davranışı kontratta açık olmalı; mobil taraf yeniden okunan normalize edilmiş değeri geçerli canonical state olarak kabul etmelidir.
Backend testlerinde kullanılan golden JSON canonical wire-format kaynağıdır. Mobil toJson çıktısı ve HTTP'ye gönderilen gerçek request body, golden JSON ile property adı, JSON tipi ve null/omission semantiğinde birebir eşleşmelidir. toJson doğru olsa bile gönderim katmanında anahtar ekleme, silme, yeniden adlandırma veya değer tipini dönüştürme kontrat ihlalidir.
GET /api/v1/profiles/{username}
GET /api/v1/profiles/{username}/followers
GET /api/v1/profiles/{username}/following
GET /api/v1/profiles/{username}/posts