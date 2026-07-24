import 'dart:html' as html;

bool isPWA() {
  final isStandalone = html.window.matchMedia('(display-mode: standalone)').matches;
  
  // Sadece standalone'u kontrol ediyoruz, minimal-ui mobil tarayıcılarda yanıltıcı olabiliyor.
  return isStandalone;
}
