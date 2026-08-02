/// Uygulama konfigürasyonu — versiyon .bat ile buradan güncellenir
class AppConfig {
  AppConfig._();

  static const String _buildVersion = String.fromEnvironment('BUILD_VERSION');
  
  static String get version {
    if (_buildVersion.isNotEmpty) {
      String displayVersion = _buildVersion;
      // Temizle: sayı, nokta, tire ve iki nokta kalacak. 
      // Windows %time% boşluk içeriyorsa (_) temizlenecek.
      displayVersion = displayVersion.replaceAll(RegExp(r'[^\d\.\-:]'), '');
      displayVersion = displayVersion.replaceAll(RegExp(r'^\-+|\-+$'), '');
      
      var dateAndTime = displayVersion.split('-');
      if (dateAndTime.length >= 2) {
        var datePart = dateAndTime[0];
        var timePart = dateAndTime.sublist(1).join('-'); // '-' icerebilecek olası diger kisimlar
        
        var timeParts = timePart.split(':');
        if (timeParts.length >= 2) {
          var hour = timeParts[0].padLeft(2, '0');
          var minute = timeParts[1];
          displayVersion = '$datePart-$hour.$minute';
        }
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
