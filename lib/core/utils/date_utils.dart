/// Tarih yardımcı fonksiyonları
class AppDateUtils {
  AppDateUtils._();

  /// Bir ayın gün sayısı
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Ayın ilk gününün haftanın kaçıncı günü olduğu
  /// Pazartesi = 0, Pazar = 6 (takvim grid'i için)
  static int firstWeekdayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday - 1; // DateTime.monday = 1
  }

  /// Takvim grid'inde gösterilecek toplam satır sayısı
  static int gridRowCount(int year, int month) {
    final firstDay = firstWeekdayOfMonth(year, month);
    final totalDays = daysInMonth(year, month);
    return ((firstDay + totalDays) / 7).ceil();
  }

  /// İki tarih aynı gün mü?
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Bugün mü?
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Tarih ile saat dizesini ("18:00") birleştirerek tam DateTime oluşturur
  static DateTime combineDateAndTime(DateTime date, String? timeStr) {
    if (timeStr != null && timeStr.trim().isNotEmpty) {
      try {
        final parts = timeStr.trim().split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(date.year, date.month, date.day, hour, minute);
      } catch (_) {}
    }
    return DateTime(date.year, date.month, date.day, 0, 0);
  }

  /// Şehir dışı konum görünürlük kontrolü:
  /// Şehir içiyse her zaman true, şehir dışıysa sayım başlangıç saati geçmişse true
  static bool canViewSayimLocation({
    required bool isCityCenter,
    required DateTime date,
    String? startTime,
  }) {
    if (isCityCenter) return true;
    final startDateTime = combineDateAndTime(date, startTime);
    final now = DateTime.now();
    return now.isAfter(startDateTime) || now.isAtSameMomentAs(startDateTime);
  }
}
