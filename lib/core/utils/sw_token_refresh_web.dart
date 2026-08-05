/// Web platformunda JS flag kontrolü yapan yardımcı fonksiyonlar.
/// notification_service.dart'tan çağrılır.
///
/// Bu dosya web platformunda çalışır, stub dosyası (sw_token_refresh_stub.dart)
/// ise native platformlarda kullanılır.

import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// window._swTokenRefreshNeeded flag'ini kontrol et ve temizle.
/// Service Worker, iOS subscription değişikliğinde bu flag'i true yapar.
bool checkAndClearSwRefreshFlag() {
  try {
    final win = web.window as JSObject;
    final hasFlag = win.hasProperty('_swTokenRefreshNeeded'.toJS).toDart;
    
    if (hasFlag) {
      final flagValue = win.getProperty('_swTokenRefreshNeeded'.toJS);
      if (flagValue != null) {
        // Dart'a çevir — boolean bekliyoruz
        final boolVal = (flagValue as JSBoolean).toDart;
        if (boolVal) {
          // Flag'i temizle
          win.setProperty('_swTokenRefreshNeeded'.toJS, false.toJS);
          return true;
        }
      }
    }
  } catch (e) {
    // Herhangi bir hata olursa false dön
  }
  return false;
}

/// Window'a 'fcm-token-refresh-needed' event listener'ı ekle.
/// Callback her tetiklendiğinde token yenileme döngüsünü başlatır.
void addFcmTokenRefreshListener(Function callback) {
  try {
    web.window.addEventListener(
      'fcm-token-refresh-needed',
      (web.Event event) {
        callback();
      }.toJS,
    );
  } catch (e) {
    // Web API'sı desteklenmiyorsa sessizce devam et
  }
}
