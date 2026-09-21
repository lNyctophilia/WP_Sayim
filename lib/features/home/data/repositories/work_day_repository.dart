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
    final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
    
    int nextYear = year;
    int nextMonth = month + 1;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    final endStr = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';

    final snapshot = await _firestore
        .collection('personel_takvimi')
        .doc(userId)
        .collection('gunler')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
        .where(FieldPath.documentId, isLessThan: endStr)
        .get();

    final days = snapshot.docs.map((doc) => WorkDay.fromJson(doc.data())).toList();
    return MonthlyData(year: year, month: month, workDays: days);
  }

  /// Bir ayın verilerini Firestore'dan stream olarak getirir
  Stream<MonthlyData> getMonthlyDataStream(int year, int month) {
    final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
    
    int nextYear = year;
    int nextMonth = month + 1;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    final endStr = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';

    return _firestore
        .collection('personel_takvimi')
        .doc(userId)
        .collection('gunler')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
        .where(FieldPath.documentId, isLessThan: endStr)
        .snapshots()
        .map((snapshot) {
      final days = snapshot.docs.map((doc) => WorkDay.fromJson(doc.data())).toList();
      return MonthlyData(year: year, month: month, workDays: days);
    });
  }

  /// Kullanıcının en son çalıştığı (kayıtlı) iş gününü getirir
  Future<WorkDay?> getLatestWorkDay() async {
    final snapshot = await _firestore
        .collection('personel_takvimi')
        .doc(userId)
        .collection('gunler')
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return WorkDay.fromJson(snapshot.docs.first.data());
  }

  /// İş günü kaydet (yeni veya güncelle)
  Future<void> saveWorkDay(WorkDay workDay) async {
    final dateString = "${workDay.date.year}-${workDay.date.month.toString().padLeft(2, '0')}-${workDay.date.day.toString().padLeft(2, '0')}";
    final docId = workDay.sayimId != null ? "${dateString}_${workDay.sayimId}" : dateString;
    await _firestore
        .collection('personel_takvimi')
        .doc(userId)
        .collection('gunler')
        .doc(docId)
        .set(workDay.toJson(), SetOptions(merge: true));
  }

  /// İş günü sil (Eğer yönetici daveti iptal ederse kullanılabilir)
  Future<void> deleteWorkDay(DateTime date, {String? sayimId}) async {
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final docId = sayimId != null ? "${dateString}_$sayimId" : dateString;
    await _firestore
        .collection('personel_takvimi')
        .doc(userId)
        .collection('gunler')
        .doc(docId)
        .delete();
  }
}
