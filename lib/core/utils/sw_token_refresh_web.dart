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
        final boolVal = (flagValue as JSBoolean).toDart;
        if (boolVal) {
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
/// TOKEN_REFRESH_NEEDED, SUBSCRIPTION_CHANGED, SUBSCRIPTION_EXPIRED,
/// ve VISIBILITY_CHANGE sebeplerini dinler.
///
/// [onExpired] varsa sadece SUBSCRIPTION_EXPIRED event'inde çağrılır
/// (full re-subscribe gerekebilir). Verilmezse [callback] kullanılır.
void addFcmTokenRefreshListener(Function callback, {Function? onExpired}) {
  try {
    web.window.addEventListener(
      'fcm-token-refresh-needed',
      (web.Event event) {
        try {
          String reason = '';
          // CustomEvent.detail.reason'ı okumak için JS interop
          final jsEvent = event as JSObject;
          final detail = jsEvent.getProperty('detail'.toJS);
          if (detail != null) {
            final jsDetail = detail as JSObject;
            final reasonVal = jsDetail.getProperty('reason'.toJS);
            if (reasonVal != null) {
              reason = (reasonVal as JSString).toDart;
            }
          }

          if (reason == 'SUBSCRIPTION_EXPIRED' && onExpired != null) {
            onExpired();
          } else {
            callback();
          }
        } catch (_) {
          // Reason okuma başarısız olursa standart callback çağır
          callback();
        }
      }.toJS,
    );
  } catch (e) {
    // Web API'sı desteklenmiyorsa sessizce devam et
  }
}
