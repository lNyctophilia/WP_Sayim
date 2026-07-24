import 'dart:html' as html;
import 'dart:js' as js;

void showWebNotification(String title, String body) {
  if (html.Notification.permission == 'granted') {
    if (js.context.hasProperty('forceShowNotification')) {
      js.context.callMethod('forceShowNotification', [title, body]);
    } else {
      html.Notification(title, body: body);
    }
  }
}
