import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/preset_location.dart';

/// Hazır konumlar için Firestore servisi
/// Güvenlik kuralları /settings/{document} iznine sahip olduğundan
/// `settings/hazir_konumlar` dokümanı altında saklanır.
class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference get _doc => _firestore.collection('settings').doc('hazir_konumlar');

  /// Tüm hazır konumları dinle (isme göre alfabetik sıralı)
  Stream<List<PresetLocation>> getPresetLocations() {
    return _doc.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return <PresetLocation>[];
      }
      final data = snapshot.data() as Map<String, dynamic>;
      final rawList = data['items'] as List<dynamic>? ?? [];

      final locations = rawList.map((item) {
        if (item is Map<String, dynamic>) {
          return PresetLocation.fromMap(item);
        } else if (item is Map) {
          return PresetLocation.fromMap(Map<String, dynamic>.from(item));
        }
        return const PresetLocation(id: '', name: '', url: '');
      }).where((l) => l.name.isNotEmpty && l.url.isNotEmpty).toList();

      locations.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return locations;
    });
  }

  /// Tek seferlik tüm hazır konumları getir
  Future<List<PresetLocation>> getPresetLocationsOnce() async {
    try {
      final snapshot = await _doc.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return <PresetLocation>[];
      }
      final data = snapshot.data() as Map<String, dynamic>;
      final rawList = data['items'] as List<dynamic>? ?? [];

      final locations = rawList.map((item) {
        if (item is Map<String, dynamic>) {
          return PresetLocation.fromMap(item);
        } else if (item is Map) {
          return PresetLocation.fromMap(Map<String, dynamic>.from(item));
        }
        return const PresetLocation(id: '', name: '', url: '');
      }).where((l) => l.name.isNotEmpty && l.url.isNotEmpty).toList();

      locations.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return locations;
    } catch (_) {
      return <PresetLocation>[];
    }
  }

  /// Yeni hazır konum ekle (Sadece isim ve link)
  Future<void> addPresetLocation({
    required String name,
    required String url,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newLoc = PresetLocation(
      id: id,
      name: name.trim(),
      url: url.trim(),
    );

    final snapshot = await _doc.get();
    List<dynamic> items = [];
    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data() as Map<String, dynamic>;
      items = List<dynamic>.from(data['items'] as List<dynamic>? ?? []);
    }

    items.add(newLoc.toMap());
    await _doc.set({'items': items}, SetOptions(merge: true));
  }

  /// Hazır konumu güncelle
  Future<void> updatePresetLocation(PresetLocation location) async {
    final snapshot = await _doc.get();
    if (!snapshot.exists || snapshot.data() == null) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final items = List<dynamic>.from(data['items'] as List<dynamic>? ?? []);

    final index = items.indexWhere((item) {
      if (item is Map) return item['id'] == location.id;
      return false;
    });

    if (index != -1) {
      items[index] = location.toMap();
      await _doc.set({'items': items}, SetOptions(merge: true));
    }
  }

  /// Hazır konumu sil
  Future<void> deletePresetLocation(String id) async {
    final snapshot = await _doc.get();
    if (!snapshot.exists || snapshot.data() == null) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final items = List<dynamic>.from(data['items'] as List<dynamic>? ?? []);

    items.removeWhere((item) {
      if (item is Map) return item['id'] == id;
      return false;
    });

    await _doc.set({'items': items}, SetOptions(merge: true));
  }
}
