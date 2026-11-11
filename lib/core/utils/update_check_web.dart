import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:js_interop_unsafe';

/// Web platformunda index.html'deki manualCheckForUpdates() JS fonksiyonunu çağırır.
/// Sonuç: 'updated', 'up_to_date', veya 'error'
Future<String> manualCheckForUpdates() async {
  try {
    final jsResult = web.window.callMethod('manualCheckForUpdates'.toJS);
    if (jsResult == null || jsResult.isUndefined) return 'error';
    
    // JS Promise'i Dart Future'a çevir
    final promiseResult = await (jsResult as JSPromise).toDart;
    if (promiseResult == null || promiseResult.isUndefined) return 'error';
    
    return (promiseResult as JSString).toDart;
  } catch (e) {
    return 'error';
  }
}
