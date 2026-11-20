import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/preset_location.dart';

/// Hazır konumlar için Firestore servisi
class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('hazir_konumlar');

  /// Tüm hazır konumları stream olarak dinle (isme göre alfabetik)
  Stream<List<PresetLocation>> getPresetLocations() {
    return _col.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PresetLocation.fromFirestore(doc)).toList();
    });
  }

  /// Tek seferlik tüm hazır konumları getir
  Future<List<PresetLocation>> getPresetLocationsOnce() async {
    final snapshot = await _col.orderBy('name').get();
    return snapshot.docs.map((doc) => PresetLocation.fromFirestore(doc)).toList();
  }

  /// Yeni hazır konum ekle
  Future<void> addPresetLocation({
    required String name,
    required String url,
    String? city,
    String? description,
  }) async {
    await _col.add({
      'name': name.trim(),
      'url': url.trim(),
      'city': city?.trim() ?? '',
      'description': description?.trim() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hazır konumu güncelle
  Future<void> updatePresetLocation(PresetLocation location) async {
    await _col.doc(location.id).update({
      'name': location.name.trim(),
      'url': location.url.trim(),
      'city': location.city.trim(),
      'description': location.description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hazır konumu sil
  Future<void> deletePresetLocation(String id) async {
    await _col.doc(id).delete();
  }
}
