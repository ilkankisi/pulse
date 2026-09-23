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
| GET | /api/v1/posts/{postId}/likes |
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

Like read-after-write canonical kararı: `POST /api/v1/posts/{postId}/likes` ve `DELETE /api/v1/posts/{postId}/likes` sonrasında persisted state'in tek read yüzeyi `GET /api/v1/posts/{postId}/likes` endpoint'idir. Workspace kontrat kanıtı olarak route matrisi bu GET'i içerir; POST ve DELETE için mevcut `READ_AFTER_WRITE` kayıtları bu GET'i hedefler; `likePost` ve `unlikePost` için mevcut `CLIENT_WRITE_READ` kayıtları da aynı GET'i hedefler. Backend runtime bu canonical GET route'u ile birebir eşleşmelidir. `GET /api/v1/feed` canonical read değildir. `CONTRACT_MUTATION_WITHOUT_READ` kapanış koşulu bu iki mutation için sağlanmıştır: mevcut canonical GET ile POST→GET ve DELETE→GET eşleşmeleri birlikte bulunduğundan POST/DELETE `/api/v1/posts/{postId}/likes` missing-read finding'i üretmez.

READ_AFTER_WRITE | POST /api/v1/posts | REQUIRED | GET /api/v1/feed

READ_AFTER_WRITE | DELETE /api/v1/posts/{postId} | EXEMPT | NONE

READ_AFTER_WRITE | POST /api/v1/posts/{postId}/replies | REQUIRED | GET /api/v1/posts/{postId}/replies

READ_AFTER_WRITE | POST /api/v1/posts/{postId}/likes | REQUIRED | GET /api/v1/posts/{postId}/likes
READ_AFTER_WRITE | DELETE /api/v1/posts/{postId}/likes | REQUIRED | GET /api/v1/posts/{postId}/likes
LIKE_READ_AFTER_WRITE_ACCEPTANCE

Bu karar yalnız doküman veya Manager onayıyla doğrulanmış sayılmaz. Kabul için aynı güncel workspace snapshot'ına bağlı AUTHORITATIVE_CURRENT_VERIFICATION kaydı aşağıdaki koşulların tamamını doğrudan kanıtlamalıdır. Güncel VERIFY kaydı yoksa veya herhangi bir kriter `not_verified` ise kabul kapısı kapanmaz ve görev doğrulanmış sayılmaz.

VERIFY_CRITERION | likeCanonicalRead | REQUIRED | workspace-current | route=GET /api/v1/posts/{postId}/likes; POST-read=GET /api/v1/posts/{postId}/likes; DELETE-read=GET /api/v1/posts/{postId}/likes
VERIFY_CRITERION | likeBackendRuntime | REQUIRED | workspace-current | runtime GET /api/v1/posts/{postId}/likes equals canonical GET /api/v1/posts/{postId}/likes
VERIFY_CRITERION | likeMobileRead | REQUIRED | workspace-current | likePost and unlikePost read target equals GET /api/v1/posts/{postId}/likes
VERIFY_CRITERION | mutationWithoutRead | REQUIRED | workspace-current | CONTRACT_MUTATION_WITHOUT_READ absent for POST /api/v1/posts/{postId}/likes and DELETE /api/v1/posts/{postId}/likes
VERIFY_GATE | likeReadAfterWrite | REQUIRED | AUTHORITATIVE_CURRENT_VERIFICATION[current-workspace-snapshot] | likeCanonicalRead=ok;likeBackendRuntime=ok;likeMobileRead=ok;mutationWithoutRead=ok
VERIFY_GATE | likeReadAfterWrite | FAIL_CLOSED | no current AUTHORITATIVE_CURRENT_VERIFICATION record or any criterion missing/not_verified
VERIFY_EVIDENCE_SOURCE | likeReadAfterWrite | REQUIRED | orchestrator-generated-current-run
VERIFY_WORKSPACE_EXPECTATION | likeCanonicalRead | docs/api-contract.md | GET /api/v1/posts/{postId}/likes
VERIFY_WORKSPACE_EXPECTATION | likePostReadAfterWrite | docs/api-contract.md | READ_AFTER_WRITE | POST /api/v1/posts/{postId}/likes | REQUIRED | GET /api/v1/posts/{postId}/likes
VERIFY_WORKSPACE_EXPECTATION | likeDeleteReadAfterWrite | docs/api-contract.md | READ_AFTER_WRITE | DELETE /api/v1/posts/{postId}/likes | REQUIRED | GET /api/v1/posts/{postId}/likes
VERIFY_WORKSPACE_EXPECTATION | likeBackendRuntime | backend | GET /api/v1/posts/{postId}/likes
VERIFY_WORKSPACE_EXPECTATION | likeMobileRead | mobile | likePost,unlikePost -> GET /api/v1/posts/{postId}/likes
VERIFY_WORKSPACE_EXPECTATION | mutationWithoutRead | verifier | CONTRACT_MUTATION_WITHOUT_READ=absent for POST,DELETE /api/v1/posts/{postId}/likes
ACCEPTANCE_GATE | managerApprovalOnly | REJECTED | not-verification-evidence
ACCEPTANCE_EVIDENCE | likeReadRoute | REQUIRED | GET /api/v1/posts/{postId}/likes endpoint matrisinde mevcut
ACCEPTANCE_EVIDENCE | likePostReadAfterWrite | REQUIRED | POST /api/v1/posts/{postId}/likes -> GET /api/v1/posts/{postId}/likes
ACCEPTANCE_EVIDENCE | likeDeleteReadAfterWrite | REQUIRED | DELETE /api/v1/posts/{postId}/likes -> GET /api/v1/posts/{postId}/likes
ACCEPTANCE_EVIDENCE | backendRuntimeLikeRead | REQUIRED | runtime GET /api/v1/posts/{postId}/likes canonical route ile birebir eşleşir
ACCEPTANCE_EVIDENCE | mobileLikeRead | REQUIRED | likePost,unlikePost -> getPostLikes -> GET /api/v1/posts/{postId}/likes
ACCEPTANCE_EVIDENCE | CONTRACT_MUTATION_WITHOUT_READ | REQUIRED | PASS

