import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Web platformunda PWA tema renklerini günceller:
/// - meta theme-color (status bar / address bar)
/// - manifest background_color + theme_color (splash screen)
/// - body background-color (loading ekranı)
void updatePwaThemeColor(String hexColor) {
  try {
    final win = web.window as JSObject;
    // index.html'deki updatePwaTheme fonksiyonunu çağır
    if (win.hasProperty('updatePwaTheme'.toJS).toDart) {
      win.callMethod('updatePwaTheme'.toJS, hexColor.toJS);
    }
  } catch (e) {
    // Sessizce devam et — kritik olmayan özellik
  }
}
