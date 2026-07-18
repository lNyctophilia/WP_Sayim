import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/davet.dart';
import '../models/sayim.dart';
import '../../features/home/data/models/work_day.dart';

class DavetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Belirli bir sayıma ait davetleri getir
  Stream<List<Davet>> getDavetlerBySayim(String sayimId) {
    return _firestore
        .collection('davetler')
        .where('sayimId', isEqualTo: sayimId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Davet.fromFirestore(doc)).toList();
    });
  }

  /// Belirli bir sayıma ait davetleri getir (Future)
  Future<List<Davet>> getDavetlerBySayimFuture(String sayimId) async {
    final snapshot = await _firestore
        .collection('davetler')
        .where('sayimId', isEqualTo: sayimId)
        .get();
    return snapshot.docs.map((doc) => Davet.fromFirestore(doc)).toList();
  }

  /// Belirli bir kullanıcıya ait (Personel/Yönetici) davetleri getir
  Stream<List<Davet>> getDavetlerByUser(String userId) {
    return _firestore
        .collection('davetler')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Davet.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Yeni bir davet oluşturur (Toplu oluşturma için de kullanılabilir)
  Future<String> createDavet(Davet davet) async {
    final docRef = await _firestore.collection('davetler').add(davet.toFirestore());
    return docRef.id;
  }

  /// Davet durumunu (Kabul/Red) günceller
  Future<void> updateDavetStatus(String davetId, DavetStatus status) async {
    await _firestore.collection('davetler').doc(davetId).update({
      'status': status.name,
      'respondedAt': Timestamp.now(),
    });
  }

  /// Hatırlatma bildirim tarihini günceller
  Future<void> updateLastReminder(String davetId) async {
    await _firestore.collection('davetler').doc(davetId).update({
      'lastReminderAt': Timestamp.now(),
    });
  }

  /// Daveti kabul et ve takvime işle
  Future<void> acceptDavet(String davetId) async {
    final doc = await _firestore.collection('davetler').doc(davetId).get();
    if (!doc.exists) return;
    final davet = Davet.fromFirestore(doc);

    // 1. Sayım detaylarını al (Tarih ve yer/not bilgisi için)
    final sayimDoc = await _firestore.collection('sayimlar').doc(davet.sayimId).get();
    if (!sayimDoc.exists) throw Exception('Sayım bulunamadı!');
    final sayim = Sayim.fromFirestore(sayimDoc);

    // 2. Grubun saatini bul
    final grup = sayim.gruplar.firstWhere(
      (g) => g.grupId == davet.grupId,
      orElse: () => const SayimGrup(grupId: 1, saat: ''),
    );
    final combinedNote = '${sayim.note} ${grup.saat}'.trim();

    // 3. WorkDay oluştur
    final workDay = WorkDay(
      date: sayim.date,
      isCityCenter: davet.sehirIciDisi == SehirTipi.ici,
      payment: davet.ucret,
      note: combinedNote,
      sayimId: sayim.id,
    );

    // 4. Batch işlemi (Hem daveti güncelle hem de takvime ekle)
    final batch = _firestore.batch();
    
    final davetRef = _firestore.collection('davetler').doc(davet.id);
    batch.update(davetRef, {
      'status': DavetStatus.accepted.name,
      'respondedAt': Timestamp.now(),
    });

    final dateString = "${workDay.date.year}-${workDay.date.month.toString().padLeft(2, '0')}-${workDay.date.day.toString().padLeft(2, '0')}";
    final workDayRef = _firestore
        .collection('personel_takvimi')
        .doc(davet.userId)
        .collection('gunler')
        .doc(dateString);
        
    batch.set(workDayRef, workDay.toJson(), SetOptions(merge: true));

    await batch.commit();
  }

  /// Daveti reddet
  Future<void> declineDavet(String davetId) async {
    await updateDavetStatus(davetId, DavetStatus.declined);
  }

  /// Daveti siler (Yönetici daveti iptal ederse) ve takvimden de kaldırır
  Future<void> deleteDavet(String davetId) async {
    final doc = await _firestore.collection('davetler').doc(davetId).get();
    if (!doc.exists) return;

    final davet = Davet.fromFirestore(doc);
    final batch = _firestore.batch();

    batch.delete(doc.reference);

    if (davet.status == DavetStatus.accepted) {
      final sayimDoc = await _firestore.collection('sayimlar').doc(davet.sayimId).get();
      if (sayimDoc.exists) {
        final sayim = Sayim.fromFirestore(sayimDoc);
        final dateString = "${sayim.date.year}-${sayim.date.month.toString().padLeft(2, '0')}-${sayim.date.day.toString().padLeft(2, '0')}";
        final workDayRef = _firestore
            .collection('personel_takvimi')
            .doc(davet.userId)
            .collection('gunler')
            .doc(dateString);
        batch.delete(workDayRef);
      }
    }

    await batch.commit();
  }

  /// Daveti reddedenden tekrar bekleme durumuna alır
  Future<void> resetDavet(String davetId) async {
    final doc = await _firestore.collection('davetler').doc(davetId).get();
    if (!doc.exists) return;
    await doc.reference.update({
      'status': DavetStatus.pending.name,
      'isAccepted': false,
      'isPending': true,
      'isDeclined': false,
    });
  }

  /// Davetin detaylarını günceller ve ücret değişirse takvime (WorkDay) yansıtır
  Future<void> updateDavetDetails(String davetId, double newUcret, int newGrupId, double newMultiplier) async {
    final doc = await _firestore.collection('davetler').doc(davetId).get();
    if (!doc.exists) return;

    final davet = Davet.fromFirestore(doc);
    final batch = _firestore.batch();

    batch.update(doc.reference, {
      'ucret': newUcret,
      'grupId': newGrupId,
      'multiplier': newMultiplier,
    });

    if (davet.status == DavetStatus.accepted && davet.ucret != newUcret) {
      final sayimDoc = await _firestore.collection('sayimlar').doc(davet.sayimId).get();
      if (sayimDoc.exists) {
        final sayim = Sayim.fromFirestore(sayimDoc);
        final dateString = "${sayim.date.year}-${sayim.date.month.toString().padLeft(2, '0')}-${sayim.date.day.toString().padLeft(2, '0')}";
        final workDayRef = _firestore
            .collection('personel_takvimi')
            .doc(davet.userId)
            .collection('gunler')
            .doc(dateString);
        batch.update(workDayRef, {'payment': newUcret});
      }
    }

    await batch.commit();
  }

  /// Reddedilmiş daveti tekrar bekleyen durumuna alır
  Future<void> reinviteDavet(String davetId) async {
    await _firestore.collection('davetler').doc(davetId).update({
      'status': DavetStatus.pending.name,
      'respondedAt': FieldValue.delete(),
      'lastReminderAt': Timestamp.now(),
    });
  }
}

