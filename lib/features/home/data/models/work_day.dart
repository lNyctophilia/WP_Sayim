import 'package:cloud_firestore/cloud_firestore.dart';

/// Tek bir iş günü verisi
class WorkDay {
  final DateTime date;
  final bool isCityCenter; // true = şehir içi, false = şehir dışı
  final double payment;
  final String note;
  final String? sayimId;

  const WorkDay({
    required this.date,
    required this.isCityCenter,
    required this.payment,
    this.note = '',
    this.sayimId,
  });

  WorkDay copyWith({
    DateTime? date,
    bool? isCityCenter,
    double? payment,
    String? note,
    String? sayimId,
  }) {
    return WorkDay(
      date: date ?? this.date,
      isCityCenter: isCityCenter ?? this.isCityCenter,
      payment: payment ?? this.payment,
      note: note ?? this.note,
      sayimId: sayimId ?? this.sayimId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'isCityCenter': isCityCenter,
      'payment': payment,
      'note': note,
      if (sayimId != null) 'sayimId': sayimId,
    };
  }

  factory WorkDay.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final dateVal = json['date'];
    if (dateVal is Timestamp) {
      parsedDate = dateVal.toDate();
    } else if (dateVal is String) {
      parsedDate = DateTime.parse(dateVal);
    } else {
      parsedDate = DateTime.now();
    }

    return WorkDay(
      date: parsedDate,
      isCityCenter: json['isCityCenter'] as bool? ?? true,
      payment: (json['payment'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String? ?? '',
      sayimId: json['sayimId'] as String?,
    );
  }
}
