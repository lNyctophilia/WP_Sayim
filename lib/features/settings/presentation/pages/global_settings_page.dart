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
import '../../../../core/theme/theme_service.dart';

class GlobalSettingsPage extends StatefulWidget {
  final LanguageService lang;
  final AppUser currentUser;
  final StorageService storage;
  final ThemeService themeService;
  final bool isEmbedded;

  const GlobalSettingsPage({
    super.key,
    required this.lang,
    required this.currentUser,
    required this.storage,
    required this.themeService,
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
  late TextEditingController _managerA1IciCtrl;
  late TextEditingController _managerA1DisiCtrl;
  late TextEditingController _managerA2IciCtrl;
  late TextEditingController _managerA2DisiCtrl;
  late TextEditingController _managerA3IciCtrl;
  late TextEditingController _managerA3DisiCtrl;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.storage.setLastPanel('global_settings');
    _staffIciCtrl = TextEditingController();
    _staffDisiCtrl = TextEditingController();
    _managerA1IciCtrl = TextEditingController();
    _managerA1DisiCtrl = TextEditingController();
    _managerA2IciCtrl = TextEditingController();
    _managerA2DisiCtrl = TextEditingController();
    _managerA3IciCtrl = TextEditingController();
    _managerA3DisiCtrl = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getSettingsOnce();
    setState(() {
      _staffIciCtrl.text = settings.staffSehirIciWage.toString();
      _staffDisiCtrl.text = settings.staffSehirDisiWage.toString();
      _managerA1IciCtrl.text = settings.managerA1SehirIciWage.toString();
      _managerA1DisiCtrl.text = settings.managerA1SehirDisiWage.toString();
      _managerA2IciCtrl.text = settings.managerA2SehirIciWage.toString();
      _managerA2DisiCtrl.text = settings.managerA2SehirDisiWage.toString();
      _managerA3IciCtrl.text = settings.managerA3SehirIciWage.toString();
      _managerA3DisiCtrl.text = settings.managerA3SehirDisiWage.toString();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _staffIciCtrl.dispose();
    _staffDisiCtrl.dispose();
    _managerA1IciCtrl.dispose();
    _managerA1DisiCtrl.dispose();
    _managerA2IciCtrl.dispose();
    _managerA2DisiCtrl.dispose();
    _managerA3IciCtrl.dispose();
    _managerA3DisiCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newSettings = AppSettings(
        staffSehirIciWage: double.tryParse(_staffIciCtrl.text) ?? 0.0,
        staffSehirDisiWage: double.tryParse(_staffDisiCtrl.text) ?? 0.0,
        managerA1SehirIciWage: double.tryParse(_managerA1IciCtrl.text) ?? 0.0,
        managerA1SehirDisiWage: double.tryParse(_managerA1DisiCtrl.text) ?? 0.0,
        managerA2SehirIciWage: double.tryParse(_managerA2IciCtrl.text) ?? 0.0,
        managerA2SehirDisiWage: double.tryParse(_managerA2DisiCtrl.text) ?? 0.0,
        managerA3SehirIciWage: double.tryParse(_managerA3IciCtrl.text) ?? 0.0,
        managerA3SehirDisiWage: double.tryParse(_managerA3DisiCtrl.text) ?? 0.0,
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
              themeService: widget.themeService,
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
          CustomTopBar(
            currentUser: widget.currentUser, 
            lang: widget.lang, 
            storage: widget.storage,
            themeService: widget.themeService,
          ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.settings_rounded, color: AppColors.accentLight),
              SizedBox(width: 8),
              Text(
                widget.lang.tr('global_settings'),
                style: TextStyle(
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
                ? Center(
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
                      style: TextStyle(
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
                      controller: _managerA1IciCtrl,
                      label: widget.lang.tr('manager_a1_in_city'),
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _managerA1DisiCtrl,
                      label: widget.lang.tr('manager_a1_out_city'),
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _managerA2IciCtrl,
                      label: widget.lang.tr('manager_a2_in_city'),
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _managerA2DisiCtrl,
                      label: widget.lang.tr('manager_a2_out_city'),
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _managerA3IciCtrl,
                      label: widget.lang.tr('manager_a3_in_city'),
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _managerA3DisiCtrl,
                      label: widget.lang.tr('manager_a3_out_city'),
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
              themeService: widget.themeService,
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
          themeService: widget.themeService,
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
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.accentLight),
        suffixText: '₺',
        suffixStyle: TextStyle(color: AppColors.textHint),
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
