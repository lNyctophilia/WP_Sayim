import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcı rolleri
enum UserRole { owner, manager, staff }

/// Firestore `users/{userId}` koleksiyonuna karşılık gelen model
class AppUser {
  final String id;
  final String username;
  final String fullName;
  final List<UserRole> roles;
  final double? defaultWage;
  final String? createdBy;
  final bool active;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.roles,
    this.defaultWage,
    this.createdBy,
    this.active = true,
    required this.createdAt,
  });

  /// En yüksek yetki seviyesi
  bool get isOwner => roles.contains(UserRole.owner);
  bool get isManager => roles.contains(UserRole.manager) || isOwner;
  bool get isStaff => roles.contains(UserRole.staff);

  /// Firestore'dan oku
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      username: data['username'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      roles: (data['roles'] as List<dynamic>?)
              ?.map((r) => UserRole.values.firstWhere(
                    (e) => e.name == r,
                    orElse: () => UserRole.staff,
                  ))
              .toList() ??
          [UserRole.staff],
      defaultWage: (data['defaultWage'] as num?)?.toDouble(),
      createdBy: data['createdBy'] as String?,
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore'a yaz
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'fullName': fullName,
      'roles': roles.map((r) => r.name).toList(),
      'defaultWage': defaultWage,
      'createdBy': createdBy,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? id,
    String? username,
    String? fullName,
    List<UserRole>? roles,
    double? defaultWage,
    String? createdBy,
    bool? active,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      roles: roles ?? this.roles,
      defaultWage: defaultWage ?? this.defaultWage,
      createdBy: createdBy ?? this.createdBy,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
