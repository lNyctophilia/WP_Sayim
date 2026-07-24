/// Uygulama konfigürasyonu — versiyon .bat ile buradan güncellenir
class AppConfig {
  AppConfig._();

  static const String _buildVersion = String.fromEnvironment('BUILD_VERSION');
  
  static String get version {
    if (_buildVersion.isNotEmpty) {
      String displayVersion = _buildVersion;
      var parts = displayVersion.split(':');
      if (parts.length >= 2) {
        displayVersion = '${parts[0]}:${parts[1]}';
      }
      return 'Versiyon ($displayVersion)';
    }
    return 'Geliştirici Sürümü'; // Local ortamda çalışırken görünecek metin
  }

  static const String developerName = 'lNyctophilia';
}
