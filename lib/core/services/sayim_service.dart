import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sayim.dart';

class SayimService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tüm sayımları getirir (tarihe göre azalan sırada)
  Stream<List<Sayim>> getSayimlar() {
    return _firestore
        .collection('sayimlar')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Sayim.fromFirestore(doc)).toList();
    });
  }

  /// Sadece belirli bir kullanıcının oluşturduğu sayımları getirir
  Stream<List<Sayim>> getSayimlarByCreator(String creatorId) {
    return _firestore
        .collection('sayimlar')
        .where('createdBy', isEqualTo: creatorId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Sayim.fromFirestore(doc)).toList();
      list.sort((a, b) => b.date.compareTo(a.date)); // Sort in Dart to avoid index
      return list;
    });
  }

  /// Yeni bir sayım oluşturur ve ID'sini döner
  Future<String> createSayim(Sayim sayim) async {
    final docRef = await _firestore.collection('sayimlar').add(sayim.toFirestore());
    return docRef.id;
  }

  /// Var olan sayımı günceller
  Future<void> updateSayim(Sayim sayim) async {
    await _firestore.collection('sayimlar').doc(sayim.id).update(sayim.toFirestore());
  }

  /// Sayımı kapatır
  Future<void> closeSayim(String sayimId) async {
    await _firestore.collection('sayimlar').doc(sayimId).update({
      'status': SayimStatus.closed.name,
    });
  }

  /// Sayımı, ona bağlı davetleri ve kabul edilen takvim kayıtlarını tamamen siler
  Future<void> deleteSayimFull(String sayimId) async {
    final sayimDoc = await _firestore.collection('sayimlar').doc(sayimId).get();
    if (!sayimDoc.exists) return;
    
    final sayim = Sayim.fromFirestore(sayimDoc);

    final davetlerQuery = await _firestore
        .collection('davetler')
        .where('sayimId', isEqualTo: sayimId)
        .get();

    final batch = _firestore.batch();
    
    // Davetleri ve takvimleri sil
    for (var davetDoc in davetlerQuery.docs) {
      batch.delete(davetDoc.reference);
      
      final status = davetDoc.data()['status'] as String?;
      if (status == 'accepted') {
        final userId = davetDoc.data()['userId'] as String;
        final dateString = "${sayim.date.year}-${sayim.date.month.toString().padLeft(2, '0')}-${sayim.date.day.toString().padLeft(2, '0')}";
        final workDayRef = _firestore
            .collection('personel_takvimi')
            .doc(userId)
            .collection('gunler')
            .doc(dateString);
        batch.delete(workDayRef);
      }
    }

    // Sayımı sil
    batch.delete(sayimDoc.reference);

    await batch.commit();
  }
}
