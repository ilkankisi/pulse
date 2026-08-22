# Feature: Profil özeti ve gönderiler

## Scope
Profil header, sayaçlar, follow CTA ve gönderi listesi.

## Components
Profil özeti

Token: {components.profile-summary}, {components.profile-stats}, {components.relationship-button}

Widget hierarchy:

```
Column
├── Row
│   ├── CircleAvatar(size: 80)
│   └── actions
│       ├── own profile:
│       │   └── OutlinedButton("Profili Düzenle")
│       └── other profile:
│           └── FilledButton | OutlinedButton
│               └── "Takip Et" | "Takibi Bırak"
├── Text(displayName)
├── Text(@username)
├── Text(bio, optional)
├── Row: profileStats
│   ├── InkWell | TextButton
│   │   └── RichText(followingCount + " Takip")
│   │       └── onTap: FollowingPage(profile.username)
│   └── InkWell | TextButton
│       └── RichText(followerCount + " Takipçi")
│           └── onTap: FollowersPage(profile.username)
└── Divider
```

fluttertemplates kaynağı: Profile / Profile Header — https://fluttertemplates.dev/widgets/profile

Kurallar:

profile.username, ekranda görüntülenen profilin kullanıcı adıdır.

Başka bir kullanıcı profili görüntülenirken current-user username kullanılmaz.

Kendi profili ile başka profil aynı sayaç widget'ını kullanır.

“Takip” → FollowingPage(profile.username).

“Takipçi” → FollowersPage(profile.username).

Sayaçların tamamı minimum 44x44px dokunma alanına sahiptir.

Başka profilde follow state'e göre yalnız “Takip Et” veya “Takibi Bırak” gösterilir.

Kendi profilinde follow ve block aksiyonu gösterilmez.

Profil gönderileri mevcut post component'iyle listelenir.

Follow/unfollow loading sırasında CTA tekrar tetiklenemez.

Sayaçlar mutation sonrası backend state ile senkronize edilir.

Profil güncelleme başarı mesajı: “Profil güncellendi.”

## Screen states
Profil

Empty state

Başlık: "Henüz gönderi yok"

Açıklama: "Bu kullanıcının henüz gönderisi yok."

Kendi profilinde CTA: "Gönderi Oluştur"

Başka profilde zorunlu primary CTA yoktur.

Error state

Ağ/5xx: "Profil yüklenemedi"

Kullanıcı bulunamazsa: "Kullanıcı bulunamadı"

CTA: "Tekrar Dene"

401 login akışına gider.

Success

Profil güncelleme: "Profil güncellendi."

Follow: "Takip edildi."

Unfollow: "Takip bırakıldı."

App bar vs body CTA

"Profili Düzenle" profil header içindedir.

Follow CTA başka profil header'ındadır.

“Takip” ve “Takipçi” sayaçları profil body/header içindeki navigation aksiyonlarıdır.

## Navigation
Bottom nav / drawer Profil; sayaç tap → social-graph feature.
