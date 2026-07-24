/// Uygulama konfigürasyonu — versiyon .bat ile buradan güncellenir
class AppConfig {
  AppConfig._();

  static const String _buildVersion = String.fromEnvironment('BUILD_VERSION');
  
  static String get version {
    if (_buildVersion.isNotEmpty) {
      return _buildVersion;
    }
    return 'Geliştirici Sürümü'; // Local ortamda çalışırken görünecek metin
  }

  static const String developerName = 'lNyctophilia';
}
