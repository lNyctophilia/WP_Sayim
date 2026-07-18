import 'package:cloud_firestore/cloud_firestore.dart';

/// Davet durumu
enum DavetStatus { pending, accepted, declined }

/// Davet edilen kişinin bu sayımdaki rolü
enum DavetRole { manager, staff }

/// Şehir içi / dışı
enum SehirTipi { ici, disi }

/// Firestore `davetler/{davetId}` koleksiyonuna karşılık gelen model
class Davet {
  final String id;
  final String sayimId;
  final String userId;
  final DavetStatus status;
  final DavetRole role;
  final int grupId;
  final SehirTipi sehirIciDisi;
  final double ucret;
  final double multiplier;
  final bool isPast;
  final DateTime? respondedAt;
  final DateTime? lastReminderAt;
  final DateTime createdAt;

  const Davet({
    required this.id,
    required this.sayimId,
    required this.userId,
    this.status = DavetStatus.pending,
    this.role = DavetRole.staff,
    this.grupId = 1,
    this.sehirIciDisi = SehirTipi.ici,
    required this.ucret,
    this.multiplier = 1.0,
    this.isPast = false,
    this.respondedAt,
    this.lastReminderAt,
    required this.createdAt,
  });

  bool get isPending => status == DavetStatus.pending;
  bool get isAccepted => status == DavetStatus.accepted;
  bool get isDeclined => status == DavetStatus.declined;

  /// Firestore'dan oku
  factory Davet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Davet(
      id: doc.id,
      sayimId: data['sayimId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      status: DavetStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => DavetStatus.pending,
      ),
      role: DavetRole.values.firstWhere(
        (e) => e.name == (data['role'] as String? ?? 'staff'),
        orElse: () => DavetRole.staff,
      ),
      grupId: data['grupId'] as int? ?? 1,
      sehirIciDisi: SehirTipi.values.firstWhere(
        (e) => e.name == (data['sehirIciDisi'] as String? ?? 'ici'),
        orElse: () => SehirTipi.ici,
      ),
      ucret: (data['ucret'] as num?)?.toDouble() ?? 0.0,
      multiplier: (data['multiplier'] as num?)?.toDouble() ?? 1.0,
      isPast: data['isPast'] as bool? ?? false,
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      lastReminderAt: (data['lastReminderAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore'a yaz
  Map<String, dynamic> toFirestore() {
    return {
      'sayimId': sayimId,
      'userId': userId,
      'status': status.name,
      'role': role.name,
      'grupId': grupId,
      'sehirIciDisi': sehirIciDisi.name,
      'ucret': ucret,
      'multiplier': multiplier,
      'isPast': isPast,
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'lastReminderAt':
          lastReminderAt != null ? Timestamp.fromDate(lastReminderAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Davet copyWith({
    String? id,
    String? sayimId,
    String? userId,
    DavetStatus? status,
    DavetRole? role,
    int? grupId,
    SehirTipi? sehirIciDisi,
    double? ucret,
    double? multiplier,
    bool? isPast,
    DateTime? respondedAt,
    DateTime? lastReminderAt,
    DateTime? createdAt,
  }) {
    return Davet(
      id: id ?? this.id,
      sayimId: sayimId ?? this.sayimId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      role: role ?? this.role,
      grupId: grupId ?? this.grupId,
      sehirIciDisi: sehirIciDisi ?? this.sehirIciDisi,
      ucret: ucret ?? this.ucret,
      multiplier: multiplier ?? this.multiplier,
      isPast: isPast ?? this.isPast,
      respondedAt: respondedAt ?? this.respondedAt,
      lastReminderAt: lastReminderAt ?? this.lastReminderAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
