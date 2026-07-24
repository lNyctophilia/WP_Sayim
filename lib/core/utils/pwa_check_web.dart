import 'dart:html' as html;

bool isPWA() {
  final isStandalone = html.window.matchMedia('(display-mode: standalone)').matches;
  
  // Sadece standalone'u kontrol ediyoruz, minimal-ui mobil tarayıcılarda yanıltıcı olabiliyor.
  return isStandalone;
}

bool isMobileBrowser() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  return userAgent.contains('iphone') || 
         userAgent.contains('ipad') || 
         userAgent.contains('android') ||
         userAgent.contains('mobile');
}
