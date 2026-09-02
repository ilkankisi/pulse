# Feature: Öncelik 2 sosyal deneyim akışları

## Scope

Bu feature profil merkezli sosyal graf deneyimini tamamlar:

- Profilde takipçi ve takip edilen sayılarını görüntüleme.

- Takipçi listesini açma.

- Takip edilenler listesini açma.

- Sosyal graf listesinden kullanıcı profiline geçme.

- Başka kullanıcıyı takip etme.

- Başka kullanıcıyı takipten çıkarma.

- Başka kullanıcı profillerinde ilişki durumuna göre doğru CTA'yı gösterme.

- Loading, empty, error ve mutation durumlarını tutarlı biçimde ele alma.

Tüm endpoint, response alanı ve permission davranışları canonical `docs/api-contract.md` sözleşmesinden map edilir.

UI:

- API kontratında olmayan sosyal ilişki durumu üretmez.

- API kontratında olmayan feed filtresi üretmez.

- API kontratında tanımlı değilse “Seni takip ediyor” veya “Karşılıklı takip” etiketi göstermez.

- Başka profil görüntülenirken current-user username kullanarak route bağlamını değiştirmez.

- Takipçi ve takip edilen sayılarının kaynağı canonical profile response'tur.

## User flows

### Profil → sosyal graf

- Profil yüklenir.

- `followerCount` ve `followingCount` canonical profile response'tan gösterilir.

- “Takipçi” sayacına dokunma → `FollowersPage(profile.username)`.

- “Takip” sayacına dokunma → `FollowingPage(profile.username)`.

- Açılan sosyal graf ekranı kendi route `username` bağlamını korur.

- Başka profil görüntülenirken endpoint current-user username ile değiştirilmez.

- Sosyal graf listesindeki kullanıcı satırına dokunma → `ProfilePage(row.username)`.

### Takipçiler

- `FollowersPage(username)` route parametresindeki profile ait takipçileri yükler.

- Başlık kullanıcıya anlaşılır şekilde “Takipçiler” olarak gösterilir.

- Liste canonical followers endpoint response'una göre render edilir.

- Her satır canonical kullanıcı kimliği ve username değerini kullanır.

- Satıra dokunulduğunda ilgili profil açılır.

- Liste boşsa empty state gösterilir.

- Network veya 5xx hatası empty state gibi gösterilmez.

- 401 merkezi login akışına gider.

- 403 normal empty state değildir.

- Yeniden deneme mevcut route username bağlamını korur.

### Takip edilenler

- `FollowingPage(username)` route parametresindeki profile ait takip edilen hesapları yükler.

- Başlık kullanıcıya anlaşılır şekilde “Takip Edilenler” olarak gösterilir.

- Liste canonical following endpoint response'una göre render edilir.

- Her satır canonical kullanıcı kimliği ve username değerini kullanır.

- Satıra dokunulduğunda ilgili profil açılır.

- Liste boşsa empty state gösterilir.

- Network veya 5xx hatası empty state gibi gösterilmez.

- 401 merkezi login akışına gider.

- 403 normal empty state değildir.

- Yeniden deneme mevcut route username bağlamını korur.

### Profilde follow / unfollow

Başka profil:

- `isFollowedByCurrentUser=false` → “Takip Et”.

- `isFollowedByCurrentUser=true` → “Takibi Bırak”.

- Kendi profilinde follow/unfollow CTA gösterilmez; mevcut profil düzenleme davranışı korunur.

Takip Et:

- Canonical follow endpoint'i `profile.username` ile çağrılır.

- Mutation süresince yalnız ilgili relationship CTA loading/disabled olur.

- Aynı mutation tekrar tetiklenemez.

- Başarı response'u canonical relationship state ile eşleşmelidir.

- Başarı sonrası profil state'i backend sonucuyla senkronize edilir.

- İlgili açık sosyal graf read state'i invalidate/refetch edilir.

- Başarısız mutation'da önceki doğrulanmış relationship state korunur.

Takibi Bırak:

- Canonical unfollow endpoint'i `profile.username` ile çağrılır.

- Mutation süresince yalnız ilgili relationship CTA loading/disabled olur.

- Aynı mutation tekrar tetiklenemez.

- Başarı sonrası profil state'i backend sonucuyla senkronize edilir.

- İlgili açık sosyal graf read state'i invalidate/refetch edilir.

