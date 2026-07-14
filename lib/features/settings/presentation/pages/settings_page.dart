import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/router/app_router.dart';

/// Ayarlar Sayfası
class SettingsPage extends StatefulWidget {
  final StorageService storage;
  final LanguageService lang;

  const SettingsPage({
    super.key,
    required this.storage,
    required this.lang,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static String get _appVersion => AppConfig.version;
  static String get _developerName => AppConfig.developerName;

  void _showInstallGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tutma çubuğu
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_to_home_screen_rounded,
                      color: AppColors.accentLight,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.lang.tr('install_guide_title'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.lang.tr('install_guide_subtitle'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 24),
            // İçerik — kaydırılabilir
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Android Bölümü ───
                    _buildPlatformSection(
                      icon: Icons.android_rounded,
                      iconColor: const Color(0xFF3DDC84),
                      title: widget.lang.tr('install_android_title'),
                      steps: [
                        widget.lang.tr('install_android_step1'),
                        widget.lang.tr('install_android_step2'),
                        widget.lang.tr('install_android_step3'),
                        widget.lang.tr('install_android_step4'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ─── iOS Bölümü ───
                    _buildPlatformSection(
                      icon: Icons.apple_rounded,
                      iconColor: AppColors.textPrimary,
                      title: widget.lang.tr('install_ios_title'),
                      steps: [
                        widget.lang.tr('install_ios_step1'),
                        widget.lang.tr('install_ios_step2'),
                        widget.lang.tr('install_ios_step3'),
                        widget.lang.tr('install_ios_step4'),
                      ],
                      warning: widget.lang.tr('install_ios_warning'),
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
          // Platform başlığı
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Adımlar
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
          // iOS uyarısı
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lang.tr('settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ─── Genel ─────────────────────────────────────
          _buildSectionHeader(widget.lang.tr('general')),
          _buildLanguageTile(),
          _buildLogoutTile(),
          if (kIsWeb) _buildInstallGuideTile(),
          const SizedBox(height: 24),

          // ─── Hakkında ──────────────────────────────────
          _buildSectionHeader(widget.lang.tr('about')),
          _buildAboutSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.accentLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: AppColors.accentLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            widget.lang.tr('language'),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Dil seçici
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _buildLangChip('TR', 'tr'),
                _buildLangChip('EN', 'en'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String label, String langCode) {
    final isSelected = widget.lang.currentLang == langCode;
    return GestureDetector(
      onTap: () {
        widget.lang.setLanguage(langCode);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInstallGuideTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accentLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.add_to_home_screen_rounded,
            color: AppColors.accentLight,
            size: 22,
          ),
        ),
        title: Text(
          widget.lang.tr('install_guide'),
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textHint,
        ),
        onTap: _showInstallGuide,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: AppColors.danger,
            size: 22,
          ),
        ),
        title: Text(
          widget.lang.tr('logout'),
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.danger,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textHint,
        ),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                widget.lang.tr('logout'),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              content: Text(
                widget.lang.tr('logout_confirm'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(widget.lang.tr('cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: Text(widget.lang.tr('logout')),
                ),
              ],
            ),
          );

          if (confirmed == true && mounted) {
            // First log out
            await AuthService().logout();
            
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => AppRouter(
                    storage: widget.storage,
                    lang: widget.lang,
                  ),
                ),
                (route) => false,
              );
            }
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // App icon placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accentLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.accentLight,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'WP Sayim',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.lang.tr('version')} $_appVersion',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          Text(
            _developerName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.accentLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© ${DateTime.now().year} · ${widget.lang.tr('all_rights_reserved')}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
