import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_settings.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/settings_service.dart';

class GlobalSettingsPage extends StatefulWidget {
  final LanguageService lang;

  const GlobalSettingsPage({super.key, required this.lang});

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
            content: Text(widget.lang.currentLang == 'tr'
                ? 'Ayarlar başarıyla kaydedildi.'
                : 'Settings saved successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.lang.currentLang == 'tr'
                ? 'Hata: $e'
                : 'Error: $e'),
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
    final isTr = widget.lang.currentLang == 'tr';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          isTr ? 'Genel Ayarlar' : 'Global Settings',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
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
                      isTr ? 'Varsayılan Ücretler' : 'Default Wages',
                      style: const TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _staffIciCtrl,
                      label: isTr ? 'Personel (Şehir İçi)' : 'Staff (In-City)',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _staffDisiCtrl,
                      label: isTr
                          ? 'Personel (Şehir Dışı)'
                          : 'Staff (Out-of-City)',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _managerIciCtrl,
                      label: isTr ? 'Yönetici (Şehir İçi)' : 'Manager (In-City)',
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _managerDisiCtrl,
                      label: isTr
                          ? 'Yönetici (Şehir Dışı)'
                          : 'Manager (Out-of-City)',
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
                          isTr ? 'Kaydet' : 'Save',
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
