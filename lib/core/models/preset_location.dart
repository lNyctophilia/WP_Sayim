import 'package:cloud_firestore/cloud_firestore.dart';

/// Hazır AVM / Mekan konumu modeli (Sadece İsim ve Link)
class PresetLocation {
  final String id;
  final String name;
  final String url;

  const PresetLocation({
    required this.id,
    required this.name,
    required this.url,
  });

  PresetLocation copyWith({
    String? id,
    String? name,
    String? url,
  }) {
    return PresetLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
    );
  }

  factory PresetLocation.fromMap(Map<String, dynamic> map, [String? id]) {
    return PresetLocation(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      url: map['url'] as String? ?? '',
    );
  }

  factory PresetLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PresetLocation(
      id: doc.id,
      name: data['name'] as String? ?? '',
      url: data['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'url': url.trim(),
    };
  }
}
