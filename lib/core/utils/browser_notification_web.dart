import 'dart:html' as html;

void showWebNotification(String title, String body) async {
  if (html.Notification.permission == 'granted') {
    try {
      html.Notification(title, body: body);
    } catch (e) {
      try {
        final reg = await html.window.navigator.serviceWorker?.ready;
        if (reg != null) {
          reg.showNotification(title, {'body': body});
        }
      } catch (e2) {
        html.window.console.error('Push bildirim hatası: $e2');
      }
    }
  }
}
