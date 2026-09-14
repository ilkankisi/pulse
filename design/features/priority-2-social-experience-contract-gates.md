Öncelik 2 — Contract-gated sosyal deneyim yüzeyleri

Scope

Bu kaynak, Öncelik 2 sosyal deneyim kapsamındaki iki zorunlu kabul yüzeyini tanımlar:

Feed üzerinde Tümü / Takip Ettiklerim filtresi.

Profil üzerinde Seni takip ediyor / Karşılıklı takip ilişki göstergeleri.

Bu yüzeyler canonical API contract desteği henüz bulunmasa bile tasarım kapsamından çıkarılmaz. UI sözleşmede bulunmayan endpoint, query parametresi, response alanı veya ilişki durumu üretmez.

Takip Ettiklerim feed filtresi — contract-gated

Feed sosyal deneyim yüzeyinde iki seçenek bulunur:

Tümü

Takip Ettiklerim

Tümü, canonical feed davranışını kullanır.

Takip Ettiklerim, kabul kapsamının kalıcı bir parçasıdır. Canonical API contract bu filtre için gerekli endpoint veya filtre parametresini tanımladığında yalnız sözleşmede belirtilen istek ve response davranışı kullanılır.

Canonical contract desteği henüz yoksa:

Takip Ettiklerim seçeneği UI'dan kaldırılmaz.

Yeni endpoint veya query parametresi uydurulmaz.

Followers/following listeleri kullanılarak client-side feed üretilmez.

Seçenek contract-unavailable durumuna geçer.

Tümü akışı çalışmaya devam eder.

Widget hierarchy

FeedPage
└── Column
    ├── SegmentedButton
    │   ├── Segment("Tümü")
    │   └── Segment("Takip Ettiklerim")
    └── state
        ├── all-selected
        │   └── canonical feed content
        └── following-selected
            ├── loading
            │   └── feed loading state
            ├── success
            │   └── chronological post list
            ├── empty
            │   └── EmptyState
            ├── error
            │   └── ErrorState
            └── contract-unavailable
                └── StatePanel
                    ├── Text("Takip Ettiklerim")
                    └── Text("Bu akış şu anda kullanılamıyor.")

Kurallar

Filtre değişiminde seçili segment görsel olarak belirgindir.

Loading sırasında seçili filtre korunur.

Empty state yalnız kayıt-yok durumudur.

Network ve 5xx hataları empty state'e çevrilmez.

401 merkezi login akışına gider.

Contract-unavailable state bir hata response'u gibi sunulmaz.

Contract-unavailable state içinde birincil CTA gösterilmez.

Backend contract desteği gelmeden Mobile herhangi bir alternatif route veya filtre semantiği üretmez.

Profil ilişki göstergeleri — contract-gated

Başka kullanıcı profillerindeki ilişki metadata yüzeyi aşağıdaki kabul durumlarını destekler:

Seni takip ediyor

Karşılıklı takip

Bu etiketler yalnız canonical profile veya relationship response gerekli ilişki bilgisini açıkça verdiğinde gösterilir.

Seni takip ediyor, canonical veri görüntülenen kullanıcının current user'ı takip ettiğini doğruladığında gösterilir.

Karşılıklı takip, canonical veri iki yönlü takip ilişkisini doğruladığında gösterilir.

Karşılıklı takip gösterildiğinde aynı anda ikinci bir Seni takip ediyor etiketi tekrarlanmaz.

Follow/unfollow CTA ile bu göstergeler aynı semantiği taşımaz:

Follow/unfollow CTA: current user → görüntülenen profil ilişkisi.

Seni takip ediyor: görüntülenen profil → current user ilişkisi.

Karşılıklı takip: iki yönlü ilişkinin doğrulanmış hali.

Canonical contract ters yön veya karşılıklı ilişki bilgisini henüz vermiyorsa:

Boolean ilişki tahmini yapılmaz.

Followers/following listeleri client-side çaprazlanarak ilişki üretilmez.

Sahte Seni takip ediyor veya Karşılıklı takip etiketi gösterilmez.

İlişki metadata yüzeyi contract-unavailable durumda kalır.

Mevcut canonical follow/unfollow CTA davranışı etkilenmez.

Widget hierarchy

ProfilePage
└── ProfileHeader
    ├── Avatar
    ├── IdentityColumn
    │   ├── Text(displayName)
    │   ├── Text("@username")
    │   └── relationship metadata
    │       ├── Text("Seni takip ediyor")
    │       ├── Text("Karşılıklı takip")
    │       └── contract-unavailable: no relationship claim
    └── canonical follow/unfollow CTA

Kurallar

İlişki göstergeleri yalnız doğrulanmış canonical state üzerinden render edilir.

Karşılıklı takip, daha güçlü birleşik durumdur ve Seni takip ediyor etiketini tekrar ettirmez.

Contract-unavailable durumda ilişki iddiası taşıyan etiket gösterilmez.

Contract-unavailable, bu yüzeyi ürün kapsamından kaldırmaz.

Canonical contract gerekli alanları tanımladığında aynı metadata alanı gerçek ilişki durumunu gösterir.

UI yeni endpoint, query parametresi veya response field üretmez.