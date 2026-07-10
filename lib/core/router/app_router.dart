import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/manager/presentation/pages/manager_panel_page.dart';

/// Ana yönlendirici widget — Auth durumuna göre Login veya Ana Ekranı gösterir
///
/// Login sonrası kullanıcının rolüne göre farklı ekranlar gösterilecek:
/// - Owner: Yönetici Paneli (+ yönetici yönetimi sekmesi)
/// - Manager: Yönetici Paneli
/// - Staff: Mevcut takvim ekranı (personel görünümü)
class AppRouter extends StatefulWidget {
  final StorageService storage;
  final LanguageService lang;

  const AppRouter({
    super.key,
    required this.storage,
    required this.lang,
  });

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Bağlantı bekleniyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashScreen();
        }

        // Kullanıcı giriş yapmamış
        if (!snapshot.hasData || snapshot.data == null) {
          return LoginPage(
            lang: widget.lang,
            onLoginSuccess: (_) {
              // StreamBuilder otomatik olarak yeniden build edecek
            },
          );
        }

        // Kullanıcı giriş yapmış — rolünü kontrol et
        return FutureBuilder<AppUser?>(
          future: _authService.getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildSplashScreen();
            }

            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Hata: ${userSnapshot.error}'),
                ),
              );
            }

            final appUser = userSnapshot.data;

            if (appUser == null) {
              // Firestore'da kullanıcı verisi yok — çıkış yap
              _authService.logout();
              return _buildSplashScreen();
            }

            // Aktif olmayan hesapsa girişine izin verme
            if (!appUser.active) {
              _authService.logout();
              return _buildSplashScreen();
            }

            // Rol bazlı yönlendirme
            return _buildHomeForRole(appUser);
          },
        );
      },
    );
  }

  /// Kullanıcının rolüne göre uygun ana ekranı döndür
  Widget _buildHomeForRole(AppUser user) {
    if (user.isOwner || user.isManager) {
      return ManagerPanelPage(
        currentUser: user,
        storage: widget.storage,
        lang: widget.lang,
        onLogout: () {
          // authStateChanges stream tetikleneceği için ekstra bir şey gerekmiyor
        },
      );
    }

    // Personel — mevcut takvim ekranı
    return HomePage(
      storage: widget.storage,
      lang: widget.lang,
      currentUser: user,
    );
  }

  /// Uygulama yüklenirken gösterilen ekran
  Widget _buildSplashScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
