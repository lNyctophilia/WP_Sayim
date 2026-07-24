import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void showWebNotification(String title, String body) {
  if (web.Notification.permission == 'granted') {
    // PWA cache sorunlarını aşmak ve index.html'e bağımlı kalmamak için
    // JavaScript kodunu anlık olarak çalıştırıyoruz.
    final win = web.window as JSObject;
    if (!win.hasProperty('_tempShowNotification'.toJS).toDart) {
      win.callMethod('eval'.toJS, """
        window._tempShowNotification = async function(title, body) {
          try {
            const regs = await navigator.serviceWorker.getRegistrations();
            let reg = regs && regs.length > 0 ? regs[0] : await navigator.serviceWorker.ready;
            if (reg) {
              await reg.showNotification(title, {
                body: body,
                icon: 'icons/Icon-192.png',
                vibrate: [200, 100, 200],
                requireInteraction: true,
                tag: 'fg-notification-' + Date.now()
              });
            } else {
              new Notification(title, {body: body});
            }
          } catch(e) { console.error('Push hatası:', e); }
        };
      """.toJS);
    }
    
    win.callMethod('_tempShowNotification'.toJS, title.toJS, body.toJS);
  }
}
