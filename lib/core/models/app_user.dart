import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcı rolleri
enum UserRole { owner, manager, managerA1, managerA2, managerA3, staff }

extension UserRoleExtension on UserRole {
  String get translationKey {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.manager:
        return 'manager';
      case UserRole.managerA1:
        return 'manager_a1';
      case UserRole.managerA2:
        return 'manager_a2';
      case UserRole.managerA3:
        return 'manager_a3';
      case UserRole.staff:
        return 'staff';
    }
  }
}

/// Kullanıcı yetkileri (rolden bağımsız erişim kontrolü)
/// - staff   : Sayıma eklenebilir, iş takvimi görünür, davet alabilir
/// - manager : Yönetici paneline erişim (sayım oluşturma, personel yönetimi vb.)
/// - admin   : Sistem araçlarına erişim (profil düzenleme, geçmiş sayım, ücret ayarları)
enum UserPermission { staff, manager, admin }

/// Firestore `users/{userId}` koleksiyonuna karşılık gelen model
class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String? password;
  final List<UserRole> roles;
  final List<UserPermission> permissions;
  final double? defaultWage;
  final String? createdBy;
  final bool active;
  final bool isDeleted;
  final DateTime? softDeletedAt;
  final DateTime createdAt;
  final String? sessionId;
  final bool sayimReminderEnabled;
  final String? phone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isApproved;
  final String? email;
  final String city;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.password,
    required this.roles,
    this.permissions = const [UserPermission.staff],
    this.defaultWage,
    this.createdBy,
    this.active = true,
    this.isDeleted = false,
    this.softDeletedAt,
    required this.createdAt,
    this.sessionId,
    this.sayimReminderEnabled = true,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    this.isApproved = false,
    this.email,
    this.city = 'Denizli',
  });

  /// Rol bazlı kontroller (maaş hesaplaması için)
  bool get isOwner => roles.contains(UserRole.owner);
  bool get isManager =>
      roles.contains(UserRole.manager) ||
      roles.contains(UserRole.managerA1) ||
      roles.contains(UserRole.managerA2) ||
      roles.contains(UserRole.managerA3) ||
      isOwner;
  bool get isStaff => roles.contains(UserRole.staff);

  /// Soft-delete edilmiş ama henüz hard-delete olmamış
  bool get isSoftDeleted => softDeletedAt != null && !isDeleted;

  /// Yetki kontrolleri (erişim kontrolü için kullanılır — rolden bağımsız)
  bool get hasStaffPermission => permissions.contains(UserPermission.staff);
  bool get hasManagerPermission => permissions.contains(UserPermission.manager);
  bool get hasAdminPermission => permissions.contains(UserPermission.admin);

  /// Firestore'dan oku
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // permissions alanı yoksa (eski kayıtlar) staff yetkisi ver
    final rawPerms = data['permissions'] as List<dynamic>?;
    final List<UserPermission> parsedPermissions;
    if (rawPerms != null) {
      parsedPermissions = rawPerms
          .map((p) => UserPermission.values.firstWhere(
                (e) => e.name == p,
                orElse: () => UserPermission.staff,
              ))
          .toList();
    } else {
      parsedPermissions = [UserPermission.staff];
    }

    return AppUser(
      id: doc.id,
      username: data['username'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      password: null, // Veritabanındaki eski şifreleri yok sayıyoruz
      roles: (data['roles'] as List<dynamic>?)
              ?.map((r) => UserRole.values.firstWhere(
                    (e) => e.name == r,
                    orElse: () => UserRole.staff,
                  ))
              .toList() ??
          [UserRole.staff],
      permissions: parsedPermissions,
      defaultWage: (data['defaultWage'] as num?)?.toDouble(),
      createdBy: data['createdBy'] as String?,
      active: data['active'] as bool? ?? true,
      isDeleted: data['isDeleted'] as bool? ?? false,
      softDeletedAt: (data['softDeletedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessionId: data['sessionId'] as String?,
      sayimReminderEnabled: data['sayimReminderEnabled'] as bool? ?? true,
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      isApproved: data['isApproved'] as bool? ?? true,
      email: data['email'] as String?,
      city: data['city'] as String? ?? 'Denizli',
    );
  }

  /// Firestore'a yaz
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'fullName': fullName,
      'roles': roles.map((r) => r.name).toList(),
      'permissions': permissions.map((p) => p.name).toList(),
      'defaultWage': defaultWage,
      'createdBy': createdBy,
      'active': active,
      'isDeleted': isDeleted,
      if (softDeletedAt != null) 'softDeletedAt': Timestamp.fromDate(softDeletedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      if (sessionId != null) 'sessionId': sessionId,
      'sayimReminderEnabled': sayimReminderEnabled,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'isApproved': isApproved,
      if (email != null) 'email': email,
      'city': city,
    };
  }

  AppUser copyWith({
    String? id,
    String? username,
    String? fullName,
    String? password,
    List<UserRole>? roles,
    List<UserPermission>? permissions,
    double? defaultWage,
    String? createdBy,
    bool? active,
    bool? isDeleted,
    DateTime? softDeletedAt,
    DateTime? createdAt,
    String? sessionId,
    bool? sayimReminderEnabled,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    bool? isApproved,
    String? email,
    String? city,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      defaultWage: defaultWage ?? this.defaultWage,
      createdBy: createdBy ?? this.createdBy,
      active: active ?? this.active,
      isDeleted: isDeleted ?? this.isDeleted,
      softDeletedAt: softDeletedAt ?? this.softDeletedAt,
      createdAt: createdAt ?? this.createdAt,
      sessionId: sessionId ?? this.sessionId,
      sayimReminderEnabled: sayimReminderEnabled ?? this.sayimReminderEnabled,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isApproved: isApproved ?? this.isApproved,
      email: email ?? this.email,
      city: city ?? this.city,
    );
  }
}
