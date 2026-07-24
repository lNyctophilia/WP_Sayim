import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/manager/presentation/pages/manager_shell_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/notification_service.dart';
import '../../features/auth/presentation/pages/install_prompt_page.dart';
import '../utils/pwa_check.dart';
import '../utils/bottom_toast.dart';

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
  final NotificationService _notificationService = NotificationService();
  String? _initializedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Bağlantı bekleniyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashScreen();
        }

        final isMobileWeb = kIsWeb && isMobileBrowser();
        if (isMobileWeb && !isPWA()) {
          return const InstallPromptPage();
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
        return StreamBuilder<AppUser?>(
          stream: _authService.getUserDataStream(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildSplashScreen();
            }

            if (userSnapshot.hasError) {
              // Hata durumunda (ör: çevrimdışıyken cache yoksa) otomatik çıkış YAPMA!
              // Kullanıcıyı sadece bir hata ekranında beklet.
              return Scaffold(
                body: Center(
                  child: Text(
                    'Bağlantı hatası veya yetki sorunu: ${userSnapshot.error}\nLütfen internet bağlantınızı kontrol edin.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final appUser = userSnapshot.data;

            if (appUser == null) {
              // Firestore'da kullanıcı verisi gerçekten yok (silinmiş)
              // Sadece o zaman çıkış yap.
              Future.microtask(() => _authService.logout());
              return _buildSplashScreen();
            }

            // Aktif olmayan hesapsa girişine izin verme
            if (!appUser.active) {
              Future.microtask(() => _authService.logout());
              return Scaffold(
                body: Center(
                  child: Text('Hesabınız askıya alınmış.'),
                ),
              );
            }

            // Oturum çakışması kontrolü (Eğer aktif bir giriş işlemi yoksa)
            final localSessionId = widget.storage.getSessionId();
            if (!AuthService.isLoggingIn && appUser.sessionId != null && localSessionId != null && appUser.sessionId != localSessionId) {
              // Farklı bir cihazda giriş yapılmış, bu cihazı oturumdan at (Kicked = true)
              Future.microtask(() => _authService.logout(true));
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Hesabınıza başka bir cihazdan giriş yapıldı.\nGüvenliğiniz için bu cihazdaki oturumunuz kapatıldı.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent, fontSize: 16),
                    ),
                  ),
                ),
              );
            }

            // Bildirim servisini başlat (Sadece yeni bir kullanıcı geldiğinde)
            if (_initializedUid != appUser.id) {
              _initializedUid = appUser.id;
              _notificationService.initialize();
              
              // Uygulama açıkken (ön plandayken) gelen bildirimleri dinle
              FirebaseMessaging.onMessage.listen((RemoteMessage message) {
                if (message.notification != null) {
                  final title = message.notification!.title ?? 'Bildirim';
                  final body = message.notification!.body ?? '';

                  // Her sayfanın üzerinde (en üstte) görünecek özel toast bildirimi
                  BottomToast.show(context, title, body);
                }
              });
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
    final lastPanel = widget.storage.getLastPanel();

    // Adminler (Owner) doğrudan Yönetici Panellerinde başlar, iş takvimleri yoktur.
    if (user.isOwner) {
      return ManagerShellPage(
        currentUser: user,
        storage: widget.storage,
        lang: widget.lang,
        initialPanel: lastPanel.isEmpty ? 'manager' : lastPanel,
        onLogout: () {},
      );
    }

    if (user.isManager) {
      if (lastPanel != 'home') {
        return ManagerShellPage(
          currentUser: user,
          storage: widget.storage,
          lang: widget.lang,
          initialPanel: lastPanel.isEmpty ? 'manager' : lastPanel,
          onLogout: () {},
        );
      }
    }

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
