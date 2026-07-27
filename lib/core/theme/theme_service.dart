import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
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

      case AppThemeType.custom:
        final seedColor = Color(_storage.getCustomThemeColor());
        final isDark = seedColor.computeLuminance() < 0.5;
        final colorScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: isDark ? Brightness.dark : Brightness.light,
        );

        AppColors.background = colorScheme.surface;
        AppColors.surface = Color.lerp(colorScheme.surface, colorScheme.primary, 0.05)!;
        AppColors.card = Color.lerp(colorScheme.surface, colorScheme.primary, 0.08)!;
        AppColors.cardLight = Color.lerp(colorScheme.surface, colorScheme.primary, 0.12)!;
        AppColors.accent = colorScheme.primary;
        AppColors.accentLight = colorScheme.primaryContainer;
        AppColors.todayBorder = colorScheme.primary;
        AppColors.divider = colorScheme.outlineVariant;
        AppColors.textPrimary = colorScheme.onSurface;
        AppColors.textSecondary = colorScheme.onSurfaceVariant;
        AppColors.textHint = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
        AppColors.cityInner = colorScheme.secondary;
        AppColors.cityOuter = colorScheme.tertiary;
        break;
    }

    // Update the system overlay to match the background color
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
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
