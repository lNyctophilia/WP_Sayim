import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// İzin iste, token al ve Firestore'a kaydet
  Future<void> initialize() async {
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
  }

  /// FCM Token alıp kullanıcının Firestore dokümanına kaydetme
  Future<void> _saveTokenToDatabase() async {
    final user = _auth.currentUser;
    if (user == null) return; // Giriş yapılmamışsa kaydetme

    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _updateToken(token);
      }
    } catch (e) {
      debugPrint('FCM Token alınırken hata: $e');
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
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM Token silinirken hata: $e');
    }
  }
}
