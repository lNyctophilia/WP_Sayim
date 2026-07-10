import 'package:cloud_firestore/cloud_firestore.dart';
import 'davet.dart';

/// Sayım durumu
enum SayimStatus { open, closed }

/// Bir saat grubu (max 3 grup)
class SayimGrup {
  final int grupId;
  final String saat;

  const SayimGrup({
    required this.grupId,
    required this.saat,
  });

  factory SayimGrup.fromMap(Map<String, dynamic> map) {
    return SayimGrup(
      grupId: map['grupId'] as int,
      saat: map['saat'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'grupId': grupId,
      'saat': saat,
    };
  }
}

/// Firestore `sayimlar/{sayimId}` koleksiyonuna karşılık gelen model
class Sayim {
  final String id;
  final String note;
  final DateTime date;
  final int maxKisi;
  final String createdBy;
  final SayimStatus status;
  final List<SayimGrup> gruplar;
  final List<String> invitedUserIds;
  final SehirTipi sehirTipi;
  final double globalMultiplier;
  final DateTime createdAt;

  const Sayim({
    required this.id,
    required this.note,
    required this.date,
    this.maxKisi = 20,
    required this.createdBy,
    this.status = SayimStatus.open,
    this.gruplar = const [],
    this.invitedUserIds = const [],
    this.sehirTipi = SehirTipi.ici,
    this.globalMultiplier = 1.0,
    required this.createdAt,
  });

  Sayim copyWith({
    String? id,
    String? note,
    DateTime? date,
    int? maxKisi,
    String? createdBy,
    SayimStatus? status,
    List<SayimGrup>? gruplar,
    List<String>? invitedUserIds,
    SehirTipi? sehirTipi,
    double? globalMultiplier,
    DateTime? createdAt,
  }) {
    return Sayim(
      id: id ?? this.id,
      note: note ?? this.note,
      date: date ?? this.date,
      maxKisi: maxKisi ?? this.maxKisi,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      gruplar: gruplar ?? this.gruplar,
      invitedUserIds: invitedUserIds ?? this.invitedUserIds,
      sehirTipi: sehirTipi ?? this.sehirTipi,
      globalMultiplier: globalMultiplier ?? this.globalMultiplier,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Firestore'dan oku
  factory Sayim.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sayim(
      id: doc.id,
      note: data['note'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxKisi: data['maxKisi'] as int? ?? 20,
      createdBy: data['createdBy'] as String? ?? '',
      status: SayimStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'open'),
        orElse: () => SayimStatus.open,
      ),
      gruplar: (data['gruplar'] as List<dynamic>?)
              ?.map((g) => SayimGrup.fromMap(g as Map<String, dynamic>))
              .toList() ??
          [],
      invitedUserIds: (data['invitedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sehirTipi: SehirTipi.values.firstWhere(
        (e) => e.name == (data['sehirTipi'] as String? ?? 'ici'),
        orElse: () => SehirTipi.ici,
      ),
      globalMultiplier: (data['globalMultiplier'] as num?)?.toDouble() ?? 1.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore'a yaz
  Map<String, dynamic> toFirestore() {
    return {
      'note': note,
      'date': Timestamp.fromDate(date),
      'maxKisi': maxKisi,
      'createdBy': createdBy,
      'status': status.name,
      'gruplar': gruplar.map((g) => g.toMap()).toList(),
      'invitedUserIds': invitedUserIds,
      'sehirTipi': sehirTipi.name,
      'globalMultiplier': globalMultiplier,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }


}
