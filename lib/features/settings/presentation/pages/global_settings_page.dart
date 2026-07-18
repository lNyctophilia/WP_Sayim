import 'package:daytrack/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_settings.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/storage_service.dart';
import '../../../home/presentation/widgets/custom_top_bar.dart';
import '../../../manager/presentation/widgets/manager_drawer.dart';
import '../../../manager/presentation/pages/manager_panel_page.dart';

class GlobalSettingsPage extends StatefulWidget {
  final LanguageService lang;
  final AppUser currentUser;
  final StorageService storage;
  final bool isEmbedded;

  const GlobalSettingsPage({
    super.key,
    required this.lang,
    required this.currentUser,
    required this.storage,
    this.isEmbedded = false,
  });

  @override
  State<GlobalSettingsPage> createState() => _GlobalSettingsPageState();
}

class _GlobalSettingsPageState extends State<GlobalSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final SettingsService _settingsService = SettingsService();

  late TextEditingController _staffIciCtrl;
  late TextEditingController _staffDisiCtrl;
  late TextEditingController _managerIciCtrl;
  late TextEditingController _managerDisiCtrl;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.storage.setLastPanel('global_settings');
    _staffIciCtrl = TextEditingController();
    _staffDisiCtrl = TextEditingController();
    _managerIciCtrl = TextEditingController();
    _managerDisiCtrl = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getSettingsOnce();
    setState(() {
      _staffIciCtrl.text = settings.staffSehirIciWage.toString();
      _staffDisiCtrl.text = settings.staffSehirDisiWage.toString();
      _managerIciCtrl.text = settings.managerSehirIciWage.toString();
      _managerDisiCtrl.text = settings.managerSehirDisiWage.toString();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _staffIciCtrl.dispose();
    _staffDisiCtrl.dispose();
    _managerIciCtrl.dispose();
    _managerDisiCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newSettings = AppSettings(
        staffSehirIciWage: double.tryParse(_staffIciCtrl.text) ?? 0.0,
        staffSehirDisiWage: double.tryParse(_staffDisiCtrl.text) ?? 0.0,
        managerSehirIciWage: double.tryParse(_managerIciCtrl.text) ?? 0.0,
        managerSehirDisiWage: double.tryParse(_managerDisiCtrl.text) ?? 0.0,
      );

      await _settingsService.updateSettings(newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('settings_saved', widget.lang.currentLang)),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ManagerPanelPage(
              currentUser: widget.currentUser,
              storage: widget.storage,
              lang: widget.lang,
              onLogout: () {},
            ),
            transitionDuration: Duration.zero,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('error_prefix', widget.lang.currentLang) + e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    Widget content = Column(
      children: [
        if (!widget.isEmbedded)
          CustomTopBar(currentUser: widget.currentUser, lang: widget.lang, storage: widget.storage),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.settings_rounded, color: AppColors.accentLight),
              const SizedBox(width: 8),
              Text(
                widget.lang.tr('global_settings'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accentLight))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lang.tr('default_wages'),
                      style: const TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _staffIciCtrl,
                      label: widget.lang.tr('staff_in_city'),
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _staffDisiCtrl,
                      label: widget.lang.tr('staff_out_city'),
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _managerIciCtrl,
                      label: widget.lang.tr('manager_in_city'),
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _managerDisiCtrl,
                      label: widget.lang.tr('manager_out_city'),
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.lang.tr('save'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

    if (widget.isEmbedded) {
      return content;
    }

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ManagerPanelPage(
              currentUser: widget.currentUser,
              storage: widget.storage,
              lang: widget.lang,
              onLogout: () {},
            ),
            transitionDuration: Duration.zero,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: ManagerDrawer(
          currentUser: widget.currentUser,
          lang: widget.lang,
          storage: widget.storage,
        ),
        body: SafeArea(child: content),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.accentLight),
        suffixText: '₺',
        suffixStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Boş bırakılamaz';
        if (double.tryParse(val) == null) return 'Geçersiz değer';
        return null;
      },
    );
  }
}
