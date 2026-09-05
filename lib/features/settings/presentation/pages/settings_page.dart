import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../../../main.dart';

/// Ayarlar Sayfası
class SettingsPage extends StatefulWidget {
  final StorageService storage;
  final LanguageService lang;
  final ThemeService themeService;

  const SettingsPage({
    super.key,
    required this.storage,
    required this.lang,
    required this.themeService,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static String get _appVersion => AppConfig.version;
  static String get _developerName => AppConfig.developerName;


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
          _buildReminderToggle(),
          _buildNotificationHelpTile(),

          const SizedBox(height: 24),

          // ─── Görünüm ───────────────────────────────────
          _buildSectionHeader(widget.lang.currentLang == 'tr' ? 'Görünüm' : 'Appearance'),
          _buildThemeTile(),

          const SizedBox(height: 24),

          // ─── Hesap ─────────────────────────────────────
          _buildLogoutTile(),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              widget.lang.currentLang == 'tr' ? 'Hesap' : 'Account',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accentLight,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _buildDeleteAccountTile(),

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
        style: TextStyle(
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
            child: Icon(
              Icons.language_rounded,
              color: AppColors.accentLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            widget.lang.tr('language'),
            style: TextStyle(
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

  Widget _buildThemeTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: AppColors.accentLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                widget.lang.currentLang == 'tr' ? 'Tema Rengi' : 'Theme Color',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Color pickerColor = widget.themeService.currentTheme == AppThemeType.custom 
                        ? Color(widget.storage.getCustomThemeColor()) 
                        : AppColors.accent;
                    bool? changed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: AppColors.card,
                          title: Text(
                            widget.lang.currentLang == 'tr' ? 'Renk Seç' : 'Pick Color',
                            style: TextStyle(color: AppColors.textPrimary)
                          ),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: pickerColor,
                              onColorChanged: (color) {
                                pickerColor = color;
                              },
                              pickerAreaHeightPercent: 0.8,
                              enableAlpha: false,
                              displayThumbColor: true,
                              paletteType: PaletteType.hsvWithHue,
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text(widget.lang.tr('cancel'), style: TextStyle(color: AppColors.textHint)),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              child: Text(widget.lang.tr('save') ?? 'Seç', style: TextStyle(color: AppColors.accentLight)),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        );
                      },
                    );
                    
                    if (changed == true && mounted) {
                      // ignore: deprecated_member_use
                      await widget.storage.setCustomThemeColor(pickerColor.value);
                      await widget.themeService.setTheme(AppThemeType.custom, forceUpdate: true);
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.color_lens_rounded),
                  label: Text(widget.lang.tr('pick_custom_color')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await widget.themeService.setTheme(AppThemeType.defaultDark);
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(widget.lang.currentLang == 'tr' ? 'Sıfırla' : 'Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          child: Icon(
            Icons.logout_rounded,
            color: AppColors.danger,
            size: 22,
          ),
        ),
        title: Text(
          widget.lang.tr('logout'),
          style: TextStyle(
            fontSize: 15,
            color: AppColors.danger,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
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
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: Text(
                widget.lang.tr('logout_confirm'),
                style: TextStyle(color: AppColors.textSecondary),
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
            // AppRouter on authStateChanges will automatically pop all pushed routes and show LoginPage.
            await AuthService().logout();
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountTile() {
    final authService = AuthService();
    final uid = authService.currentFirebaseUser?.uid;
    
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<AppUser?>(
      stream: authService.getUserDataStream(uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isSoftDeleted = user?.isSoftDeleted ?? false;
        
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
                color: isSoftDeleted 
                    ? AppColors.divider.withValues(alpha: 0.15)
                    : AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.person_remove_rounded,
                color: isSoftDeleted ? AppColors.textHint : AppColors.danger,
                size: 22,
              ),
            ),
            title: Text(
              widget.lang.tr('delete_account'),
              style: TextStyle(
                fontSize: 15,
                color: isSoftDeleted ? AppColors.textHint : AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: isSoftDeleted
                ? Text(
                    widget.lang.currentLang == 'tr'
                        ? 'Hesabınız yönetici tarafından silinmiştir. Ayın 16\'sında hesabınız kalıcı olarak kapatılacaktır.'
                        : 'Your account has been deleted by a manager. It will be permanently closed on the 16th.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.danger.withValues(alpha: 0.7),
                    ),
                  )
                : null,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: isSoftDeleted ? AppColors.textHint.withValues(alpha: 0.3) : AppColors.textHint,
            ),
            onTap: isSoftDeleted ? null : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    widget.lang.tr('delete_account'),
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    widget.lang.tr('delete_account_confirm'),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(widget.lang.tr('cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      child: Text(widget.lang.tr('delete')),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                final deleteAuthService = AuthService();
                final deleteUid = deleteAuthService.currentFirebaseUser?.uid;
                
                if (deleteUid != null) {
                  try {
                    AuthService.isDeletingAccount = true;
                    // Soft delete user (Firestore only)
                    await deleteAuthService.deleteUser(deleteUid);
                    
                    if (mounted) {
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48),
                          content: Text(
                            widget.lang.currentLang == 'tr' 
                              ? 'Hesabınız başarıyla silindi.' 
                              : 'Your account has been successfully deleted.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('OK', style: TextStyle(color: AppColors.accentLight)),
                            ),
                          ],
                        ),
                      );
                    }

                    // Popup kapandıktan sonra: önce stack temizle, sonra logout
                    AuthService.isDeletingAccount = false;
                    
                    // Stack'taki tüm sayfaları kapat (Settings, vb.)
                    if (appNavigatorKey.currentState?.canPop() ?? false) {
                      appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
                    }
                    
                    // Son olarak logout — AppRouter authStateChanges üzerinden LoginPage'e geçer
                    await deleteAuthService.logout();
                    
                  } catch (e) {
                    AuthService.isDeletingAccount = false;
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  }
                }
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReminderToggle() {
    final authService = AuthService();
    final uid = authService.currentFirebaseUser?.uid;
    
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<AppUser?>(
      stream: authService.getUserDataStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final user = snapshot.data!;
        
        final isOldIos = user.email != null && user.email!.isNotEmpty;
        final bool isEnabled = isOldIos ? false : user.sayimReminderEnabled;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SwitchListTile(
            activeThumbColor: isOldIos ? AppColors.textHint : AppColors.accentLight,
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOldIos 
                    ? AppColors.divider.withValues(alpha: 0.15) 
                    : AppColors.accentLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: isOldIos ? AppColors.textHint : AppColors.accentLight,
                size: 22,
              ),
            ),
            title: Text(
              widget.lang.tr('sayim_reminder'),
              style: TextStyle(
                fontSize: 15,
                color: isOldIos ? AppColors.textHint : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              isOldIos 
                  ? widget.lang.tr('device_not_supported')
                  : widget.lang.tr('reminder_desc'),
              style: TextStyle(
                fontSize: 12,
                color: isOldIos ? AppColors.danger.withValues(alpha: 0.7) : AppColors.textSecondary,
              ),
            ),
            value: isEnabled,
            onChanged: isOldIos ? null : (bool value) async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'sayimReminderEnabled': value});
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ayarlar kaydedilirken bir hata oluştu: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationHelpTile() {
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
          child: Icon(
            Icons.help_rounded,
            color: AppColors.accentLight,
            size: 22,
          ),
        ),
        title: Text(
          widget.lang.tr('notification_help'),
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          widget.lang.tr('click_for_solution'),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.accentLight,
          size: 24,
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) {
              return _NotificationHelpSheet(
                lang: widget.lang,
              );
            },
          );
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
            child: Icon(
              Icons.calendar_month_rounded,
              color: AppColors.accentLight,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'WP Sayım',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.lang.tr('version')} $_appVersion',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          Text(
            _developerName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.accentLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© ${DateTime.now().year} · ${widget.lang.tr('all_rights_reserved')}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationHelpSheet extends StatefulWidget {
  final LanguageService lang;

  const _NotificationHelpSheet({required this.lang});

  @override
  State<_NotificationHelpSheet> createState() => _NotificationHelpSheetState();
}

class _NotificationHelpSheetState extends State<_NotificationHelpSheet> {
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTest() async {
    setState(() {
      _countdown = 5;
    });

    // Send notification trigger immediately
    final uid = AuthService().currentFirebaseUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('test_notifications').add({
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error triggering test notification: $e');
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Text(
            widget.lang.currentLang == 'tr' ? 'Bildirim Sorunu Çözümü' : 'Notification Issue Fix',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Adım 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '1',
                  style: TextStyle(
                    color: AppColors.accentLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lang.currentLang == 'tr' ? 'Yöneticinize Danışın' : 'Consult Your Manager',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.lang.currentLang == 'tr' 
                          ? 'Bildirim ayarlarınızla ilgili sorun yaşıyorsanız, cihaz ayarlarınızı kontrol edebilir veya yöneticinizle iletişime geçebilirsiniz.' 
                          : 'If you are experiencing issues with notification settings, you can check your device settings or contact your manager.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Divider(color: AppColors.divider),
          const SizedBox(height: 24),
          
          // Adım 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '2',
                  style: TextStyle(
                    color: AppColors.accentLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lang.currentLang == 'tr' ? 'Test Et' : 'Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.lang.currentLang == 'tr'
                          ? 'Alttaki butona bastıktan birkaç saniye içinde bildirim gelecek. Bu süre içinde uygulamadan tamamen çıkıp bildirimleri test edebilirsiniz.'
                          : 'A notification will be sent within a few seconds after pressing the button below. You can completely exit the app during this time to test notifications.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _countdown > 0 ? null : _startTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentLight,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.divider,
                          disabledForegroundColor: AppColors.textHint,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _countdown > 0 
                              ? '$_countdown ${widget.lang.currentLang == 'tr' ? 'saniye...' : 'seconds...'}' 
                              : (widget.lang.currentLang == 'tr' ? 'Test Et' : 'Test'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
