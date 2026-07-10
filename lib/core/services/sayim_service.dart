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
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Sayim.fromFirestore(doc)).toList();
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

  /// Sayımı siler
  Future<void> deleteSayim(String sayimId) async {
    await _firestore.collection('sayimlar').doc(sayimId).delete();
  }
}
