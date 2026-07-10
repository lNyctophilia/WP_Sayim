import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_data.dart';
import '../models/work_day.dart';

/// İş günü verileri için repository — Firestore üzerinden çalışır
class WorkDayRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  WorkDayRepository({required this.userId});

  /// Bir ayın verilerini Firestore'dan getirir
  Future<MonthlyData> getMonthlyData(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final snapshot = await _firestore
        .collection('personel_takvimi')
        .doc(userId)
        .collection('gunler')
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .get();

    final days = snapshot.docs.map((doc) => WorkDay.fromJson(doc.data())).toList();
    return MonthlyData(year: year, month: month, workDays: days);
  }

  /// İş günü kaydet (yeni veya güncelle)
  Future<void> saveWorkDay(WorkDay workDay) async {
    // Sadece tarihi (YYYY-MM-DD) ID olarak kullanıyoruz ki her gün için tek kayıt olsun
    final dateString = "${workDay.date.year}-${workDay.date.month.toString().padLeft(2, '0')}-${workDay.date.day.toString().padLeft(2, '0')}";
    await _firestore
        .collection('personel_takvimi')
        .doc(userId)
        .collection('gunler')
        .doc(dateString)
        .set(workDay.toJson(), SetOptions(merge: true));
  }

  /// İş günü sil (Eğer yönetici daveti iptal ederse kullanılabilir)
  Future<void> deleteWorkDay(DateTime date) async {
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    await _firestore
        .collection('personel_takvimi')
        .doc(userId)
        .collection('gunler')
        .doc(dateString)
        .delete();
  }
}
