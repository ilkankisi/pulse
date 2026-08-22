# Feature: Moderasyon kuyruğu

## Scope
Moderator-only şikâyet inceleme ve aksiyonlar.

## Components
Moderasyon kuyruğu kartı

Token: {components.moderation-card}

Widget hierarchy:

```
CustomScrollView
└── SliverList
    └── Card
        └── Padding
            └── Column(crossAxis: start)
                ├── Row
                │   ├── target summary
                │   └── status badge
                ├── Text(report reason)
                ├── Text(report description, optional)
                ├── Text(metadata)
                └── action area
                    └── canonical moderator actions
```

fluttertemplates kaynağı: Core / Cards — https://fluttertemplates.dev/widgets

Kurallar:

Yalnız moderator kullanıcıya gösterilir.

Status ve action değerleri docs/api-contract.md ile map edilir.

UI yeni role/status/action üretmez.

İşlenen kayıt backend sonucuna göre yenilenir veya listeden çıkarılır.

## Screen states
Moderasyon Kuyruğu

Empty state

Başlık: "Bekleyen şikâyet yok"

Açıklama: "İncelenecek yeni şikâyet bulunmuyor."

CTA yoktur.

Error state

Başlık: "Moderasyon kuyruğu yüklenemedi"

Açıklama: "Şikâyetler alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

403 empty değildir.

401 login akışına gider.

Success

Backend'in güncel moderation sonucu render edilir.

App bar vs body CTA

Moderasyon aksiyonları ilgili kayıt body alanındadır.

Do's and Don'ts

Do

Material 3 semantik token'larını kullan.

Takipçiler ve Takip Edilenler için aynı SocialGraphListItem bileşenini kullan.

Profil sayaçlarını minimum 44x44px dokunma alanına sahip yap.

Kendi profilim ve başka profil için aynı Followers/Following ekranlarını yeniden kullan.

Followers route'una görüntülenen profilin username değerini geçir.

Following route'una görüntülenen profilin username değerini geçir.

Takipçiler için GET /api/v1/profiles/{username}/followers kullan.

Takip Edilenler için GET /api/v1/profiles/{username}/following kullan.

Liste satırından profile geçerken row.username kullan.

Profil A → sosyal graf → Profil B → Profil B sosyal graf zincirinde her route'un kendi username bağlamını koru.

Geri navigasyonda mümkünse sosyal graf scroll konumunu koru.

Follow/unfollow durumlarını backend ile senkronize et.

404 kayıt-yok durumunu empty state olarak ele al.

401'i login akışına gönder.

403'ü normal empty state gibi gösterme.

Moderator-only UI'ı role sonucuna göre gizle.

Minimum dokunma alanını 44x44px koru.

Don'ts

Başka profilin “Takipçi” sayacına basınca current-user takipçilerini açma.

Başka profilin “Takip” sayacına basınca current-user takip listesini açma.

Profil A listesindeki Profil B satırından profile geçerken A'nın username'ini kullanma.

Followers ve Following ekranlarını ana NavigationBar/NavigationDrawer öğesi yapma.

API kontratında olmayan sosyal graf endpoint'i üretme.

API kontratında olmayan cursor, offset veya pagination query parametresi üretme.

Takipçi/takip sayaçlarını yalnız local optimistic değerle kalıcı kaynak kabul etme.

Kullanıcının kendi sosyal graf satırında “Takip Et” veya “Takibi Bırak” gösterme.

Followers ve Following için birbirinden farklı duplicate kullanıcı satırı tasarlama.

Sosyal graf satırına duplicate “Engelle” veya “Şikâyet Et” aksiyonu ekleme.

Kayıt yok durumunu "yüklenemedi" error state'e dönüştürme.

401'i normal retry paneli olarak gösterme.

Moderator olmayan kullanıcıya moderation action gösterme.

API kontratında olmayan role, status veya moderation action üretme.

Çok seviyeli thread, DM veya kapsam dışı yeni özellik ekleme.

## Navigation
Drawer Moderasyon destination (moderator rolü).
