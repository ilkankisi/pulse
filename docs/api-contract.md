POST /api/v1/auth/register
POST /api/v1/auth/login
GET /api/v1/feed
POST /api/v1/posts
DELETE /api/v1/posts/{postId}
POST /api/v1/posts/{postId}/replies
POST /api/v1/posts/{postId}/likes
DELETE /api/v1/posts/{postId}/likes
GET /api/v1/me
PUT /api/v1/me
GET /api/v1/profiles/{username}
GET /api/v1/profiles/{username}/posts
GET /api/v1/profiles/{username}/followers
GET /api/v1/profiles/{username}/following
POST /api/v1/profiles/{username}/follow
DELETE /api/v1/profiles/{username}/follow
POST /api/v1/profiles/{username}/block
DELETE /api/v1/profiles/{username}/block
GET /api/v1/blocks
POST /api/v1/reports
GET /health

READ_AFTER_WRITE: Request body taşıyan mutation'larda backend integration testlerinde kullanılan golden JSON canonical wire-format kaynağıdır. Mobil toJson çıktısı ve transport katmanında HTTP'ye gerçekten gönderilen request body ayrı ayrı golden JSON ile property adı, JSON tipi, null/omission semantiği ve enum string değerlerinde birebir eşleşmelidir. toJson doğru olsa bile transport katmanının alan eklemesi, atlaması, yeniden adlandırması, alias kullanması veya değer tipi/string case değiştirmesi kontrat ihlalidir. Canonical kontratta request body taşımadığı belirtilen mutation'larda mobil istemci JSON/request body üretmemelidir; bu endpoint'lerde golden request-body eşitliği aranmaz.