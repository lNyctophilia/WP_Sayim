import 'work_day.dart';

/// Bir ayın tüm iş günü verisi + hesaplamalar
class MonthlyData {
  final int year;
  final int month;
  final List<WorkDay> workDays;

  MonthlyData({
    required this.year,
    required this.month,
    required List<WorkDay> workDays,
  }) : workDays = _deduplicate(workDays);

  static List<WorkDay> _deduplicate(List<WorkDay> days) {
    final Map<String, WorkDay> map = {};
    final List<WorkDay> noIdDays = [];
    
    for (var day in days) {
      if (day.sayimId != null && day.sayimId!.isNotEmpty) {
        // Aynı sayimId'ye sahip kayıt varsa üzerine yazar (çiftleri teke indirir)
        map[day.sayimId!] = day;
      } else {
        noIdDays.add(day);
      }
    }
    
    return [...map.values, ...noIdDays];
  }

  int get totalDays => workDays.length;

  double get totalEarnings =>
      workDays.fold(0.0, (sum, day) => sum + day.payment);

  /// Belirli bir günde olan tüm işleri döner
  List<WorkDay> getWorkDaysForDay(int day) {
    return workDays.where((wd) => wd.date.day == day).toList();
  }

  /// Geriye uyumluluk veya tek bir iş beklendiğinde ilkini döner
  WorkDay? getWorkDay(int day) {
    try {
      return workDays.firstWhere(
        (wd) => wd.date.day == day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Boş ay
  static MonthlyData empty(int year, int month) {
    return MonthlyData(year: year, month: month, workDays: []);
  }
}
