import 'dart:html' as html;

bool isPWA() {
  final isStandalone = html.window.matchMedia('(display-mode: standalone)').matches;
  final isFullscreen = html.window.matchMedia('(display-mode: fullscreen)').matches;
  final isMinimalUi = html.window.matchMedia('(display-mode: minimal-ui)').matches;
  
  return isStandalone || isFullscreen || isMinimalUi;
}
