import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/services/language_service.dart';
import 'package:url_launcher/url_launcher.dart';

class InstallPromptPage extends StatelessWidget {
  final LanguageService? lang;

  const InstallPromptPage({super.key, this.lang});

  Widget _buildPlatformSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> steps,
    String? warning,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: step.startsWith('✅')
                        ? AppColors.accentLight
                        : AppColors.textSecondary,
                    fontWeight:
                        step.startsWith('✅') ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              )),
          if (warning != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                warning,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFFA726),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _tr(String key, {String defaultText = ''}) {
    if (lang != null) {
      return lang!.tr(key);
    }
    return defaultText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_to_home_screen_rounded,
                      color: AppColors.accentLight,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _tr('install_guide_title', defaultText: 'Uygulamayı Ana Ekrana Ekle'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _tr('install_guide_subtitle', defaultText: 'Cihazınıza göre aşağıdaki adımları takip edin:'),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.divider, height: 32),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.video_library_rounded, color: const Color(0xFFFF0000), size: 24),
                              const SizedBox(width: 10),
                              Text(
                                'Kurulum Videosu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Uygulamayı telefonunuza nasıl kuracağınızı videolu olarak izleyebilirsiniz.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final url = AppConfig.installVideoUrl;
                                if (url.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Video linki henüz eklenmedi.'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                  return;
                                }
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                              label: const Text('YouTube\'da İzle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF0000),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPlatformSection(
                      icon: Icons.android_rounded,
                      iconColor: const Color(0xFF3DDC84),
                      title: _tr('install_android_title', defaultText: 'Android (Chrome)'),
                      steps: [
                        _tr('install_android_step1', defaultText: '1. Chrome\'da sağ üstteki üç nokta menüsüne (⋮) dokunun'),
                        _tr('install_android_step2', defaultText: '2. Biraz aşağı kaydırıp "Yükle ve kısayol oluştur" seçeneğine basın'),
                        _tr('install_android_step3', defaultText: '3. Açılan pencerede onaylayarak işlemi tamamlayın'),
                        _tr('install_android_step4', defaultText: '✅ Artık ana ekranınızda uygulama ikonu görünecek!'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildPlatformSection(
                      icon: Icons.apple_rounded,
                      iconColor: AppColors.textPrimary,
                      title: _tr('install_ios_title', defaultText: 'iOS (Safari)'),
                      steps: [
                        _tr('install_ios_step1', defaultText: '1. Safari\'nin alt menüsündeki Paylaş (⬆) ikonuna dokunun'),
                        _tr('install_ios_step2', defaultText: '2. Biraz aşağı kaydırıp gri listeden "Ana Ekrana Ekle"ye dokunun. (Eğer görünmüyorsa "Daha Fazla" seçeneği içinden bulabilirsiniz)'),
                        _tr('install_ios_step3', defaultText: '3. Açılan pencerede onaylayarak işlemi tamamlayın'),
                        _tr('install_ios_step4', defaultText: '✅ Artık ana ekranınızda uygulama ikonu görünecek!'),
                      ],
                      warning: _tr('install_ios_warning', defaultText: '⚠️ iOS 16.4 altı cihazlarda bildirim yerine e-posta gönderilir.'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
