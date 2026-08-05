import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../utils/pwa_theme.dart';
import '../services/storage_service.dart';

enum AppThemeType {
  defaultDark,
  custom,
}

class ThemeService extends ChangeNotifier {
  final StorageService _storage;
  late AppThemeType _currentTheme;

  ThemeService(this._storage) {
    int index = _storage.getThemeIndex();
    if (index < 0 || index >= AppThemeType.values.length) {
      index = 0;
    }
    _currentTheme = AppThemeType.values[index];
    _applyTheme(_currentTheme);
  }

  AppThemeType get currentTheme => _currentTheme;

  Future<void> setTheme(AppThemeType theme, {bool forceUpdate = false}) async {
    if (_currentTheme == theme && !forceUpdate) return;
    _currentTheme = theme;
    await _storage.setThemeIndex(theme.index);
    _applyTheme(theme);
    notifyListeners();
  }

  void _applyTheme(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.defaultDark:
        // Varsayılan Koyu Lacivert (Orjinal)
        AppColors.background = const Color(0xFF0A1128);
        AppColors.surface = const Color(0xFF131D35);
        AppColors.card = const Color(0xFF1B2845);
        AppColors.cardLight = const Color(0xFF223354);
        AppColors.accent = const Color(0xFF274472);
        AppColors.accentLight = const Color(0xFF3A86FF);
        AppColors.todayBorder = const Color(0xFF3A86FF);
        AppColors.divider = const Color(0xFF1E3050);
        AppColors.textPrimary = const Color(0xFFFFFFFF);
        AppColors.textSecondary = const Color(0xFF8899AA);
        AppColors.textHint = const Color(0xFF556677);
        AppColors.cityInner = const Color(0xFF48BFE3);
        AppColors.cityOuter = const Color(0xFFF9A826);
        break;

      case AppThemeType.custom:
        final seedColor = Color(_storage.getCustomThemeColor());
        final hslSeed = HSLColor.fromColor(seedColor);
        final hue = hslSeed.hue;
        final sat = hslSeed.saturation;
        
        // Siyah/Beyaz/Gri seçildiyse doygunluğu 0'da tut, yoksa 0.10 gibi ufak bir tint bırak
        final textSat = sat > 0.05 ? 0.10 : 0.0;
        
        // HER ZAMAN KOYU TEMA (Kullanıcı isteği üzerine açık tema geçişi kaldırıldı)
        final bgSat = sat.clamp(0.0, 0.40); // Koyu temada %40'a kadar doygunluk güzel durur
        AppColors.background = HSLColor.fromAHSL(1.0, hue, bgSat, 0.10).toColor();
        AppColors.surface = HSLColor.fromAHSL(1.0, hue, bgSat, 0.14).toColor();
        AppColors.card = HSLColor.fromAHSL(1.0, hue, bgSat, 0.19).toColor();
        AppColors.cardLight = HSLColor.fromAHSL(1.0, hue, bgSat, 0.23).toColor();
        
        AppColors.accent = HSLColor.fromAHSL(1.0, hue, sat.clamp(0.4, 1.0), 0.30).toColor();
        AppColors.accentLight = hslSeed.withLightness(hslSeed.lightness.clamp(0.60, 1.0)).toColor(); 
        AppColors.todayBorder = AppColors.accentLight;
        
        AppColors.divider = HSLColor.fromAHSL(1.0, hue, bgSat, 0.21).toColor();
        
        AppColors.textPrimary = HSLColor.fromAHSL(1.0, hue, textSat, 0.95).toColor();
        AppColors.textSecondary = HSLColor.fromAHSL(1.0, hue, textSat + 0.10, 0.60).toColor();
        AppColors.textHint = HSLColor.fromAHSL(1.0, hue, textSat + 0.05, 0.40).toColor();
        
        // Şehir ve Fonksiyon Renkleri (Gri seçildiyse renksiz tut)
        final innerHue = (hue - 32 + 360) % 360; 
        final outerHue = (hue + 171) % 360; 
        AppColors.cityInner = HSLColor.fromAHSL(1.0, innerHue, sat > 0.05 ? 0.70 : 0.0, 0.60).toColor();
        AppColors.cityOuter = HSLColor.fromAHSL(1.0, outerHue, sat > 0.05 ? 0.80 : 0.0, 0.60).toColor();
        break;
    }

    // Update the system overlay to match the background color
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: AppColors.background.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: AppColors.background.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );

    // PWA: Sadece safebar (status bar/address bar) rengini dinamik tut
    final bgHex = '#${AppColors.background.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    updatePwaTheme(bgHex);
  }

  String getThemeName(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultDark:
        return 'Okyanus (Varsayılan)';
      case AppThemeType.custom:
        return 'Özel Renk';
    }
  }

  Color getThemeColorPreview(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultDark:
        return const Color(0xFF3A86FF);
      case AppThemeType.custom:
        // Use the actual custom color from storage
        return Color(_storage.getCustomThemeColor());
    }
  }
}
