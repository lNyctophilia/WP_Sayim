import 'package:cloud_firestore/cloud_firestore.dart';

/// Tek bir iş günü verisi
class WorkDay {
  final DateTime date;
  final bool isCityCenter; // true = şehir içi, false = şehir dışı
  final double payment;
  final String note;
  final String toplanmaYeri;
  final String? grupSaati;
  final String? sayimStartTime;
  final String? sayimId;

  const WorkDay({
    required this.date,
    required this.isCityCenter,
    required this.payment,
    this.note = '',
    this.toplanmaYeri = '',
    this.grupSaati,
    this.sayimStartTime,
    this.sayimId,
  });

  WorkDay copyWith({
    DateTime? date,
    bool? isCityCenter,
    double? payment,
    String? note,
    String? toplanmaYeri,
    String? grupSaati,
    String? sayimStartTime,
    String? sayimId,
  }) {
    return WorkDay(
      date: date ?? this.date,
      isCityCenter: isCityCenter ?? this.isCityCenter,
      payment: payment ?? this.payment,
      note: note ?? this.note,
      toplanmaYeri: toplanmaYeri ?? this.toplanmaYeri,
      grupSaati: grupSaati ?? this.grupSaati,
      sayimStartTime: sayimStartTime ?? this.sayimStartTime,
      sayimId: sayimId ?? this.sayimId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'isCityCenter': isCityCenter,
      'payment': payment,
      'note': note,
      'toplanmaYeri': toplanmaYeri,
      if (grupSaati != null) 'grupSaati': grupSaati,
      if (sayimStartTime != null) 'sayimStartTime': sayimStartTime,
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
      toplanmaYeri: json['toplanmaYeri'] as String? ?? '',
      grupSaati: json['grupSaati'] as String?,
      sayimStartTime: json['sayimStartTime'] as String?,
      sayimId: json['sayimId'] as String?,
    );
  }

  String get displayNote {
    final timeToUse = (sayimStartTime != null && sayimStartTime!.trim().isNotEmpty) 
        ? sayimStartTime 
        : grupSaati;

    if (timeToUse == null || timeToUse.isEmpty) return note;

    try {
      final parts = timeToUse.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final targetTime = DateTime(date.year, date.month, date.day, hour, minute);
      
      final now = DateTime.now();
      if (now.compareTo(targetTime) >= 0) {
        return note;
      } else {
        final toplanmaText = toplanmaYeri.trim().isNotEmpty 
            ? toplanmaYeri 
            : 'Toplanma Yeri Belirtilmedi';
            
        if (grupSaati != null && grupSaati!.trim().isNotEmpty) {
          return '$toplanmaText ${grupSaati!}';
        }
        return toplanmaText;
      }
    } catch (e) {
      return note;
    }
  }
}
