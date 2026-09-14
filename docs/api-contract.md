---PATCH

@@

-GET /api/v1/posts/{postId}/likes

POST /api/v1/posts/{postId}/likes

DELETE /api/v1/posts/{postId}/likes

---END PATCH
POST / PUT sonrasında dönen kaynak tekrar okunduğunda, yazma isteğinde ifade edilen kontratla tutarlı olmalıdır.
- Build ve testlerin geçmesi tek başına read-after-write bütünlüğü için yeterli kabul edilmez; backend wire contract, mobil toJson / request body ve yazma sonrası yeniden okunan response aynı alan semantiğini korumalıdır.
- Bu katmanlardan herhangi birinde alan adı, JSON tipi, null/omission davranışı veya yazılan değerin yeniden okunması farklıysa kontrat kırılmış kabul edilir.
Backend testlerinde kullanılan golden JSON kontratın referans wire-format'ıdır. Mobil toJson ve request body aynı property adlarını, JSON tiplerini ve null/omission davranışını üretmelidir; bu üç katmandan biri değiştiğinde diğerleriyle kontrat uyumu birlikte doğrulanmalıdır.