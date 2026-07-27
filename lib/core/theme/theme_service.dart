import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';

enum AppThemeType {
  defaultDark,
  pastelPink,
  pastelYellow,
  pastelOrange,
  pastelPurple,
  pastelBlue,
  pastelGreen,
  monochromeBlack,
  monochromeWhite,
  monochromeGray,
  custom,
}

class ThemeService extends ChangeNotifier {
  final StorageService _storage;
  late AppThemeType _currentTheme;

  ThemeService(this._storage) {
    _currentTheme = AppThemeType.values[_storage.getThemeIndex()];
    _applyTheme(_currentTheme);
  }

  AppThemeType get currentTheme => _currentTheme;

  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme == theme) return;
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

      case AppThemeType.pastelPink:
        AppColors.background = const Color(0xFFFFF0F5);
        AppColors.surface = const Color(0xFFFFE4E1);
        AppColors.card = const Color(0xFFFFD1DC);
        AppColors.cardLight = const Color(0xFFFFB6C1);
        AppColors.accent = const Color(0xFFD87093);
        AppColors.accentLight = const Color(0xFFFF69B4);
        AppColors.todayBorder = const Color(0xFFFF69B4);
        AppColors.divider = const Color(0xFFF8BBD0);
        AppColors.textPrimary = const Color(0xFF333333);
        AppColors.textSecondary = const Color(0xFF666666);
        AppColors.textHint = const Color(0xFF999999);
        AppColors.cityInner = const Color(0xFF0077B6);
        AppColors.cityOuter = const Color(0xFFF57C00);
        break;

      case AppThemeType.pastelYellow:
        AppColors.background = const Color(0xFFFFFFE0);
        AppColors.surface = const Color(0xFFFFFACD);
        AppColors.card = const Color(0xFFFFF8DC);
        AppColors.cardLight = const Color(0xFFFFE4B5);
        AppColors.accent = const Color(0xFFDAA520);
        AppColors.accentLight = const Color(0xFFFFA000); // Sarı-Turuncu tonu belirgin
        AppColors.todayBorder = const Color(0xFFFFA000);
        AppColors.divider = const Color(0xFFF0E68C);
        AppColors.textPrimary = const Color(0xFF333333);
        AppColors.textSecondary = const Color(0xFF666666);
        AppColors.textHint = const Color(0xFF999999);
        AppColors.cityInner = const Color(0xFF0077B6);
        AppColors.cityOuter = const Color(0xFFE65100);
        break;

      case AppThemeType.pastelOrange:
        AppColors.background = const Color(0xFFFFF5E6);
        AppColors.surface = const Color(0xFFFFE4CC);
        AppColors.card = const Color(0xFFFFD6B3);
        AppColors.cardLight = const Color(0xFFFFC299);
        AppColors.accent = const Color(0xFFE67300);
        AppColors.accentLight = const Color(0xFFFF8C1A);
        AppColors.todayBorder = const Color(0xFFFF8C1A);
        AppColors.divider = const Color(0xFFFFDAB9);
        AppColors.textPrimary = const Color(0xFF333333);
        AppColors.textSecondary = const Color(0xFF666666);
        AppColors.textHint = const Color(0xFF999999);
        AppColors.cityInner = const Color(0xFF0077B6);
        AppColors.cityOuter = const Color(0xFFD84315);
        break;

      case AppThemeType.pastelPurple:
        AppColors.background = const Color(0xFFF8F4FF);
        AppColors.surface = const Color(0xFFE6DDF2);
        AppColors.card = const Color(0xFFD4C4E5);
        AppColors.cardLight = const Color(0xFFC2ABD8);
        AppColors.accent = const Color(0xFF6A4C93);
        AppColors.accentLight = const Color(0xFF8860D0);
        AppColors.todayBorder = const Color(0xFF8860D0);
        AppColors.divider = const Color(0xFFDCD0FF);
        AppColors.textPrimary = const Color(0xFF333333);
        AppColors.textSecondary = const Color(0xFF666666);
        AppColors.textHint = const Color(0xFF999999);
        AppColors.cityInner = const Color(0xFF0077B6);
        AppColors.cityOuter = const Color(0xFFF57C00);
        break;

      case AppThemeType.pastelBlue:
        AppColors.background = const Color(0xFFF0F8FF);
        AppColors.surface = const Color(0xFFE1F0FF);
        AppColors.card = const Color(0xFFCCE5FF);
        AppColors.cardLight = const Color(0xFFB3D9FF);
        AppColors.accent = const Color(0xFF3385FF);
        AppColors.accentLight = const Color(0xFF66A3FF);
        AppColors.todayBorder = const Color(0xFF66A3FF);
        AppColors.divider = const Color(0xFFB0E0E6);
        AppColors.textPrimary = const Color(0xFF333333);
        AppColors.textSecondary = const Color(0xFF666666);
        AppColors.textHint = const Color(0xFF999999);
        AppColors.cityInner = const Color(0xFF0277BD);
        AppColors.cityOuter = const Color(0xFFF57C00);
        break;

      case AppThemeType.pastelGreen:
        AppColors.background = const Color(0xFFF0FFF0);
        AppColors.surface = const Color(0xFFE1FFE1);
        AppColors.card = const Color(0xFFCCFFCC);
        AppColors.cardLight = const Color(0xFFB3FFB3);
        AppColors.accent = const Color(0xFF2E8B57);
        AppColors.accentLight = const Color(0xFF3CB371);
        AppColors.todayBorder = const Color(0xFF3CB371);
        AppColors.divider = const Color(0xFFC1E1C1);
        AppColors.textPrimary = const Color(0xFF333333);
        AppColors.textSecondary = const Color(0xFF666666);
        AppColors.textHint = const Color(0xFF999999);
        AppColors.cityInner = const Color(0xFF0077B6);
        AppColors.cityOuter = const Color(0xFFF57C00);
        break;

      case AppThemeType.monochromeBlack:
        AppColors.background = const Color(0xFF000000);
        AppColors.surface = const Color(0xFF121212);
        AppColors.card = const Color(0xFF1E1E1E);
        AppColors.cardLight = const Color(0xFF2C2C2C);
        AppColors.accent = const Color(0xFF757575);
        AppColors.accentLight = const Color(0xFFBDBDBD);
        AppColors.todayBorder = const Color(0xFFBDBDBD);
        AppColors.divider = const Color(0xFF333333);
        AppColors.textPrimary = const Color(0xFFFFFFFF);
        AppColors.textSecondary = const Color(0xFFAAAAAA);
        AppColors.textHint = const Color(0xFF777777);
        AppColors.cityInner = const Color(0xFF4FC3F7);
        AppColors.cityOuter = const Color(0xFFFFB74D);
        break;

      case AppThemeType.monochromeWhite:
        AppColors.background = const Color(0xFFFFFFFF);
        AppColors.surface = const Color(0xFFF5F5F5);
        AppColors.card = const Color(0xFFEBEBEB);
        AppColors.cardLight = const Color(0xFFE0E0E0);
        AppColors.accent = const Color(0xFF333333);
        AppColors.accentLight = const Color(0xFF666666);
        AppColors.todayBorder = const Color(0xFF666666);
        AppColors.divider = const Color(0xFFDDDDDD);
        AppColors.textPrimary = const Color(0xFF111111);
        AppColors.textSecondary = const Color(0xFF555555);
        AppColors.textHint = const Color(0xFF888888);
        AppColors.cityInner = const Color(0xFF0077B6);
        AppColors.cityOuter = const Color(0xFFE65100);
        break;

      case AppThemeType.monochromeGray:
        AppColors.background = const Color(0xFFF0F0F0);
        AppColors.surface = const Color(0xFFE0E0E0);
        AppColors.card = const Color(0xFFD6D6D6);
        AppColors.cardLight = const Color(0xFFCCCCCC);
        AppColors.accent = const Color(0xFF424242);
        AppColors.accentLight = const Color(0xFF757575);
        AppColors.todayBorder = const Color(0xFF757575);
        AppColors.divider = const Color(0xFFBDBDBD);
        AppColors.textPrimary = const Color(0xFF212121);
        AppColors.textSecondary = const Color(0xFF616161);
        AppColors.textHint = const Color(0xFF9E9E9E);
        AppColors.cityInner = const Color(0xFF0077B6);
        AppColors.cityOuter = const Color(0xFFE65100);
        break;

      case AppThemeType.custom:
        final seedColor = Color(_storage.getCustomThemeColor());
        AppColors.background = const Color(0xFF121212);
        AppColors.surface = const Color(0xFF1E1E1E);
        AppColors.card = const Color(0xFF2C2C2C);
        AppColors.cardLight = const Color(0xFF3C3C3C);
        AppColors.accent = seedColor.withValues(alpha: 0.7);
        AppColors.accentLight = seedColor;
        AppColors.todayBorder = seedColor;
        AppColors.divider = const Color(0xFF444444);
        AppColors.textPrimary = Colors.white;
        AppColors.textSecondary = Colors.white70;
        AppColors.textHint = Colors.white54;
        AppColors.cityInner = const Color(0xFF4FC3F7);
        AppColors.cityOuter = const Color(0xFFFFB74D);
        break;
    }

    // Update the system overlay to match the background color
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: AppColors.background.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: AppColors.background.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light,
      ),
    );
  }

  String getThemeName(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultDark:
        return 'Okyanus (Varsayılan)';
      case AppThemeType.pastelPink:
        return 'Pastel Pembe';
      case AppThemeType.pastelYellow:
        return 'Pastel Sarı';
      case AppThemeType.pastelOrange:
        return 'Pastel Turuncu';
      case AppThemeType.pastelPurple:
        return 'Pastel Mor';
      case AppThemeType.pastelBlue:
        return 'Pastel Mavi';
      case AppThemeType.pastelGreen:
        return 'Pastel Yeşil';
      case AppThemeType.monochromeBlack:
        return 'Gece Siyahı';
      case AppThemeType.monochromeWhite:
        return 'Saf Beyaz';
      case AppThemeType.monochromeGray:
        return 'Nötr Gri';
      case AppThemeType.custom:
        return 'Özel Renk';
    }
  }

  Color getThemeColorPreview(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultDark:
        return const Color(0xFF3A86FF);
      case AppThemeType.pastelPink:
        return const Color(0xFFFFB5A7);
      case AppThemeType.pastelYellow:
        return const Color(0xFFFDF0D5);
      case AppThemeType.pastelOrange:
        return const Color(0xFFFFD6BA);
      case AppThemeType.pastelPurple:
        return const Color(0xFFC1B3D7);
      case AppThemeType.pastelBlue:
        return const Color(0xFFA8D0E6);
      case AppThemeType.pastelGreen:
        return const Color(0xFFB8E0D2);
      case AppThemeType.monochromeBlack:
        return const Color(0xFF555555);
      case AppThemeType.monochromeWhite:
        return const Color(0xFFFFFFFF);
      case AppThemeType.monochromeGray:
        return const Color(0xFFB0B0B8);
      case AppThemeType.custom:
        // Use the actual custom color from storage
        return Color(_storage.getCustomThemeColor());
    }
  }
}
