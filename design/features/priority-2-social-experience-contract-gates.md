Öncelik 2 Sosyal Deneyim Kontrat Kapıları

Scope
Bu feature, Öncelik 2 sosyal deneyim akışlarının ürün ve API kontratıyla uyumlu çalışması için gerekli tasarım kapılarını tanımlar.
Amaçları:
Sosyal deneyim ekranlarında yalnızca desteklenen davranışların kullanıcıya sunulması.
Veri bekleme, boş sonuç, hata ve başarılı veri durumlarının açık biçimde tasarlanması.
Liste, detay ve profil geçişlerinin tutarlı navigasyon davranışı göstermesi.
API tarafından desteklenmeyen bir davranışın yalnızca arayüz seviyesinde varmış gibi gösterilmemesi.
Kullanıcının yaptığı sosyal aksiyonlardan sonra ekrandaki durumun güncel sonucu açık biçimde yansıtması.
### Request body kontrat kapısı

- Mobil toJson çıktısı ve HTTP request body yapısı backend testlerinde doğrulanan golden JSON ile birebir aynı alan adlarını ve değer semantiğini kullanır.
- UI veya repository katmanı kontratta bulunmayan ek request alanı üretmez.
- Alan adları istemci tarafında yeniden adlandırılmaz; backend golden JSON hangi JSON key'i tanımlıyorsa mobil aynı key'i gönderir.
- Enum/string değerleri UI metinlerinden türetilmez; canonical kontratta tanımlanan wire değerleri kullanılır.
- null, boş string ve alanın hiç gönderilmemesi birbirinin yerine kullanılmaz; backend golden JSON ve canonical API kontratındaki semantik korunur.
- Collection create işlemleri yalnız endpoint matrisindeki POST sözleşmesini, güncelleme işlemleri ise yalnız tanımlı update method/path sözleşmesini kullanır; istemci farklı method veya payload şekli tahmin etmez.
### Takip edilenler akışı kontrat kapısı

- Boss kapsamındaki Tümü ve Takip Ettiklerim ayrımı ürün hedefidir.
- Güncel backend endpoint matrisinde akış için yalnızca GET /api/v1/feed tanımlıdır.
- Takip Ettiklerim için ayrı endpoint, query parametresi veya filtre sözleşmesi tanımlı değilse mobil katman bunlardan birini tahmin ederek üretmez.
- Kontrat desteği bulunmadığı sürece Takip Ettiklerim sekmesi gerçek veri kaynağı varmış gibi aktif bir akış yüzeyi olarak sunulmaz.
- Kontrat bu ayrımı destekleyecek şekilde güncellendiğinde iki görünüm de aynı durum modelini kullanır: loading, empty, error ve success.
- Akışın kronolojik sıralaması backend kontratından gelir; istemci ek bir sıralama semantiği uydurmaz.

Components

Sosyal deneyim akışlarında ihtiyaç oldukça aşağıdaki bileşenler kullanılır:

Kullanıcı satırı veya kullanıcı kartı.

Avatar, görünen ad ve @username kimlik alanları.

Sosyal ilişki durumunu gösteren aksiyon alanı.

Gönderi kartı.

Liste bölümü ve bölüm başlığı.

Yükleniyor göstergesi.

Boş durum bileşeni.

Hata mesajı ve tekrar deneme aksiyonu.

Sayfa veya liste yenileme davranışı.

Navigasyon için dokunulabilir kullanıcı ve gönderi yüzeyleri.

Aynı sosyal aksiyon birden fazla ekranda bulunuyorsa etiket, durum ve geri bildirim davranışı tutarlı olmalıdır.

Screen states

Her veri kullanan sosyal deneyim yüzeyi aşağıdaki durumları ayırt eder:

Loading

İlk veri yüklenirken kullanıcıya yükleme durumu gösterilir.

Henüz veri alınmamışken yanlış bir boş durum gösterilmez.

Mevcut veri yenilenirken içerik gereksiz yere kaybolmamalıdır.

Empty

İstek başarıyla tamamlanmış ancak gösterilecek veri yoksa açık bir boş durum gösterilir.

Boş durum hata gibi sunulmaz.

Kullanıcının yapabileceği anlamlı bir sonraki aksiyon varsa boş durum içinde gösterilebilir.

Error

İstek başarısız olduğunda kullanıcıya anlaşılır bir hata durumu gösterilir.

Tekrar denenebilen okuma işlemlerinde tekrar deneme aksiyonu sağlanır.

Başarısız sosyal aksiyonlar başarılıymış gibi kalıcı biçimde gösterilmez.

Success

Başarılı veri yüklemesinde gerçek içerik gösterilir.

Kullanıcı tarafından gerçekleştirilen başarılı sosyal aksiyon sonrasında ilgili görsel durum güncellenir.

Sayaç, durum etiketi veya aksiyon metni kullanılıyorsa ekrandaki yeni durumla tutarlı kalır.

Navigation

Kullanıcı adı, avatar veya kullanıcıyı temsil eden dokunulabilir alan profil ekranına yönlendirir.

Gönderiyi temsil eden dokunulabilir alan, detay akışı destekleniyorsa gönderi detayına yönlendirir.

Alt sayfadan geri dönüldüğünde kullanıcı mümkün olduğunca önceki sosyal bağlamına geri döner.

Aynı hedefe giden farklı sosyal yüzeyler tutarlı navigasyon davranışı kullanır.

Sadece navigasyon amacıyla ikinci ve bağımsız bir ana uygulama kabuğu oluşturulmaz.

Navigasyon hedefi ürün veya kontrat kapsamında desteklenmiyorsa kullanıcıya çalışmayan bir geçiş sunulmaz.