class AppSettings {
  final double staffSehirIciWage;
  final double staffSehirDisiWage;
  final double managerA1SehirIciWage;
  final double managerA1SehirDisiWage;
  final double managerA2SehirIciWage;
  final double managerA2SehirDisiWage;
  final double managerA3SehirIciWage;
  final double managerA3SehirDisiWage;

  AppSettings({
    this.staffSehirIciWage = 1025.0,
    this.staffSehirDisiWage = 1100.0,
    this.managerA1SehirIciWage = 1400.0,
    this.managerA1SehirDisiWage = 1500.0,
    this.managerA2SehirIciWage = 1400.0,
    this.managerA2SehirDisiWage = 1500.0,
    this.managerA3SehirIciWage = 1400.0,
    this.managerA3SehirDisiWage = 1500.0,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    // Legacy support for managerSehirIciWage and managerSehirDisiWage
    final legacyManagerIci = (map['managerSehirIciWage'] ?? 1400.0).toDouble();
    final legacyManagerDisi = (map['managerSehirDisiWage'] ?? 1500.0).toDouble();

    return AppSettings(
      staffSehirIciWage: (map['staffSehirIciWage'] ?? 1025.0).toDouble(),
      staffSehirDisiWage: (map['staffSehirDisiWage'] ?? 1100.0).toDouble(),
      managerA1SehirIciWage: (map['managerA1SehirIciWage'] ?? legacyManagerIci).toDouble(),
      managerA1SehirDisiWage: (map['managerA1SehirDisiWage'] ?? legacyManagerDisi).toDouble(),
      managerA2SehirIciWage: (map['managerA2SehirIciWage'] ?? legacyManagerIci).toDouble(),
      managerA2SehirDisiWage: (map['managerA2SehirDisiWage'] ?? legacyManagerDisi).toDouble(),
      managerA3SehirIciWage: (map['managerA3SehirIciWage'] ?? legacyManagerIci).toDouble(),
      managerA3SehirDisiWage: (map['managerA3SehirDisiWage'] ?? legacyManagerDisi).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffSehirIciWage': staffSehirIciWage,
      'staffSehirDisiWage': staffSehirDisiWage,
      'managerA1SehirIciWage': managerA1SehirIciWage,
      'managerA1SehirDisiWage': managerA1SehirDisiWage,
      'managerA2SehirIciWage': managerA2SehirIciWage,
      'managerA2SehirDisiWage': managerA2SehirDisiWage,
      'managerA3SehirIciWage': managerA3SehirIciWage,
      'managerA3SehirDisiWage': managerA3SehirDisiWage,
    };
  }

  AppSettings copyWith({
    double? staffSehirIciWage,
    double? staffSehirDisiWage,
    double? managerA1SehirIciWage,
    double? managerA1SehirDisiWage,
    double? managerA2SehirIciWage,
    double? managerA2SehirDisiWage,
    double? managerA3SehirIciWage,
    double? managerA3SehirDisiWage,
  }) {
    return AppSettings(
      staffSehirIciWage: staffSehirIciWage ?? this.staffSehirIciWage,
      staffSehirDisiWage: staffSehirDisiWage ?? this.staffSehirDisiWage,
      managerA1SehirIciWage: managerA1SehirIciWage ?? this.managerA1SehirIciWage,
      managerA1SehirDisiWage: managerA1SehirDisiWage ?? this.managerA1SehirDisiWage,
      managerA2SehirIciWage: managerA2SehirIciWage ?? this.managerA2SehirIciWage,
      managerA2SehirDisiWage: managerA2SehirDisiWage ?? this.managerA2SehirDisiWage,
      managerA3SehirIciWage: managerA3SehirIciWage ?? this.managerA3SehirIciWage,
      managerA3SehirDisiWage: managerA3SehirDisiWage ?? this.managerA3SehirDisiWage,
    );
  }
}
