import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/services/language_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'core/router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Arka plan mesaj handler — Web'de Service Worker kullanılır, burada sadece mobile
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Durum çubuğu şeffaf — Web'de etkisiz ama hata vermez
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A1128),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // Servisleri başlat
  final storage = StorageService();
  await storage.init();

  final lang = LanguageService(storage);
  final themeService = ThemeService(storage);

  runApp(DayTrackApp(storage: storage, lang: lang, themeService: themeService));
}

class DayTrackApp extends StatefulWidget {
  final StorageService storage;
  final LanguageService lang;
  final ThemeService themeService;

  const DayTrackApp({
    super.key,
    required this.storage,
    required this.lang,
    required this.themeService,
  });

  @override
  State<DayTrackApp> createState() => _DayTrackAppState();
}

class _DayTrackAppState extends State<DayTrackApp> {
  @override
  void initState() {
    super.initState();
    // Dil ve Tema değişiminde rebuild
    widget.lang.addListener(_onRebuild);
    widget.themeService.addListener(_onRebuild);
  }

  @override
  void dispose() {
    widget.lang.removeListener(_onRebuild);
    widget.themeService.removeListener(_onRebuild);
    super.dispose();
  }

  void _onRebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WP Sayım',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: AppRouter(
        storage: widget.storage,
        lang: widget.lang,
        themeService: widget.themeService,
      ),
    );
  }
}
