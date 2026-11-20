import 'package:cloud_firestore/cloud_firestore.dart';

/// Hazır AVM / Mekan konumu modeli
class PresetLocation {
  final String id;
  final String name;
  final String url;
  final String city;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PresetLocation({
    required this.id,
    required this.name,
    required this.url,
    this.city = '',
    this.description = '',
    this.createdAt,
    this.updatedAt,
  });

  PresetLocation copyWith({
    String? id,
    String? name,
    String? url,
    String? city,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PresetLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      city: city ?? this.city,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PresetLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PresetLocation(
      id: doc.id,
      name: data['name'] as String? ?? '',
      url: data['url'] as String? ?? '',
      city: data['city'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'url': url.trim(),
      'city': city.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
