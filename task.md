# WP Sayım — Görev Takip Listesi

## Adım 1 — Firebase Kurulumu + Flutter Entegrasyonu
- [x] `pubspec.yaml`'a Firebase paketlerini ekle
- [x] `main.dart`'ta `Firebase.initializeApp()` hazırla
- [x] Firebase Console'da proje oluştur (kullanıcı yapacak)
- [x] `flutterfire configure` komutu çalıştır (kullanıcı yapacak)
- [x] `flutter pub get` ile paketleri indir

## Adım 2 — Firestore Veri Modeli (Dart Model Sınıfları)
- [x] `AppUser` model sınıfı
- [x] `Sayim` model sınıfı
- [x] `Davet` model sınıfı
- [x] `TakvimGirisi` model sınıfı

## Adım 3 — Auth Servisi (Login)
- [x] `AuthService` oluştur (pseudo-email)
- [x] `LoginPage` UI oluştur

## Adım 4 — Rol Bazlı Yönlendirme
- [x] `UserService` oluştur
- [x] `AppRouter` oluştur
- [x] `main.dart` güncelle

## Adım 5 & 6 — Yönetici & Owner Paneli
- [x] `ManagerPanelPage` (Rol bazlı sekmeli yapı)
- [x] `UserListTab` (Yönetici ve Personel Listeleme/Aktif/Pasif)
- [x] `CreateUserDialog` (Yönetici ve Personel Oluşturma)
- [x] Yönlendirme (AppRouter güncellemesi)

## Adım 7 — Sayım Oluşturma
- [ ] `CreateSayimPage`
- [ ] Grup & personel seçici widgetlar
- [ ] `SayimService`

## Adım 8 — Davet + Bildirim
- [ ] `DavetService`
- [ ] Cloud Functions (FCM)
- [ ] `NotificationService`

## Adım 9 — Personel Davet Ekranı
- [ ] `DavetDetayPage`
- [ ] `DavetlerimPage`

## Adım 10 — Takvim Firestore Entegrasyonu
- [ ] Mevcut takvim UI'ını Firestore'a bağla
- [ ] Personel için salt okunur mod

## Adım 11 — Davet Durum Takibi (Yönetici)
- [ ] `SayimDetayPage`
- [ ] Hatırlatma & kişi değiştirme

## Adım 12 — Firestore Security Rules
- [ ] `firestore.rules` yaz

## Adım 13 — Test + Yayın
- [ ] Uçtan uca test
- [ ] Play Store güncellemesi
