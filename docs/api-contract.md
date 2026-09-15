---PATCH

@@

-Backend integration testlerinde kullanılan golden JSON canonical wire-format kaynağıdır. Mobil toJson çıktısı ve HTTP'ye gönderilen gerçek request body, golden JSON ile property adı, JSON tipi, null/omission semantiği ve enum string değerlerinde birebir eşleşmelidir. Golden JSON'da bulunmayan alanın eklenmesi, bulunan alanın atlanması, anahtarın yeniden adlandırılması, alias kullanılması veya değer tipinin/string case'inin değiştirilmesi hem serializer hem de gerçek request katmanında kontrat ihlalidir.

+Request body taşıyan mutation'larda backend integration testlerinde kullanılan golden JSON canonical wire-format kaynağıdır. Mobil toJson çıktısı ve HTTP'ye gönderilen gerçek request body, golden JSON ile property adı, JSON tipi, null/omission semantiği ve enum string değerlerinde birebir eşleşmelidir. Golden JSON'da bulunmayan alanın eklenmesi, bulunan alanın atlanması, anahtarın yeniden adlandırılması, alias kullanılması veya değer tipinin/string case'inin değiştirilmesi hem serializer hem de gerçek request katmanında kontrat ihlalidir. Canonical kontratta request body taşımadığı belirtilen mutation'larda mobil istemci JSON/request body üretmemelidir; bu endpoint'lerde golden request-body eşitliği aranmaz.

---END PATCH