Pulse API sözleşmesi

Parse edilebilir endpoint matrisi. Orchestrator ürün semantiği uydurmaz; mutation/read ve istemci kuralları bu dosyadaki satırlardır.

| METHOD | Path |
| --- | --- |
| POST | /api/v1/auth/register |
| POST | /api/v1/auth/login |
| GET | /api/v1/feed |
| POST | /api/v1/posts |
| DELETE | /api/v1/posts/{postId} |
| POST | /api/v1/posts/{postId}/replies |
| GET | /api/v1/posts/{postId}/replies |
| POST | /api/v1/posts/{postId}/likes |
| DELETE | /api/v1/posts/{postId}/likes |
| GET | /api/v1/me |
| PUT | /api/v1/me |
| GET | /api/v1/profiles/{username} |
| GET | /api/v1/profiles/{username}/posts |
| GET | /api/v1/profiles/{username}/followers |
| GET | /api/v1/profiles/{username}/following |
| POST | /api/v1/profiles/{username}/follow |
| DELETE | /api/v1/profiles/{username}/follow |
| POST | /api/v1/profiles/{username}/block |
| DELETE | /api/v1/profiles/{username}/block |
| GET | /api/v1/blocks |
| POST | /api/v1/reports |
| GET | /health |

READ_AFTER_WRITE

Yalnızca backend'de var olan GET. Sibling GET uydurulmaz.

READ_AFTER_WRITE | POST /api/v1/posts | REQUIRED | GET /api/v1/feed

READ_AFTER_WRITE | DELETE /api/v1/posts/{postId} | EXEMPT | NONE

READ_AFTER_WRITE | POST /api/v1/posts/{postId}/replies | REQUIRED | GET /api/v1/posts/{postId}/replies

READ_AFTER_WRITE | POST /api/v1/posts/{postId}/likes | REQUIRED | GET /api/v1/feed

READ_AFTER_WRITE | DELETE /api/v1/posts/{postId}/likes | REQUIRED | GET /api/v1/feed

READ_AFTER_WRITE | PUT /api/v1/me | REQUIRED | GET /api/v1/me

READ_AFTER_WRITE | POST /api/v1/profiles/{username}/follow | REQUIRED | GET /api/v1/profiles/{username}

READ_AFTER_WRITE | DELETE /api/v1/profiles/{username}/follow | REQUIRED | GET /api/v1/profiles/{username}

READ_AFTER_WRITE | POST /api/v1/profiles/{username}/block | REQUIRED | GET /api/v1/blocks

READ_AFTER_WRITE | DELETE /api/v1/profiles/{username}/block | REQUIRED | GET /api/v1/blocks

READ_AFTER_WRITE | POST /api/v1/reports | EXEMPT | NONE

READ_AFTER_WRITE | POST /api/v1/auth/register | EXEMPT | NONE

READ_AFTER_WRITE | POST /api/v1/auth/login | EXEMPT | NONE

CLIENT_*
CLIENT_WRITE_READ hedefleri ilgili READ_AFTER_WRITE canonical GET hedefiyle aynı olmalıdır.

CLIENT_WRITE_READ | createPost | REQUIRED | getFeed

CLIENT_WRITE_READ | createReply | REQUIRED | /api/v1/posts/{postId}/replies

CLIENT_WRITE_READ | deletePost | REQUIRED | getFeed

CLIENT_WRITE_READ | updateMyProfile | REQUIRED | getMyProfile

CLIENT_WRITE_READ | followUser | REQUIRED | getProfile

CLIENT_WRITE_READ | unfollowUser | REQUIRED | getProfile

CLIENT_WRITE_READ | likePost | REQUIRED | getFeed

CLIENT_WRITE_READ | unlikePost | REQUIRED | getFeed

CLIENT_COUNT_LIST | getFollowers | REQUIRED | ListView
CLIENT_COUNT_LIST | getFollowing | REQUIRED | ListView
CLIENT_FALSE_EMPTY | getBlocks | REQUIRED | GET /api/v1/blocks
REQUEST_BODY_GOLDEN | toJson | REQUIRED | backend-integration-test-golden-json
REQUEST_BODY_GOLDEN | transport-request-body | REQUIRED | backend-integration-test-golden-json
REQUEST_BODY_NONE | canonical-no-body-mutation | REQUIRED | no-json-request-body

Request body taşıyan mutation'larda backend integration testlerinde kullanılan golden JSON tek canonical wire-format kaynağıdır. Mobil toJson çıktısı ve transport katmanında HTTP'ye gerçekten gönderilen request body, backend golden JSON ile birbirinden bağımsız olarak JSON nesnesi semantiğinde eşleşmelidir; yalnızca birbirleriyle eşleşmeleri yeterli değildir. Eşitlik property adını, JSON değer tipini, null/omission semantiğini ve enum string değerini kapsar; property sırası ile anlamsız whitespace/formatlama farkları dikkate alınmaz. İki bağımsız karşılaştırmadan herhangi birinin başarısız olması kontrat ihlalidir. Canonical kontratta request body taşımadığı belirtilen mutation'larda mobil istemci JSON/request body üretmemelidir; bu endpoint'lerde golden request-body eşitliği aranmaz.