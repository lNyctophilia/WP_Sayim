import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sayim.dart';
import '../models/davet.dart';

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

  /// Belirli bir sayımın anlık değişikliklerini dinler
  Stream<Sayim?> getSayimStream(String sayimId) {
    return _firestore
        .collection('sayimlar')
        .doc(sayimId)
        .snapshots()
        .map((doc) => doc.exists ? Sayim.fromFirestore(doc) : null);
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

  /// Geçmiş bir sayımı oluşturur, tüm seçili kişileri 'accepted' olarak davet eder ve
  /// iş takvimlerine ekler. Hiçbir bildirim gitmez (isPast = true).
  Future<void> createPastSayimFull(Sayim sayim, List<Davet> davetler) async {
    final batch = _firestore.batch();
    
    // 1. Sayımı oluştur
    final sayimRef = _firestore.collection('sayimlar').doc();
    final newSayim = sayim.copyWith(id: sayimRef.id);
    batch.set(sayimRef, newSayim.toFirestore());

    // 2. Davetleri oluştur ve takvime ekle
    for (var davet in davetler) {
      final davetRef = _firestore.collection('davetler').doc();
      final newDavet = davet.copyWith(id: davetRef.id, sayimId: sayimRef.id);
      batch.set(davetRef, newDavet.toFirestore());

      // Takvime ekle (WorkDay)
      final grup = newSayim.gruplar.firstWhere(
        (g) => g.grupId == newDavet.grupId,
        orElse: () => const SayimGrup(grupId: 1, saat: ''),
      );
      final combinedNote = '${newSayim.note} ${grup.saat}'.trim();
      
      final dateString = "${newSayim.date.year}-${newSayim.date.month.toString().padLeft(2, '0')}-${newSayim.date.day.toString().padLeft(2, '0')}";
      final workDayRef = _firestore
          .collection('personel_takvimi')
          .doc(newDavet.userId)
          .collection('gunler')
          .doc(dateString);

      final workDay = {
        'date': newSayim.date.toIso8601String(),
        'isCityCenter': newSayim.sehirTipi == SehirTipi.ici,
        'payment': newDavet.ucret,
        'note': combinedNote,
        'sayimId': newSayim.id,
      };

      batch.set(workDayRef, workDay, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Var olan sayımı günceller ve bağlı davetleri/takvim kayıtlarını senkronize eder
  Future<void> updateSayim(Sayim sayim) async {
    final oldSayimDoc = await _firestore.collection('sayimlar').doc(sayim.id).get();
    if (!oldSayimDoc.exists) return;
    
    final oldSayim = Sayim.fromFirestore(oldSayimDoc);
    final batch = _firestore.batch();
    
    // 1. Sayımı güncelle
    batch.update(_firestore.collection('sayimlar').doc(sayim.id), sayim.toFirestore());

    // 2. Davetleri bul
    final davetlerQuery = await _firestore
        .collection('davetler')
        .where('sayimId', isEqualTo: sayim.id)
        .get();

    for (var davetDoc in davetlerQuery.docs) {
      final davetData = davetDoc.data();
      
      // Şehir tipi değiştiyse daveti güncelle
      if (oldSayim.sehirTipi != sayim.sehirTipi) {
        batch.update(davetDoc.reference, {'sehirIciDisi': sayim.sehirTipi.name});
      }

      // Kabul edildiyse takvimleri senkronize et
      if (davetData['status'] == 'accepted') {
        final userId = davetData['userId'] as String;
        final grupId = davetData['grupId'] as int;
        final ucret = (davetData['ucret'] as num).toDouble();
        
        final grup = sayim.gruplar.firstWhere(
          (g) => g.grupId == grupId,
          orElse: () => const SayimGrup(grupId: 1, saat: ''),
        );
        final combinedNote = '${sayim.note} ${grup.saat}'.trim();

        final oldDateString = "${oldSayim.date.year}-${oldSayim.date.month.toString().padLeft(2, '0')}-${oldSayim.date.day.toString().padLeft(2, '0')}";
        final newDateString = "${sayim.date.year}-${sayim.date.month.toString().padLeft(2, '0')}-${sayim.date.day.toString().padLeft(2, '0')}";

        final oldWorkDayRef = _firestore
            .collection('personel_takvimi')
            .doc(userId)
            .collection('gunler')
            .doc(oldDateString);
            
        final newWorkDayRef = _firestore
            .collection('personel_takvimi')
            .doc(userId)
            .collection('gunler')
            .doc(newDateString);

        if (oldDateString != newDateString) {
          batch.delete(oldWorkDayRef);
        }

        final workDay = {
          'date': sayim.date.toIso8601String(),
          'isCityCenter': sayim.sehirTipi == SehirTipi.ici,
          'payment': ucret,
          'note': combinedNote,
          'sayimId': sayim.id,
        };

        batch.set(newWorkDayRef, workDay, SetOptions(merge: true));
      }
    }

    await batch.commit();
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

  /// Belirli bir tarihteki sayımlara davet edilmiş kullanıcıların ID'lerini getirir
  /// [excludeSayimId] verilirse o sayımı hesaba katmaz (örn. düzenleme ekranı için).
  Future<List<String>> getBusyUsersOnDate(DateTime date, {String? excludeSayimId}) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = await _firestore
        .collection('sayimlar')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final Set<String> busyUsers = {};
    for (var doc in query.docs) {
      if (excludeSayimId != null && doc.id == excludeSayimId) continue;
      
      final sayim = Sayim.fromFirestore(doc);
      if (sayim.status != SayimStatus.closed) {
        busyUsers.addAll(sayim.invitedUserIds);
      }
    }
    return busyUsers.toList();
  }
}
