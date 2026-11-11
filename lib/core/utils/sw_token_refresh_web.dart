/// Web platformunda JS flag kontrolü yapan yardımcı fonksiyonlar.
/// notification_service.dart'tan çağrılır.
///
/// Bu dosya web platformunda çalışır, stub dosyası (sw_token_refresh_stub.dart)
/// ise native platformlarda kullanılır.

import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// window._swTokenRefreshNeeded flag'ini kontrol et ve temizle.
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
void addFcmTokenRefreshListener(Function callback, {Function? onExpired}) {
  try {
    web.window.addEventListener(
      'fcm-token-refresh-needed',
      (web.Event event) {
        try {
          String reason = '';
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
          callback();
        }
      }.toJS,
    );
  } catch (e) {
    // Web API'sı desteklenmiyorsa sessizce devam et
  }
}

/// Service Worker'a kullanıcının Firebase UID'sini gönderir.
/// SW bunu IndexedDB'de saklar — uygulama kapalıyken de token yenileyebilmek için.
void sendUserIdToSw(String userId) {
  _postMessageToSw({'type': 'SET_USER_ID', 'userId': userId});
}

/// Çıkış yapılınca SW'deki userId'yi temizle.
void clearUserIdFromSw() {
  _postMessageToSw({'type': 'CLEAR_USER_ID'});
}

/// SW'ye mesaj gönder — ready promise tamamlanınca active controller'a iletir.
void _postMessageToSw(Map<String, String> msg) {
  try {
    final sw = web.window.navigator.serviceWorker;
    // toDart ile Future'a çevir, async olarak gönder
    sw.ready.toDart.then((reg) {
      final controller = reg.active;
      if (controller != null) {
        controller.postMessage(msg.jsify());
      }
    }).catchError((_) {/* sessiz hata */});
  } catch (e) {
    // Sessiz hata — kritik değil
  }
}
