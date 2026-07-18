import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences tabanlı veri depolama servisi
/// İş günü verileri Firestore üzerinden yönetilir (WorkDayRepository).
/// Bu servis sadece yerel ayarları (dil, oturum, son görüntülenen ay) saklar.
class StorageService {
  static const String _prefsLang = 'language';
  static const String _prefsCityInner = 'city_inner_payment';
  static const String _prefsCityOuter = 'city_outer_payment';
  static const String _prefsLastYear = 'last_viewed_year';
  static const String _prefsLastMonth = 'last_viewed_month';
  static const String _prefsSessionId = 'session_id';
  static const String _prefsLastPanel = 'last_active_panel';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Dil ──────────────────────────────────────────────────

  String getLanguage() => _prefs.getString(_prefsLang) ?? 'tr';

  Future<void> setLanguage(String lang) async {
    await _prefs.setString(_prefsLang, lang);
  }

  // ─── Oturum (Session) ─────────────────────────────────────

  String? getSessionId() => _prefs.getString(_prefsSessionId);

  Future<void> setSessionId(String? sessionId) async {
    if (sessionId == null) {
      await _prefs.remove(_prefsSessionId);
    } else {
      await _prefs.setString(_prefsSessionId, sessionId);
    }
  }

  // ─── Varsayılan Ücretler ──────────────────────────────────

  double getCityInnerPayment() =>
      _prefs.getDouble(_prefsCityInner) ?? 1025.0;

  double getCityOuterPayment() =>
      _prefs.getDouble(_prefsCityOuter) ?? 1100.0;

  Future<void> setCityInnerPayment(double value) async {
    await _prefs.setDouble(_prefsCityInner, value);
  }

  Future<void> setCityOuterPayment(double value) async {
    await _prefs.setDouble(_prefsCityOuter, value);
  }

  // ─── Son Görüntülenen Ay ──────────────────────────────────

  int getLastViewedYear() =>
      _prefs.getInt(_prefsLastYear) ?? DateTime.now().year;

  int getLastViewedMonth() =>
      _prefs.getInt(_prefsLastMonth) ?? DateTime.now().month;

  Future<void> setLastViewed(int year, int month) async {
    await _prefs.setInt(_prefsLastYear, year);
    await _prefs.setInt(_prefsLastMonth, month);
  }

  // ─── Son Aktif Panel ──────────────────────────────────────

  String getLastPanel() => _prefs.getString(_prefsLastPanel) ?? 'home';

  Future<void> setLastPanel(String panel) async {
    await _prefs.setString(_prefsLastPanel, panel);
  }

  // ─── Son Aktif Manager Tab ────────────────────────────────

  int getLastManagerTab() => _prefs.getInt('last_manager_tab') ?? 0;

  Future<void> setLastManagerTab(int index) async {
    await _prefs.setInt('last_manager_tab', index);
  }
}
