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
  final bool isDeleted;
  final DateTime createdAt;
  final String? sessionId;
  final bool sayimReminderEnabled;
  final String? phone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isApproved;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.password,
    required this.roles,
    this.defaultWage,
    this.createdBy,
    this.active = true,
    this.isDeleted = false,
    required this.createdAt,
    this.sessionId,
    this.sayimReminderEnabled = true,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    this.isApproved = false,
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
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessionId: data['sessionId'] as String?,
      sayimReminderEnabled: data['sayimReminderEnabled'] as bool? ?? true,
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      isApproved: data['isApproved'] as bool? ?? false,
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
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      if (sessionId != null) 'sessionId': sessionId,
      'sayimReminderEnabled': sayimReminderEnabled,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'isApproved': isApproved,
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
    bool? isDeleted,
    DateTime? createdAt,
    String? sessionId,
    bool? sayimReminderEnabled,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    bool? isApproved,
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
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      sessionId: sessionId ?? this.sessionId,
      sayimReminderEnabled: sayimReminderEnabled ?? this.sayimReminderEnabled,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
