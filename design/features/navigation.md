Feature: Uygulama navigasyonu

Scope

Ana akış ve profil destination'ları; sosyal graf ve güvenlik yönetimi global nav değildir.

Components

Uygulama navigasyonu

Token: {components.navigation-drawer}, {components.bottom-navigation}

Widget hierarchy:

Scaffold
├── drawer: NavigationDrawer
│   ├── header: DrawerHeader
│   │   └── Row
│   │       ├── CircleAvatar
│   │       └── Column (ad, @kullanıcı)
│   ├── destinations[]
│   │   ├── NavigationDrawerDestination ("Ana Akış")
│   │   ├── NavigationDrawerDestination ("Profil")
│   │   └── moderator ise NavigationDrawerDestination ("Moderasyon")
│   └── footer: ListTile (logout, "Çıkış yap")
├── bottomNavigationBar: NavigationBar
│   └── destinations: "Ana Akış", "Profil"
├── floatingActionButton: FloatingActionButton.extended
│   └── icon: edit + label: "Gönder"
└── body: aktif ekran

fluttertemplates kaynağı: Navigation Drawer — https://fluttertemplates.dev/widgets/navigation

Kurallar:

Drawer ve kalıcı sidebar aynı destination listesini paylaşır.

Aktif route ikinci kez stack'e eklenmez.

Moderator destination yalnızca yetkili kullanıcıya görünür.

Bottom Navigation iki ana destination içerir: Ana Akış ve Profil.

Takipçiler ve Takip Edilenler global destination değildir.

Takipçiler ve Takip Edilenler yalnız profil sosyal graf sayaçlarından açılır.

Engellenen Hesaplar global destination değildir; profil/hesap güvenliği alt akışından açılır.

401 genel error state olarak render edilmez; merkezi login akışına yönlendirilir.

Screen states

Oturum kontrolü loading; 401 login akışına gider.

Navigation

Drawer, bottom nav ve FAB ile ana ekranlar arası geçiş.

Moderator kullanıcı: Drawer Moderasyon → Moderasyon Kuyruğu → Şikâyet Detayı.

Profil / hesap güvenliği → Engellenen Hesaplar alt ekranı.