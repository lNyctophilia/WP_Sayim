import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class UrlHelper {
  UrlHelper._();

  /// Google Haritalar veya herhangi bir harita URL'sini harita uygulamasında açar
  static Future<void> openMapUrl(BuildContext context, String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;

    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    try {
      final uri = Uri.parse(cleanUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback: platform varsayılanı ile açmayı dene
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harita açılamadı: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