ACCEPTANCE_VERIFY | likeReadRoute | REQUIRED | AUTHORITATIVE_CURRENT_VERIFICATION
ACCEPTANCE_VERIFY | likePostReadAfterWrite | REQUIRED | AUTHORITATIVE_CURRENT_VERIFICATION
ACCEPTANCE_VERIFY | likeDeleteReadAfterWrite | REQUIRED | AUTHORITATIVE_CURRENT_VERIFICATION
ACCEPTANCE_VERIFY | backendRuntimeLikeRead | REQUIRED | AUTHORITATIVE_CURRENT_VERIFICATION
ACCEPTANCE_VERIFY | mobileLikeRead | REQUIRED | AUTHORITATIVE_CURRENT_VERIFICATION
ACCEPTANCE_VERIFY | CONTRACT_MUTATION_WITHOUT_READ | REQUIRED | AUTHORITATIVE_CURRENT_VERIFICATION

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

CLIENT_WRITE_READ | likePost | REQUIRED | GET /api/v1/posts/{postId}/likes
CLIENT_WRITE_READ | unlikePost | REQUIRED | GET /api/v1/posts/{postId}/likes

CLIENT_COUNT_LIST | getFollowers | REQUIRED | ListView
CLIENT_COUNT_LIST | getFollowing | REQUIRED | ListView
CLIENT_FALSE_EMPTY | getBlocks | REQUIRED | GET /api/v1/blocks
REQUEST_BODY_GOLDEN | toJson | REQUIRED | backend-integration-test-golden-json
REQUEST_BODY_GOLDEN | transport-request-body | REQUIRED | backend-integration-test-golden-json
REQUEST_BODY_NONE | canonical-no-body-mutation | REQUIRED | no-json-request-body

Request body taşıyan mutation'larda backend integration testlerinde kullanılan golden JSON tek canonical wire-format kaynağıdır. Mobil toJson çıktısı ve transport katmanında HTTP'ye gerçekten gönderilen request body, backend golden JSON ile birbirinden bağımsız olarak JSON nesnesi semantiğinde eşleşmelidir; yalnızca birbirleriyle eşleşmeleri yeterli değildir. Eşitlik property adını, JSON değer tipini, null/omission semantiğini ve enum string değerini kapsar; property sırası ile anlamsız whitespace/formatlama farkları dikkate alınmaz. İki bağımsız karşılaştırmadan herhangi birinin başarısız olması kontrat ihlalidir. Canonical kontratta request body taşımadığı belirtilen mutation'larda mobil istemci JSON/request body üretmemelidir; bu endpoint'lerde golden request-body eşitliği aranmaz.