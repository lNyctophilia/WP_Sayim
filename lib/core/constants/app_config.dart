/// Uygulama konfigürasyonu — versiyon .bat ile buradan güncellenir
class AppConfig {
  AppConfig._();

  static const String _buildVersion = String.fromEnvironment('BUILD_VERSION');
  
  static String get version {
    if (_buildVersion.isNotEmpty) {
      String displayVersion = _buildVersion;
      // Harfleri, Türkçe karakterleri ve alt tireleri temizle, sadece sayı, nokta, tire ve iki nokta kalsın
      displayVersion = displayVersion.replaceAll(RegExp(r'[^\d\.\-:]'), '');
      // Eğer başta veya sonda fazladan tire kaldıysa onları da temizle
      displayVersion = displayVersion.replaceAll(RegExp(r'^\-+|\-+$'), '');
      
      var parts = displayVersion.split(':');
      if (parts.length >= 2) {
        displayVersion = '${parts[0]}:${parts[1]}';
      }
      return '($displayVersion)';
    }
    return 'Geliştirici Sürümü'; // Local ortamda çalışırken görünecek metin
  }

  static const String developerName = 'lNyctophilia';
  
  // YouTube video links
  static const String settingsVideoUrl = '';
  static const String installVideoUrl = '';
}
