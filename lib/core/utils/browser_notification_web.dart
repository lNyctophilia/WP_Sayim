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
              const tag = 'sayim-group';
              const existingNotifications = await reg.getNotifications({ tag: tag });
              
              let newTitle = title;
              let newBody = body;
              let count = 1;

              if (existingNotifications && existingNotifications.length > 0) {
                const existing = existingNotifications[0];
                count = (existing.data && existing.data.count ? existing.data.count : 1) + 1;
                
                let lines = (existing.body || '').split('\\n');
                if(lines.length > 0 && lines[lines.length-1] === '...') {
                  lines.pop(); // Remove the trailing dots if they exist
                }
                
                lines.push(body); // Add new message
                
                // Keep only last 4 messages to avoid huge notifications
                if (lines.length > 4) {
                  lines = lines.slice(lines.length - 4);
                  lines.push('...');
                }
                
                newBody = lines.join('\\n');
                newTitle = count + ' Yeni Bildirim';
                
                existing.close(); // Close the previous one explicitly
              }

              await reg.showNotification(newTitle, {
                body: newBody,
                icon: 'icons/Icon-192.png',
                vibrate: [200, 100, 200],
                requireInteraction: true,
                tag: tag,
                renotify: true,
                data: { count: count }
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
