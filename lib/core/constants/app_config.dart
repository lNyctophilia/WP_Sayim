/// Uygulama konfigürasyonu — versiyon .bat ile buradan güncellenir
class AppConfig {
  AppConfig._();

  static const String _buildVersion = String.fromEnvironment('BUILD_VERSION');
  
  static String get version {
    if (_buildVersion.isNotEmpty) {
      String displayVersion = _buildVersion;
      // Harfleri ve alt tireleri temizle (örn: "Cum_24.07.2026-_6:46" -> "24.07.2026-6:46:...")
      displayVersion = displayVersion.replaceAll(RegExp(r'[A-Za-z_]'), '');
      
      var parts = displayVersion.split(':');
      if (parts.length >= 2) {
        displayVersion = '${parts[0]}:${parts[1]}';
      }
      return '($displayVersion)';
    }
    return 'Geliştirici Sürümü'; // Local ortamda çalışırken görünecek metin
  }

  static const String developerName = 'lNyctophilia';
}
