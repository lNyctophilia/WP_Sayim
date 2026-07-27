import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/app_notification.dart';

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
        await _saveTokenToDatabase();
        
        // Token yenilendiğinde dinle ve güncelle
        _messaging.onTokenRefresh.listen(_updateToken);
      } else {
        debugPrint('Kullanıcı bildirim iznini reddetti.');
      }
    } catch (e) {
      debugPrint('Bildirim başlatılırken hata (Desteklenmiyor olabilir): $e');
    }
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
        
        // Başarılı olursa eski hatayı temizle
        await _firestore.collection('users').doc(user.uid).set(
          {'fcmError': FieldValue.delete()},
          SetOptions(merge: true),
        );
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

  /// Token'ı Firestore'da güncelle
  Future<void> _updateToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
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
