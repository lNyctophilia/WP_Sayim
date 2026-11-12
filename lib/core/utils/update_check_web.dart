import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:web/web.dart' as web;

@JS('manualCheckForUpdates')
external JSPromise<JSString> _jsManualCheckForUpdates();

/// Web platformunda index.html'deki manualCheckForUpdates() JS fonksiyonunu çağırır.
/// Sonuç: 'updated', 'up_to_date', veya 'error'
Future<String> manualCheckForUpdates() async {
  try {
    final win = web.window as JSObject;
    if (!win.hasProperty('manualCheckForUpdates'.toJS).toDart) {
      debugPrint('[UpdateCheck] window.manualCheckForUpdates bulunamadı.');
      return 'error';
    }

    final result = await _jsManualCheckForUpdates().toDart;
    return result.toDart;
  } catch (e) {
    debugPrint('[UpdateCheck] Hata: $e');
    return 'error';
  }
}
