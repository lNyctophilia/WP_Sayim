import 'package:flutter/material.dart';
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
        break;

      case AppThemeType.pastelPink:
        AppColors.background = const Color(0xFF1A1115);
        AppColors.surface = const Color(0xFF261820);
        AppColors.card = const Color(0xFF341F2B);
        AppColors.cardLight = const Color(0xFF422837);
        AppColors.accent = const Color(0xFFB56576);
        AppColors.accentLight = const Color(0xFFFFB5A7); // Pastel Pink
        AppColors.todayBorder = const Color(0xFFFFB5A7);
        AppColors.divider = const Color(0xFF4A303F);
        break;

      case AppThemeType.pastelYellow:
        AppColors.background = const Color(0xFF1A1A10);
        AppColors.surface = const Color(0xFF252516);
        AppColors.card = const Color(0xFF31311C);
        AppColors.cardLight = const Color(0xFF3F3F24);
        AppColors.accent = const Color(0xFFBFA15F);
        AppColors.accentLight = const Color(0xFFFDF0D5); // Pastel Yellow
        AppColors.todayBorder = const Color(0xFFFDF0D5);
        AppColors.divider = const Color(0xFF48482A);
        break;

      case AppThemeType.pastelOrange:
        AppColors.background = const Color(0xFF1A1410);
        AppColors.surface = const Color(0xFF261D16);
        AppColors.card = const Color(0xFF34261C);
        AppColors.cardLight = const Color(0xFF423024);
        AppColors.accent = const Color(0xFFC07C50);
        AppColors.accentLight = const Color(0xFFFFD6BA); // Pastel Orange
        AppColors.todayBorder = const Color(0xFFFFD6BA);
        AppColors.divider = const Color(0xFF4A382A);
        break;

      case AppThemeType.pastelPurple:
        AppColors.background = const Color(0xFF14111A);
        AppColors.surface = const Color(0xFF1E1826);
        AppColors.card = const Color(0xFF281F34);
        AppColors.cardLight = const Color(0xFF332842);
        AppColors.accent = const Color(0xFF8860D0);
        AppColors.accentLight = const Color(0xFFC1B3D7); // Pastel Purple
        AppColors.todayBorder = const Color(0xFFC1B3D7);
        AppColors.divider = const Color(0xFF3E314F);
        break;

      case AppThemeType.pastelBlue:
        AppColors.background = const Color(0xFF0F141A);
        AppColors.surface = const Color(0xFF161E26);
        AppColors.card = const Color(0xFF1E2834);
        AppColors.cardLight = const Color(0xFF283442);
        AppColors.accent = const Color(0xFF5B8E7D);
        AppColors.accentLight = const Color(0xFFA8D0E6); // Pastel Light Blue
        AppColors.todayBorder = const Color(0xFFA8D0E6);
        AppColors.divider = const Color(0xFF324152);
        break;

      case AppThemeType.pastelGreen:
        AppColors.background = const Color(0xFF0F1A14);
        AppColors.surface = const Color(0xFF16261D);
        AppColors.card = const Color(0xFF1E3426);
        AppColors.cardLight = const Color(0xFF284230);
        AppColors.accent = const Color(0xFF6A997D);
        AppColors.accentLight = const Color(0xFFB8E0D2); // Pastel Green
        AppColors.todayBorder = const Color(0xFFB8E0D2);
        AppColors.divider = const Color(0xFF304F3A);
        break;

      case AppThemeType.monochromeBlack:
        AppColors.background = const Color(0xFF000000);
        AppColors.surface = const Color(0xFF0A0A0A);
        AppColors.card = const Color(0xFF141414);
        AppColors.cardLight = const Color(0xFF1E1E1E);
        AppColors.accent = const Color(0xFF666666);
        AppColors.accentLight = const Color(0xFFE0E0E0);
        AppColors.todayBorder = const Color(0xFFE0E0E0);
        AppColors.divider = const Color(0xFF2C2C2C);
        break;

      case AppThemeType.monochromeWhite:
        AppColors.background = const Color(0xFF121212);
        AppColors.surface = const Color(0xFF1C1C1C);
        AppColors.card = const Color(0xFF262626);
        AppColors.cardLight = const Color(0xFF333333);
        AppColors.accent = const Color(0xFFA3A3A3);
        AppColors.accentLight = const Color(0xFFFFFFFF);
        AppColors.todayBorder = const Color(0xFFFFFFFF);
        AppColors.divider = const Color(0xFF404040);
        break;

      case AppThemeType.monochromeGray:
        AppColors.background = const Color(0xFF161618);
        AppColors.surface = const Color(0xFF202023);
        AppColors.card = const Color(0xFF2A2A2E);
        AppColors.cardLight = const Color(0xFF36363B);
        AppColors.accent = const Color(0xFF6D6D75);
        AppColors.accentLight = const Color(0xFFB0B0B8);
        AppColors.todayBorder = const Color(0xFFB0B0B8);
        AppColors.divider = const Color(0xFF43434A);
        break;
    }
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
    }
  }
}
