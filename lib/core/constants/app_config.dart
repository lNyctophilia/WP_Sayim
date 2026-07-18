/// Uygulama konfigürasyonu — versiyon .bat ile buradan güncellenir
class AppConfig {
  AppConfig._();

  static const String _baseVersion = '1.11.0';
  static const String _buildVersion = String.fromEnvironment('BUILD_VERSION');
  
  static String get version => _buildVersion.isNotEmpty ? '$_baseVersion ($_buildVersion)' : _baseVersion;

  static const String developerName = 'lNyctophilia';
}
