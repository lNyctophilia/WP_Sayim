import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `personel_takvimi/{userId}/gunler/{tarih}` koleksiyonuna karşılık gelen model
///
/// Mevcut WorkDay modelinin Firestore versiyonu — aynı veriler ama artık
/// veriyi kullanıcı kendisi değil, yönetici davet üzerinden dolduruyor.
class TakvimGirisi {
  final String id; // tarih formatında: "2026-07-10"
  final String sehirIciDisi; // "ici" veya "disi"
  final double ucret;
  final String not;
  final String? sayimId; // Hangi sayımdan geldiğinin referansı

  const TakvimGirisi({
    required this.id,
    required this.sehirIciDisi,
    required this.ucret,
    this.not = '',
    this.sayimId,
  });

  bool get isCityCenter => sehirIciDisi == 'ici';

  /// Firestore'dan oku
  factory TakvimGirisi.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TakvimGirisi(
      id: doc.id,
      sehirIciDisi: data['sehirIciDisi'] as String? ?? 'ici',
      ucret: (data['ucret'] as num?)?.toDouble() ?? 0.0,
      not: data['not'] as String? ?? '',
      sayimId: data['sayimId'] as String?,
    );
  }

  /// Firestore'a yaz
  Map<String, dynamic> toFirestore() {
    return {
      'sehirIciDisi': sehirIciDisi,
      'ucret': ucret,
      'not': not,
      'sayimId': sayimId,
    };
  }

  /// Mevcut WorkDay modeline dönüştür (geriye dönük uyumluluk)
  /// Takvim UI'ı şu an WorkDay kullanıyor — geçiş döneminde bu metod lazım olacak
  TakvimGirisi copyWith({
    String? id,
    String? sehirIciDisi,
    double? ucret,
    String? not,
    String? sayimId,
  }) {
    return TakvimGirisi(
      id: id ?? this.id,
      sehirIciDisi: sehirIciDisi ?? this.sehirIciDisi,
      ucret: ucret ?? this.ucret,
      not: not ?? this.not,
      sayimId: sayimId ?? this.sayimId,
    );
  }
}
