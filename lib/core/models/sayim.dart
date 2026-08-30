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
  final String firmaAdi;
  final String toplanmaYeri;
  final DateTime date;
  final int maxKisi;
  final int maxYonetici;
  final String createdBy;
  final SayimStatus status;
  final List<SayimGrup> gruplar;
  final List<String> invitedUserIds;
  final SehirTipi sehirTipi;
  final double globalMultiplier;
  final bool isPast;
  final bool isManualStatus;
  final DateTime createdAt;
  final String? startTime;
  final String city;

  Sayim({
    required this.id,
    required this.note,
    this.firmaAdi = '',
    this.toplanmaYeri = '',
    required this.date,
    this.maxKisi = 20,
    this.maxYonetici = 2,
    required this.createdBy,
    this.status = SayimStatus.open,
    this.gruplar = const [],
    this.invitedUserIds = const [],
    this.sehirTipi = SehirTipi.ici,
    this.globalMultiplier = 1.0,
    this.isPast = false,
    this.isManualStatus = false,
    required this.createdAt,
    this.startTime,
    this.city = 'Denizli',
  });

  Sayim copyWith({
    String? id,
    String? note,
    String? firmaAdi,
    String? toplanmaYeri,
    DateTime? date,
    int? maxKisi,
    int? maxYonetici,
    String? createdBy,
    SayimStatus? status,
    List<SayimGrup>? gruplar,
    List<String>? invitedUserIds,
    SehirTipi? sehirTipi,
    double? globalMultiplier,
    bool? isPast,
    bool? isManualStatus,
    DateTime? createdAt,
    String? startTime,
    String? city,
  }) {
    return Sayim(
      id: id ?? this.id,
      note: note ?? this.note,
      firmaAdi: firmaAdi ?? this.firmaAdi,
      toplanmaYeri: toplanmaYeri ?? this.toplanmaYeri,
      date: date ?? this.date,
      maxKisi: maxKisi ?? this.maxKisi,
      maxYonetici: maxYonetici ?? this.maxYonetici,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      gruplar: gruplar ?? this.gruplar,
      invitedUserIds: invitedUserIds ?? this.invitedUserIds,
      sehirTipi: sehirTipi ?? this.sehirTipi,
      globalMultiplier: globalMultiplier ?? this.globalMultiplier,
      isPast: isPast ?? this.isPast,
      isManualStatus: isManualStatus ?? this.isManualStatus,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      city: city ?? this.city,
    );
  }

  /// Firestore'dan oku
  factory Sayim.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sayim(
      id: doc.id,
      note: data['note'] as String? ?? '',
      firmaAdi: data['firmaAdi'] as String? ?? '',
      toplanmaYeri: data['toplanmaYeri'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxKisi: data['maxKisi'] as int? ?? 20,
      maxYonetici: data['maxYonetici'] as int? ?? 2,
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
      isPast: data['isPast'] as bool? ?? false,
      isManualStatus: data['isManualStatus'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: data['startTime'] as String?,
      city: data['city'] as String? ?? 'Denizli',
    );
  }

  late final DateTime _endDateTime = _calculateEndDateTime();

  DateTime _calculateEndDateTime() {
    if (startTime != null && startTime!.isNotEmpty) {
      try {
        final parts = startTime!.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        return DateTime(date.year, date.month, date.day, hour, minute);
      } catch (e) {
        // Fallback to groups if parse fails
      }
    }

    if (gruplar.isEmpty) {
      return DateTime(date.year, date.month, date.day, 23, 59, 59);
    }
    
    String latestTime = "00:00";
    for (var g in gruplar) {
      if (g.saat.isNotEmpty && g.saat.compareTo(latestTime) > 0) {
        latestTime = g.saat;
      }
    }
    
    try {
      final parts = latestTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return DateTime(date.year, date.month, date.day, 23, 59, 59);
    }
  }

  bool get isSayimInPast => _endDateTime.isBefore(DateTime.now());

  SayimStatus get effectiveStatus {
    if (isManualStatus) return status;
    if (isSayimInPast) return SayimStatus.closed;
    return status;
  }

  bool get isClosed => effectiveStatus == SayimStatus.closed;

  /// Firestore'a yaz
  Map<String, dynamic> toFirestore() {
    return {
      'note': note,
      'firmaAdi': firmaAdi,
      'toplanmaYeri': toplanmaYeri,
      'date': Timestamp.fromDate(date),
      'maxKisi': maxKisi,
      'maxYonetici': maxYonetici,
      'createdBy': createdBy,
      'status': status.name,
      'gruplar': gruplar.map((g) => g.toMap()).toList(),
      'invitedUserIds': invitedUserIds,
      'sehirTipi': sehirTipi.name,
      'globalMultiplier': globalMultiplier,
      'isPast': isPast,
      'isManualStatus': isManualStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'startTime': startTime,
      'city': city,
    };
  }


}
