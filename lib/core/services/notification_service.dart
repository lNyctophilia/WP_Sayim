import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/app_notification.dart';
import '../utils/sw_token_refresh_stub.dart'
    if (dart.library.js_interop) '../utils/sw_token_refresh_web.dart'
    as sw_refresh;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
  // "Generate key pair" ile oluşturulan VAPID Key buraya girilecek.
  // Bu key olmadan Web Push bildirimleri çalışmaz!
  static const String _vapidKey =
      'BOkvHMWfKFEaXrwF-TgJ9KrrJSnNqL3tO966nz5F-esnB6SYZCfSIy6uWe9dvVTKfhPsTZ771DOsGVJY4JeDmio';

  /// İzin iste, token al ve Firestore'a kaydet
  /// Her uygulama açılışında çağrılır — iOS subscription yenilemelerini yakalamak için
  /// token'ı her seferinde agresif olarak Firestore'a yazar.
  Future<void> initialize() async {
    try {
      // 1. İzin İste (Özellikle iOS için gereklidir, Android 13+ için de prompt çıkar)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Kullanıcı bildirim izni verdi.');
        
        // ─── AGRESİF TOKEN YENİLEME ───
        // Her açılışta token'ı al ve Firestore'a yaz.
        // iOS subscription sessizce değişmiş olabilir, bu yüzden
        // "değişmediyse yazma" optimizasyonu YAPMIYORUZ.
        await _saveTokenToDatabase();
        
        // Token yenilendiğinde dinle ve güncelle
        _messaging.onTokenRefresh.listen(_updateToken);
        
        // ─── WEB: SERVICE WORKER MESAJ DİNLEYİCİSİ ───
        // iOS subscription değiştiğinde veya push alındığında SW'den 
        // 'fcm-token-refresh-needed' event'i gelir, biz de token'ı yenileriz.
        if (kIsWeb) {
          _listenForSubscriptionChanges();
        }
      } else {
        debugPrint('Kullanıcı bildirim iznini reddetti.');
      }
    } catch (e) {
      debugPrint('Bildirim başlatılırken hata (Desteklenmiyor olabilir): $e');
    }
  }

  /// Web platformunda Service Worker'dan gelen subscription değişikliği
  /// mesajlarını dinler ve token'ı yeniden kaydeder.
  void _listenForSubscriptionChanges() {
    try {
      // JS interop ile 'fcm-token-refresh-needed' custom event'ini dinle
      // Bu event, index.html'deki SW message listener tarafından fırlatılır.
      _addJsEventListener();
      debugPrint('[iOS Push Fix] SW subscription değişikliği dinleyicisi kuruldu.');
    } catch (e) {
      debugPrint('[iOS Push Fix] JS event listener kurulurken hata: $e');
    }
  }

  /// JS event listener'ı kur (web only)
  void _addJsEventListener() {
    if (!kIsWeb) return;
    
    try {
      // dart:js_interop kullanarak window.addEventListener çağır
      final callback = () async {
        debugPrint('[iOS Push Fix] Token yenileme sinyali alındı! Yeniden kaydediliyor...');
        
        // Mevcut token'ı sil ve yenisini al
        try {
          await _messaging.deleteToken();
          debugPrint('[iOS Push Fix] Eski token silindi, yenisi alınıyor...');
        } catch (e) {
          debugPrint('[iOS Push Fix] Token silme hatası (devam ediliyor): $e');
        }
        
        // Yeni token al ve Firestore'a kaydet
        await _saveTokenToDatabase();
      };
      
      // Web platformunda window event listener'ı kur
      _registerWebEventListener(callback);
    } catch (e) {
      debugPrint('[iOS Push Fix] Event listener kurma hatası: $e');
    }
  }

  /// Web event listener kayıt (conditional import ile)
  void _registerWebEventListener(Function callback) {
    // Web platformunda çalışan JS interop kodu
    // index.html'deki 'fcm-token-refresh-needed' custom event'ini dinler
    try {
      // 1. Doğrudan JS event listener — anında tetiklenir
      sw_refresh.addFcmTokenRefreshListener(callback);
      
      // 2. Periyodik kontrol (fallback) — JS event kaçırılırsa flag'den yakala
      Future.delayed(const Duration(seconds: 10), () async {
        _startTokenRefreshPolling(callback);
      });
    } catch (e) {
      debugPrint('[iOS Push Fix] Listener/Polling kurulurken hata: $e');
    }
  }

  /// Periyodik token yenileme kontrolü (Web only, 60 saniyede bir)
  void _startTokenRefreshPolling(Function callback) async {
    // Her 60 saniyede bir JS flag'ini kontrol et
    while (true) {
      await Future.delayed(const Duration(seconds: 60));
      try {
        if (!kIsWeb) break;
        // window._swTokenRefreshNeeded flag'ini kontrol et
        // Bu flag, SW'den mesaj geldiğinde index.html'de true yapılıyor
        if (_checkAndClearRefreshFlag()) {
          await callback();
        }
      } catch (e) {
        // Hata olsa bile döngüye devam
        debugPrint('[iOS Push Fix] Polling kontrolü hatası: $e');
      }
    }
  }

  /// JS tarafındaki _swTokenRefreshNeeded flag'ini kontrol et ve temizle
  bool _checkAndClearRefreshFlag() {
    if (!kIsWeb) return false;
    try {
      return _checkJsRefreshFlag();
    } catch (e) {
      return false;
    }
  }

  /// JS flag kontrolü (web only, conditional import)
  static bool _checkJsRefreshFlag() {
    return sw_refresh.checkAndClearSwRefreshFlag();
  }

  /// Kayıt sırasında kullanmak için (veritabanına yazmadan) token alır
  Future<String?> getTokenForRegistration() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kIsWeb) {
          return await _messaging.getToken(vapidKey: _vapidKey);
        } else {
          return await _messaging.getToken();
        }
      }
    } catch (e) {
      debugPrint('Kayıt için FCM Token alınırken hata (Desteklenmiyor olabilir): $e');
    }
    return null;
  }

  /// FCM Token alıp kullanıcının Firestore dokümanına kaydetme
  /// Her çağrıda token'ı Firestore'a yazar (iOS subscription yenilemelerini yakalamak için)
  Future<void> _saveTokenToDatabase() async {
    final user = _auth.currentUser;
    if (user == null) return; // Giriş yapılmamışsa kaydetme

    try {
      String? token;
      if (kIsWeb) {
        // Web platformunda VAPID Key gerekli
        token = await _messaging.getToken(vapidKey: _vapidKey);
      } else {
        // Android/iOS
        token = await _messaging.getToken();
      }
      if (token != null) {
        await _updateToken(token);
        
        // Başarılı olursa eski hatayı ve invalidation bilgisini temizle
        // (Backend, geçersiz token tespit ettiğinde bu alanları set ediyor)
        await _firestore.collection('users').doc(user.uid).set(
          {
            'fcmError': FieldValue.delete(),
            'fcmTokenInvalidatedAt': FieldValue.delete(),
            'fcmTokenInvalidReason': FieldValue.delete(),
          },
          SetOptions(merge: true),
        );
        debugPrint('[iOS Push Fix] Token başarıyla kaydedildi ve eski hata bilgileri temizlendi.');
      }
    } catch (e) {
      debugPrint('FCM Token alınırken hata: $e');
      // Mobil cihazın console ekranını göremediğimiz için, hatayı Firestore'a kaydediyoruz!
      try {
        await _firestore.collection('users').doc(user.uid).set(
          {'fcmError': e.toString()},
          SetOptions(merge: true),
        );
      } catch (innerError) {
        debugPrint('Hata veritabanına yazılamadı: $innerError');
      }
    }
  }

  /// Uygulama arka plandan (uykudan) döndüğünde çağrılır
  /// iOS subscription yenilemelerini yakalamak ve "keep-alive" yapmak için 
  /// optimizasyon yapmadan agresif olarak token'ı günceller.
  Future<void> refreshTokenOnResume() async {
    debugPrint('[iOS Push Fix] Uygulama uykudan uyandı, token agresif olarak yenileniyor...');
    await _saveTokenToDatabase();
  }

  /// Token'ı Firestore'da güncelle
  Future<void> _updateToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'pushVersion': 2, // Yeni: Keep-alive (sessiz bildirim) sürüm kontrolü
      });
      debugPrint('FCM Token Firestore\'a kaydedildi.');
    } catch (e) {
      debugPrint('FCM Token güncellenirken hata: $e');
    }
  }

  /// Çıkış yaparken token'ı sil (Başka hesaba bildirim gitmemesi için)
  Future<void> clearToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });
      // Cihazdaki tokenı tamamen silmiyoruz (yeni girişte sorun yaşamamak için)
      // await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM Token silinirken hata: $e');
    }
  }

  /// Kullanıcıya ait genel bildirimleri (davetler dışındaki push notification verilerini) Firestore'dan çeker
  Stream<List<AppNotification>> getNotificationsByUser(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// Bir bildirimi okundu olarak işaretler
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Bildirim okundu işaretlenirken hata: $e');
    }
  }

  /// Kullanıcının tüm bildirimlerini okundu olarak işaretler
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Tüm bildirimler okundu işaretlenirken hata: $e');
    }
  }

  /// Yöneticiler (veya diğer kullanıcılar) için lokal işlem logu oluşturur (ör. sayım oluşturuldu, sildi)
  Future<void> logSystemAction({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Sistem logu oluşturulurken hata: $e');
    }
  }

  /// EmailJS ile E-posta Bildirimi
  /// Sadece veritabanında "email" alanı dolu olan (örn: eski iOS kullanan) kullanıcılara e-posta atar
  Future<void> sendEmailNotification({
    required String targetUserId,
    required String subject,
    required String textContent,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(targetUserId).get();
      if (!doc.exists) return;
      
      final email = doc.data()?['email'] as String?;
      if (email == null || email.trim().isEmpty) return; // Kullanıcının mail adresi yoksa gönderme
      
      // EmailJS API Ayarları (Site üzerinden alacağın kodları buraya yapıştır)
      const serviceId = 'service_qjvatbn';
      const templateId = 'template_9wd7j5s';
      const publicKey = '6Ybd1Uu2O5Es_Rdtq';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': email,
            'subject': subject,
            'message': textContent,
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('E-posta başarıyla gönderildi: $email');
      } else {
        debugPrint('E-posta gönderilemedi. Hata: ${response.body}');
      }
    } catch (e) {
      debugPrint('E-posta gönderilirken hata: $e');
    }
  }
}