- Başarısız mutation'da önceki doğrulanmış relationship state korunur.

### Sosyal graf satırında relationship aksiyonu

- Canonical response satır bazında ilişki aksiyonunu güvenilir biçimde destekliyorsa mevcut relationship CTA pattern'i reuse edilebilir.

- Canonical response gerekli ilişki bilgisini vermiyorsa liste satırında tahmini follow/unfollow butonu üretilmez.

- Satırın ana navigasyon davranışı her durumda `ProfilePage(row.username)` olur.

- Mutation aksiyonu ile satır navigasyonu birbirine karıştırılmaz.

## Components

### Profil sosyal istatistikleri

Token: `{components.profile-stats}`

Widget hierarchy:

ProfileStats

Row

StatButton

Text(followerCount)

Text("Takipçi")

StatButton

Text(followingCount)

Text("Takip")

Kurallar:

- Değerler canonical profile response'tan gelir.

- Sayaçlar local liste uzunluğundan türetilerek kalıcı kaynak kabul edilmez.

- Her sayaç minimum 44x44px dokunma alanına sahiptir.

- Dinamik metin ölçeklendirmede değer ve etiket okunabilir kalır.

- Profil sahibi değiştiğinde sayaçların route bağlamı da yeni `profile.username` olur.

### Sosyal graf liste öğesi

Token: `{components.social-graph-list-item}`

Widget hierarchy:

InkWell

Padding

Row

CircleAvatar

Expanded

Column

Text(displayName)

Text("@username")

optional relationship action

Kurallar:

- Avatar yoksa mevcut avatar fallback pattern'i reuse edilir.

- Display name ve username canonical response'tan gelir.

- Satıra dokunma → `ProfilePage(row.username)`.

- Tüm satırın minimum dokunma yüksekliği 44px'tir.

- Uzun display name tek satırda uygun ellipsis davranışı kullanabilir.

- Username görünür ve profile navigasyonunda canonical değer olarak kullanılır.

- Block/report gibi farklı amaçlı aksiyonlar bu satıra duplicate edilmez.

### Relationship CTA

Token: `{components.relationship-button}`

Durumlar:

- Follow ediliyor değil → FilledButton veya mevcut primary relationship button: “Takip Et”.

- Follow ediliyor → OutlinedButton veya mevcut secondary relationship button: “Takibi Bırak”.

- Mutation → spinner/progress indicator + disabled state.

- Kendi profilinde → relationship CTA yok.

Kurallar:

- Buton etiketi backend relationship state'e göre belirlenir.

- Optimistic görsel değişiklik kalıcı doğruluk kaynağı değildir.

- Başarılı response sonrası canonical state kullanılır.

- Hata durumunda kullanıcı tekrar deneyebilir.

- Layout buton etiketinin iki durumu arasında gereksiz sıçrama üretmemelidir.

## Screen states

### FollowersPage

Initial/loading:

- AppBar ve route bağlamı korunur.

- Liste alanında mevcut list skeleton/loading pattern'i kullanılır.

- Sahte kullanıcı satırı gösterilmez.

Empty:

Başlık: “Henüz takipçi yok”

Açıklama: “Bu hesabı henüz kimse takip etmiyor.”

- Empty state yalnız başarılı fakat boş canonical response için gösterilir.

- CTA zorunlu değildir.

Error:

Başlık: “Takipçiler yüklenemedi”

Açıklama: “Takipçiler alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

- 401 merkezi login akışına gider.

- 403 empty state gibi gösterilmez.

- Yeniden deneme aynı `username` route bağlamını kullanır.

### FollowingPage

Initial/loading:

- AppBar ve route bağlamı korunur.

- Liste alanında mevcut list skeleton/loading pattern'i kullanılır.

- Sahte kullanıcı satırı gösterilmez.

Empty:

Başlık: “Henüz kimseyi takip etmiyor”

Açıklama: “Bu hesabın takip ettiği kullanıcı bulunmuyor.”

- Empty state yalnız başarılı fakat boş canonical response için gösterilir.

- CTA zorunlu değildir.

Error:

Başlık: “Takip edilenler yüklenemedi”

Açıklama: “Takip edilen hesaplar alınırken bir sorun oluştu.”

CTA: “Tekrar Dene”

- 401 merkezi login akışına gider.

- 403 empty state gibi gösterilmez.

- Yeniden deneme aynı `username` route bağlamını kullanır.

