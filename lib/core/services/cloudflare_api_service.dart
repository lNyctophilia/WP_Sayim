import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Cloudflare Workers API servisi
/// Firebase Functions'dan taşınan backend fonksiyonlarını HTTP üzerinden çağırır.
///
/// Flutter app'te Firestore yazma işlemi yapıldıktan sonra,
/// ilgili bildirim/sync işlemi için bu servis çağrılır.
class CloudflareApiService {
  /// Cloudflare Worker URL'i
  /// Deploy sonrası bu URL güncellenecek
  static const String _baseUrl = 'https://wp-sayim-api.nycgamedevs.workers.dev';
  // TODO: Deploy sonrası gerçek URL ile değiştir

  static final CloudflareApiService _instance = CloudflareApiService._();
  factory CloudflareApiService() => _instance;
  CloudflareApiService._();

  /// Firebase Auth'tan idToken al
  Future<String?> _getIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      debugPrint('[CF API] Error getting idToken: $e');
      return null;
    }
  }

  /// POST request gönder (fire-and-forget, hata olursa logla)
  Future<void> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await _getIdToken();
      if (token == null) {
        debugPrint('[CF API] No auth token, skipping $endpoint');
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[CF API] $endpoint failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Fire-and-forget — hata olursa UI'ı bloklamaz
      debugPrint('[CF API] $endpoint error: $e');
    }
  }

  // ─── DAVET BİLDİRİMLERİ ───

  /// Yeni davet oluşturulduğunda çağır (sendDavetNotification)
  Future<void> notifyDavetCreated({
    required String davetId,
    required Map<String, dynamic> davetData,
  }) async {
    await _post('/api/notify/davet-created', {
      'davetId': davetId,
      'davetData': davetData,
    });
  }

  /// Davet yanıtlandığında çağır (sendDavetResponseNotification)
  Future<void> notifyDavetResponse({
    required String davetId,
    required String oldStatus,
    required String newStatus,
    required String userId,
    required String sayimId,
  }) async {
    await _post('/api/notify/davet-response', {
      'davetId': davetId,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
      'userId': userId,
      'sayimId': sayimId,
    });
  }

  /// Davet hatırlatma gönderildiğinde çağır (sendDavetReminderNotification)
  Future<void> notifyDavetReminder({
    required String davetId,
    required String userId,
    required String sayimId,
  }) async {
    await _post('/api/notify/davet-reminder', {
      'davetId': davetId,
      'userId': userId,
      'sayimId': sayimId,
    });
  }

  /// Davet iptal edildiğinde (silindiğinde) çağır (sendDavetCancelledNotification)
  Future<void> notifyDavetCancelled({
    required String davetId,
    required Map<String, dynamic> davetData,
  }) async {
    await _post('/api/notify/davet-cancelled', {
      'davetId': davetId,
      'davetData': davetData,
    });
  }

  // ─── AUTH SYNC ───

  /// Kullanıcı bilgileri güncellendiğinde çağır (syncUserWithAuth)
  Future<void> syncUserAuth({
    required String userId,
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
  }) async {
    await _post('/api/sync-user-auth', {
      'userId': userId,
      'oldData': oldData,
      'newData': newData,
    });
  }

  /// Kullanıcı silindiğinde çağır (deleteUserFromAuth)
  Future<void> deleteUserAuth({required String userId}) async {
    await _post('/api/delete-user-auth', {
      'userId': userId,
    });
  }

  // ─── KULLANICI BİLDİRİMLERİ ───

  /// Kullanıcı onaylandığında çağır (sendApprovalNotification)
  Future<void> notifyApproval({
    required String userId,
    required bool oldIsApproved,
    required bool newIsApproved,
    String? email,
  }) async {
    await _post('/api/notify/approval', {
      'userId': userId,
      'oldIsApproved': oldIsApproved,
      'newIsApproved': newIsApproved,
      'email': email,
    });
  }

  /// Test bildirimi gönder (sendTestNotification)
  Future<void> notifyTest({required String userId}) async {
    await _post('/api/notify/test', {
      'userId': userId,
    });
  }

  // ─── SAYIM BİLDİRİMLERİ ───

  /// Davetin grubu değiştirildiğinde çağır (sendDavetGrupChangedNotification)
  Future<void> notifyDavetGrupChanged({
    required String davetId,
    required int oldGrupId,
    required int newGrupId,
    required String userId,
    required String sayimId,
    required String status,
    bool isPast = false,
  }) async {
    await _post('/api/notify/davet-grup-changed', {
      'davetId': davetId,
      'oldGrupId': oldGrupId,
      'newGrupId': newGrupId,
      'userId': userId,
      'sayimId': sayimId,
      'status': status,
      'isPast': isPast,
    });
  }

  /// Sayım grubunun saati değiştirildiğinde çağır (sendSayimTimeChangedNotification)
  Future<void> notifySayimTimeChanged({
    required String sayimId,
    required List<Map<String, dynamic>> oldGruplar,
    required List<Map<String, dynamic>> newGruplar,
  }) async {
    await _post('/api/notify/sayim-time-changed', {
      'sayimId': sayimId,
      'oldGruplar': oldGruplar,
      'newGruplar': newGruplar,
    });
  }
}
