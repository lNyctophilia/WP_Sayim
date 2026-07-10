class AppSettings {
  final double staffSehirIciWage;
  final double staffSehirDisiWage;
  final double managerSehirIciWage;
  final double managerSehirDisiWage;

  AppSettings({
    this.staffSehirIciWage = 1025.0,
    this.staffSehirDisiWage = 1100.0,
    this.managerSehirIciWage = 1400.0,
    this.managerSehirDisiWage = 1500.0,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      staffSehirIciWage: (map['staffSehirIciWage'] ?? 1025.0).toDouble(),
      staffSehirDisiWage: (map['staffSehirDisiWage'] ?? 1100.0).toDouble(),
      managerSehirIciWage: (map['managerSehirIciWage'] ?? 1400.0).toDouble(),
      managerSehirDisiWage: (map['managerSehirDisiWage'] ?? 1500.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffSehirIciWage': staffSehirIciWage,
      'staffSehirDisiWage': staffSehirDisiWage,
      'managerSehirIciWage': managerSehirIciWage,
      'managerSehirDisiWage': managerSehirDisiWage,
    };
  }

  AppSettings copyWith({
    double? staffSehirIciWage,
    double? staffSehirDisiWage,
    double? managerSehirIciWage,
    double? managerSehirDisiWage,
  }) {
    return AppSettings(
      staffSehirIciWage: staffSehirIciWage ?? this.staffSehirIciWage,
      staffSehirDisiWage: staffSehirDisiWage ?? this.staffSehirDisiWage,
      managerSehirIciWage: managerSehirIciWage ?? this.managerSehirIciWage,
      managerSehirDisiWage: managerSehirDisiWage ?? this.managerSehirDisiWage,
    );
  }
}
