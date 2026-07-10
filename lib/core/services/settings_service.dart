import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_settings.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<AppSettings> getSettings() {
    return _firestore
        .collection('settings')
        .doc('global')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return AppSettings();
      }
      return AppSettings.fromMap(doc.data()!);
    });
  }

  Future<AppSettings> getSettingsOnce() async {
    final doc = await _firestore.collection('settings').doc('global').get();
    if (!doc.exists || doc.data() == null) {
      return AppSettings();
    }
    return AppSettings.fromMap(doc.data()!);
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _firestore
        .collection('settings')
        .doc('global')
        .set(settings.toMap(), SetOptions(merge: true));
  }
}
