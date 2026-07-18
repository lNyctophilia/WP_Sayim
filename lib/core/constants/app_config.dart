/// Uygulama konfigürasyonu — versiyon .bat ile buradan güncellenir
class AppConfig {
  AppConfig._();

  static const String _baseVersion = '1.11.0';
  static const String _buildVersion = String.fromEnvironment('BUILD_VERSION');
  
  static String get version {
    if (_buildVersion.isNotEmpty) {
      // Tüm özel karakterleri temizle, sadece sayıları bırak
      return _buildVersion.replaceAll(RegExp(r'[^0-9]'), '');
    }
    return _baseVersion;
  }

  static const String developerName = 'lNyctophilia';
}
