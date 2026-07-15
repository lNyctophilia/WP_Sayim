import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcı rolleri
enum UserRole { owner, manager, staff }

/// Firestore `users/{userId}` koleksiyonuna karşılık gelen model
class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String? password;
  final List<UserRole> roles;
  final double? defaultWage;
  final String? createdBy;
  final bool active;
  final DateTime createdAt;
  final String? sessionId;
  final bool sayimReminderEnabled;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.password,
    required this.roles,
    this.defaultWage,
    this.createdBy,
    this.active = true,
    required this.createdAt,
    this.sessionId,
    this.sayimReminderEnabled = true,
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
      password: data['password'] as String?,
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
      sessionId: data['sessionId'] as String?,
      sayimReminderEnabled: data['sayimReminderEnabled'] as bool? ?? true,
    );
  }

  /// Firestore'a yaz
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'fullName': fullName,
      if (password != null) 'password': password,
      'roles': roles.map((r) => r.name).toList(),
      'defaultWage': defaultWage,
      'createdBy': createdBy,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      if (sessionId != null) 'sessionId': sessionId,
      'sayimReminderEnabled': sayimReminderEnabled,
    };
  }

  AppUser copyWith({
    String? id,
    String? username,
    String? fullName,
    String? password,
    List<UserRole>? roles,
    double? defaultWage,
    String? createdBy,
    bool? active,
    DateTime? createdAt,
    String? sessionId,
    bool? sayimReminderEnabled,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      roles: roles ?? this.roles,
      defaultWage: defaultWage ?? this.defaultWage,
      createdBy: createdBy ?? this.createdBy,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      sessionId: sessionId ?? this.sessionId,
      sayimReminderEnabled: sayimReminderEnabled ?? this.sayimReminderEnabled,
    );
  }
}