### Follow mutation

Loading:

- Relationship CTA disabled olur.

- Sayfanın geri kalanı kullanılabilir kalır.

- Full-screen loading kullanılmaz.

Success:

- Backend'in canonical relationship state'i render edilir.

- Profile relationship state güncellenir.

- Follower/following count gerekiyorsa canonical refetch sonucuyla güncellenir.

- İlgili açık sosyal graf verisi invalidate/refetch edilir.

Error:

- Mutation öncesindeki doğrulanmış relationship state korunur.

- CTA tekrar kullanılabilir hale gelir.

- Network/5xx profil ekranını empty state'e dönüştürmez.

- 401 merkezi login akışına gider.

- 403 permission/error davranışı olarak gösterilir.

### Unfollow mutation

Loading:

- Relationship CTA disabled olur.

- Sayfanın geri kalanı kullanılabilir kalır.

- Full-screen loading kullanılmaz.

Success:

- Backend'in canonical relationship state'i render edilir.

- Profile relationship state güncellenir.

- Follower/following count gerekiyorsa canonical refetch sonucuyla güncellenir.

- İlgili açık sosyal graf verisi invalidate/refetch edilir.

Error:

- Mutation öncesindeki doğrulanmış relationship state korunur.

- CTA tekrar kullanılabilir hale gelir.

- Network/5xx profil ekranını empty state'e dönüştürmez.

- 401 merkezi login akışına gider.

- 403 permission/error davranışı olarak gösterilir.

## Navigation

- `ProfilePage(username)` → “Takipçi” → `FollowersPage(username)`.

- `ProfilePage(username)` → “Takip” → `FollowingPage(username)`.

- `FollowersPage(username)` → kullanıcı satırı → `ProfilePage(row.username)`.

- `FollowingPage(username)` → kullanıcı satırı → `ProfilePage(row.username)`.

- Follow/unfollow mutation route değiştirmez.

- Başka profil görüntülenirken sosyal graf endpoint'i current user adına çevrilmez.

- Back navigation önceki profil/list bağlamını korur.

## Contract boundaries

Bu feature canonical API'de bulunmayan davranışları tasarım gereksinimi gibi tanımlamaz.

Özellikle:

- “Takip Ettiklerim” feed filtresi canonical feed contract'ında açıkça tanımlı değilse gösterilmez.

- “Seni takip ediyor” etiketi canonical profile veya relationship response'unda alan olarak tanımlı değilse gösterilmez.

- “Karşılıklı takip” durumu canonical response'tan güvenilir biçimde türetilemiyorsa gösterilmez.

- Yeni relationship endpoint'i veya query parametresi üretilmez.

- Sosyal graf için client-side kalıcı ilişki kaynağı oluşturulmaz.

- Profile count değerleri liste uzunluğundan canonical alan yerine türetilmez.

## Do's and Don'ts

Do:

- Profil sayaçlarında canonical `followerCount` ve `followingCount` değerlerini kullan.

- Sosyal graf ekranlarında route `username` bağlamını koru.

- Satır navigasyonunda `row.username` kullan.

- Follow/unfollow CTA'yı backend relationship state'e göre göster.

- Mutation sırasında yalnız ilgili CTA'yı loading/disabled yap.

- Başarı sonrası backend sonucunu doğruluk kaynağı kabul et.

- Profil ve açık sosyal graf read state'ini gerektiğinde invalidate/refetch et.

- 401'i merkezi login akışına gönder.

- 403'ü empty state olarak gösterme.

- Minimum 44x44px dokunma alanını koru.

- Dinamik metin ölçeklendirmeyi destekle.

Don't:

- Başka profilin followers/following route'unda current-user username kullanma.

- API kontratında olmayan “Takip Ettiklerim” feed filtresi ekleme.

- Contract tanımlamıyorsa “Seni takip ediyor” etiketi üretme.

- Contract tanımlamıyorsa “Karşılıklı takip” etiketi üretme.

- Liste uzunluğunu canonical follower/following count yerine kalıcı kaynak kabul etme.

- Başarısız follow/unfollow mutation sonrası local optimistic state'i kalıcılaştırma.

- Sosyal graf satırlarına gereksiz block/report aksiyonları ekleme.

- Network hatasını başarılı boş liste gibi gösterme.

- Yeni role, permission, relationship status veya endpoint üretme.