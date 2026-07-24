import 'package:flutter/material.dart';

/// Koyu lacivert renk paleti — siyaha yakın, asil tonlar
class AppColors {
  AppColors._();

  // Ana arka planlar
  static Color background = Color(0xFF0A1128);
  static Color surface = Color(0xFF131D35);
  static Color card = Color(0xFF1B2845);
  static Color cardLight = Color(0xFF223354);

  // Vurgu / Accent
  static Color accent = Color(0xFF274472);
  static Color accentLight = Color(0xFF3A86FF);

  // Gün renkleri (takvim)
  static Color cityInner = Color(0xFF48BFE3); // Şehir içi — camgöbeği
  static Color cityOuter = Color(0xFFF9A826); // Şehir dışı — turuncu

  // Metin
  static Color textPrimary = Color(0xFFFFFFFF);
  static Color textSecondary = Color(0xFF8899AA);
  static Color textHint = Color(0xFF556677);

  // Durum renkleri
  static Color success = Color(0xFF06D6A0);
  static Color danger = Color(0xFFEF476F);
  static Color warning = Color(0xFFF9A826);

  // Bugünün vurgu rengi
  static Color todayBorder = Color(0xFF3A86FF);

  // Divider
  static Color divider = Color(0xFF1E3050);
}
