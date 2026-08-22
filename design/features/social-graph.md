# Feature: Takipçiler ve takip edilenler

## Scope
Profil sayaçlarından açılan sosyal graf listeleri.

## Components
Sosyal graf kullanıcı satırı

Token: {components.social-graph-list-item}, {components.relationship-button}

Widget hierarchy:

```
SocialGraphListItem(user)
└── InkWell
    └── ConstrainedBox(minHeight: 72)
        └── Padding
            └── Row
                ├── CircleAvatar(size: 48)
                ├── SizedBox(width: spacing.md)
                ├── Expanded
                │   └── Column(crossAxis: start)
                │       ├── Text(user.displayName)
                │       └── Text("@${user.username}")
                └── relationship action
                    ├── user == currentUser
                    │   └── no action
                    ├── isFollowing == false
                    │   └── FilledButton("Takip Et")
                    └── isFollowing == true
                        └── OutlinedButton("Takibi Bırak")
```

fluttertemplates kaynağı: Core / Lists — https://fluttertemplates.dev/widgets

Kurallar:

Avatar, displayName, username veya satırın profil alanına dokunulduğunda ProfilePage(user.username) açılır.

Parent Followers/Following ekranının username'i yerine satırdaki user.username kullanılır.

Kullanıcının kendi satırında follow CTA gösterilmez.

Relationship state canonical backend sonucundan gelir.

Follow/unfollow sırasında yalnız ilgili satır CTA'sı disabled/loading olur.

Tüm liste loading state'e dönmez.

Optimistic update kullanılırsa hata halinde eski state geri alınır.

Follow/unfollow sonrası profil ve sosyal graf sayaçları backend sonucuyla senkronize edilir.

Engelle/şikâyet aksiyonları bu satıra eklenmez; profil güvenlik menüsünden yürütülür.

Takipçiler listesi

Token: {components.social-graph-list-item}, {components.state-panel}

Widget hierarchy:

```
FollowersPage(username)
└── Scaffold
    ├── AppBar
    │   ├── leading: BackButton
    │   └── title
    │       └── Column
    │           ├── Text("Takipçiler")
    │           └── optional Text("@username")
    └── SafeArea
        └── state
            ├── loading-state
            ├── empty-state
            ├── error-state
            └── CustomScrollView
                └── SliverList
                    └── SocialGraphListItem[]
```

fluttertemplates kaynağı: Core / Lists — https://fluttertemplates.dev/widgets

Kurallar:

Ekran zorunlu username route parametresi alır.

Veri kaynağı: GET /api/v1/profiles/{username}/followers.

{username}, sosyal grafı görüntülenen profilin username değeridir.

Kendi profilimde sayaçtan açıldığında kendi username'im kullanılır.

Başka profilin sayacından açıldığında o profilin username'i kullanılır.

Liste ilgili profilin takipçilerini gösterir.

Satırdan profile geçerken row.username kullanılır.

Profil A'nın takipçileri içinde Profil B'ye girildiğinde Profil B'nin sayaçları Profil B username'i ile yeni sosyal graf açar.

Geri navigasyonda kaynak FollowersPage(username) route'u korunur.

Mümkünse scroll pozisyonu korunur.

404 kayıt-yok semantiği taşıyorsa empty state olarak ele alınır.

Ağ/5xx empty state'e dönüştürülmez.

401 login akışına gider.

Empty durumda boş SliverList render edilmez.

UI canonical API dışında endpoint veya query parametresi üretmez.

Takip Edilenler listesi

Token: {components.social-graph-list-item}, {components.state-panel}

Widget hierarchy:

```
FollowingPage(username)
└── Scaffold
    ├── AppBar
    │   ├── leading: BackButton
    │   └── title
    │       └── Column
    │           ├── Text("Takip Edilenler")
    │           └── optional Text("@username")
    └── SafeArea
        └── state
            ├── loading-state
            ├── empty-state
            ├── error-state
            └── CustomScrollView
                └── SliverList
                    └── SocialGraphListItem[]
```

fluttertemplates kaynağı: Core / Lists — https://fluttertemplates.dev/widgets

Kurallar:

Ekran zorunlu username route parametresi alır.

Veri kaynağı: GET /api/v1/profiles/{username}/following.

{username}, sosyal grafı görüntülenen profilin username değeridir.

Kendi profilimde sayaçtan açıldığında kendi username'im kullanılır.

Başka profilin sayacından açıldığında o profilin username'i kullanılır.

Liste ilgili profilin takip ettiği kullanıcıları gösterir.

Satırdan profile geçerken row.username kullanılır.

Profil A'nın takip listesi içinden Profil B'ye geçildiğinde Profil B sosyal grafı Profil B username'iyle açılır.

Geri navigasyonda kaynak FollowingPage(username) route'u korunur.

Mümkünse scroll pozisyonu korunur.

Relationship CTA canonical backend state'e göre gösterilir.

404 kayıt-yok semantiği taşıyorsa error değildir.

Ağ/5xx error state'tir.

401 login akışına gider.

Empty durumda boş SliverList render edilmez.

UI canonical API dışında endpoint veya query parametresi üretmez.

## Screen states
Takipçiler

Route

FollowersPage(username)

API: GET /api/v1/profiles/{username}/followers

{username} = sosyal grafı görüntülenen profil.

Empty state

Başlık: "Henüz takipçi yok"

Açıklama: "Bu hesabı henüz kimse takip etmiyor."

Birincil CTA yoktur.

Error state

Başlık: "Takipçiler yüklenemedi"

Açıklama: "Takipçi listesi alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

404 kayıt-yok error değildir.

401 login akışına gider.

Success

Liste yüklenmesinde snackbar yoktur.

Follow: "Takip edildi."

Unfollow: "Takip bırakıldı."

App bar vs body CTA

AppBar: geri + "Takipçiler".

Follow/unfollow ilgili satırdadır.

Takip Edilenler

Route

FollowingPage(username)

API: GET /api/v1/profiles/{username}/following

{username} = sosyal grafı görüntülenen profil.

Empty state

Başlık: "Henüz kimse takip edilmiyor"

Açıklama: "Takip edilen hesaplar burada görünür."

Birincil CTA yoktur.

Error state

Başlık: "Takip edilenler yüklenemedi"

Açıklama: "Takip edilen hesaplar alınırken bir sorun oluştu."

CTA: "Tekrar Dene"

404 kayıt-yok error değildir.

401 login akışına gider.

Success

Liste yüklenmesinde snackbar yoktur.

Follow: "Takip edildi."

Unfollow: "Takip bırakıldı."

App bar vs body CTA

AppBar: geri + "Takip Edilenler".

Follow/unfollow ilgili satırdadır.

## Navigation
Profil Takip/Takipçi sayaçlarından; liste satırı → profil.
