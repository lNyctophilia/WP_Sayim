import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'notification_service.dart';

/// Firebase Auth servisi — pseudo-email yöntemiyle kullanıcı adı + şifre
///
/// Kullanıcı adı "ahmet.yilmaz" girildiğinde arka planda
/// "ahmet.yilmaz@wpsayim.local" e-postasına dönüştürülür.
/// Kullanıcı hiçbir zaman e-posta görmez.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _emailDomain = 'wpsayim.local';

  /// Kullanıcı adını pseudo-email'e çevir
  String _toEmail(String username) =>
      '${username.trim().toLowerCase()}@$_emailDomain';

  /// Şu an oturum açmış kullanıcı (Firebase User)
  User? get currentFirebaseUser => _auth.currentUser;

  /// Oturum açık mı?
  bool get isLoggedIn => _auth.currentUser != null;

  /// Auth durumu değişikliklerini dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Giriş ──────────────────────────────────────────────────

  /// Kullanıcı adı + şifre ile giriş yap
  Future<AppUser?> login(String username, String password) async {
    try {
      final email = _toEmail(username);
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      // Firestore'dan kullanıcı bilgisini getir
      return await getUserData(credential.user!.uid);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    try {
      await NotificationService().clearToken();
    } catch (e) {
      // Token silinirken hata olsa bile çıkışa devam et
    }
    await _auth.signOut();
  }

  // ─── Kullanıcı Oluşturma (Yönetici/Owner tarafından) ───────

  /// Yeni kullanıcı hesabı oluştur
  /// [createdByUid] — Bu hesabı oluşturan yönetici/owner'ın UID'si
  Future<AppUser> createUser({
    required String username,
    required String password,
    required String fullName,
    required List<UserRole> roles,
    required String createdByUid,
    double? defaultWage,
  }) async {
    final email = _toEmail(username);

    // 1. Firebase Auth'ta hesap oluştur
    // Mevcut kullanıcının oturumu kapanmasın diye (Firebase limitasyonu),
    // geçici bir FirebaseApp örneği kullanıyoruz.
    final tempApp = await Firebase.initializeApp(
      name: 'TempAuthApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    
    final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

    try {
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUserId = credential.user!.uid;

      // İşimiz bitti, geçici uygulamayı sil.
      await tempApp.delete();

      // 2. Firestore'a kullanıcı bilgisini kaydet
      final appUser = AppUser(
        id: newUserId,
        username: username.trim().toLowerCase(),
        fullName: fullName,
        password: password,
        roles: roles,
        defaultWage: defaultWage,
        createdBy: createdByUid,
        active: true,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(newUserId)
          .set(appUser.toFirestore());

      return appUser;
    } catch (e) {
      await tempApp.delete();
      rethrow;
    }
  }

  // ─── Kullanıcı Bilgisi ─────────────────────────────────────

  /// UID ile Firestore'dan kullanıcı bilgisini getir
  Future<AppUser?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Şu an oturum açmış kullanıcının AppUser verisini getir
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await getUserData(user.uid);
  }

  /// Kullanıcı adının zaten kullanılıp kullanılmadığını kontrol et
  Future<bool> isUsernameTaken(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // ─── Hesap Yönetimi ────────────────────────────────────────

  /// Kullanıcıyı deaktif et (silmek yerine)
  Future<void> deactivateUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'active': false});
  }

  /// Kullanıcıyı aktif et
  Future<void> activateUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'active': true});
  }

  /// Kullanıcıyı veritabanından tamamen sil
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  /// Admin/Owner yetkisiyle kullanıcı bilgilerini güncelle
  Future<void> updateUserAdmin({
    required String uid,
    String? fullName,
    String? username,
    String? password,
  }) async {
    final Map<String, dynamic> updates = {};
    if (fullName != null && fullName.isNotEmpty) updates['fullName'] = fullName;
    if (username != null && username.isNotEmpty) updates['username'] = username;
    if (password != null && password.isNotEmpty) updates['password'] = password;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  /// Şifre değiştir (kendi şifresini)
  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  /// Tüm kullanıcıları getir (yönetici/owner için)
  Future<List<AppUser>> getAllUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('active', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }

  /// Sadece belirli roldeki kullanıcıları getir
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    final snapshot = await _firestore
        .collection('users')
        .where('roles', arrayContains: role.name)
        .where('active', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }
}
