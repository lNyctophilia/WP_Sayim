# 🔥 Firebase Kurulum Rehberi — WP Sayım

Bu rehber, WP Sayım uygulamasını çok kullanıcılı sisteme taşımak için gerekli Firebase kurulum adımlarını içerir.

---

## ✅ Tamamlanan (Kod Tarafı)

- [x] `pubspec.yaml` — Firebase paketleri eklendi (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`)
- [x] `main.dart` — `Firebase.initializeApp()` eklendi (options TODO olarak bekliyor)

---

## 📋 Senin Yapman Gerekenler

### 1. Firebase Console'da Proje Oluştur
1. https://console.firebase.google.com adresine git
2. **"Proje Ekle"** butonuna tıkla
3. Proje adı: `wp-sayim` (veya istediğin bir isim)
4. Google Analytics'i **kapatabileceğin** adımda ister aç ister kapat (zorunlu değil)
5. Projeyi oluştur

### 2. Firebase'e Android Uygulamasını Ekle
1. Proje panosunda **Android simgesine** tıkla
2. Package name: `com.example.daytrack` *(veya değiştirdiysen yeni package name)*
3. Uygulama adı: `WP Sayım`
4. SHA-1 anahtarı: *(şimdilik atlayabilirsin, sonra eklersin)*
5. `google-services.json` dosyasını indir
6. Bu dosyayı `android/app/` klasörüne koy

### 3. Firebase CLI Kur (Eğer yoksa)
```bash
# Node.js yüklüyse:
npm install -g firebase-tools

# Giriş yap:
firebase login
```

### 4. FlutterFire CLI Kur ve Yapılandır
```bash
# FlutterFire CLI kur:
dart pub global activate flutterfire_cli

# Proje dizininde çalıştır:
cd "c:\Users\Halil\Desktop\Code\7.Vibe Coding\WP_Sayim"
flutterfire configure --project=wp-sayim
```

Bu komut otomatik olarak `lib/firebase_options.dart` dosyasını oluşturacak.

### 5. main.dart'taki TODO'ları Tamamla
`lib/main.dart` dosyasındaki iki TODO satırını güncelle:
```dart
// Bu satırı uncomment et:
import 'firebase_options.dart';

// Bu satırı uncomment et (diğerini sil):
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### 6. Firebase Servislerini Etkinleştir
Firebase Console'da:
1. **Authentication** → "Email/Password" sağlayıcısını etkinleştir
2. **Firestore Database** → Veritabanı oluştur → **Test modunda** başla (sonra kuralları yazacağız)

### 7. Paketleri İndir
```bash
flutter pub get
```

### 8. Test Et
```bash
flutter run
```

---

## ⏭️ Bunlar Tamamlanınca Sonraki Adım
**Adım 2**: Firestore veri modeli (Dart model sınıfları) oluşturulacak.
Bana "Adım 2'ye geç" demen yeterli!

---

## 📊 Genel İlerleme Durumu

| Adım | Açıklama | Durum |
|------|----------|-------|
| 1 | Firebase Kurulumu | 🟡 Kod hazır, Firebase Console bekleniyor |
| 2 | Veri Modelleri (Dart) | ⬜ Bekliyor |
| 3 | Auth Servisi (Login) | ⬜ Bekliyor |
| 4 | Rol Bazlı Yönlendirme | ⬜ Bekliyor |
| 5 | Owner Paneli | ⬜ Bekliyor |
| 6 | Yönetici — Personel Yönetimi | ⬜ Bekliyor |
| 7 | Yönetici — Sayım Oluşturma | ⬜ Bekliyor |
| 8 | Davet + Bildirim (FCM) | ⬜ Bekliyor |
| 9 | Personel Davet Ekranı | ⬜ Bekliyor |
| 10 | Takvim Firestore Entegrasyonu | ⬜ Bekliyor |
| 11 | Davet Durum Takibi | ⬜ Bekliyor |
| 12 | Firestore Security Rules | ⬜ Bekliyor |
| 13 | Test + Yayın | ⬜ Bekliyor |
