import 'package:daytrack/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/manager_drawer.dart';
import '../../../../features/home/presentation/widgets/custom_top_bar.dart';
import 'manager_panel_page.dart';
import '../../../../core/theme/theme_service.dart';

class EditProfilesPage extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final StorageService storage;
  final ThemeService themeService;
  final bool isEmbedded;

  const EditProfilesPage({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.storage,
    required this.themeService,
    this.isEmbedded = false,
  });

  @override
  State<EditProfilesPage> createState() => _EditProfilesPageState();
}

class _EditProfilesPageState extends State<EditProfilesPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  List<AppUser> _allUsers = [];
  AppUser? _selectedUser;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  UserRole _selectedRole = UserRole.staff;

  @override
  void initState() {
    super.initState();
    widget.storage.setLastPanel('edit_profiles');
    _loadUsers();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _authService.getUsersByRole(UserRole.staff);
      final managers = await _authService.getUsersByRole(UserRole.manager);
      final owners = await _authService.getUsersByRole(UserRole.owner);
      
      final Map<String, AppUser> uniqueUsers = {};
      for (var u in [...snapshot, ...managers, ...owners]) {
        uniqueUsers[u.id] = u;
      }
      
      if (mounted) {
        setState(() {
          _allUsers = uniqueUsers.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onUserSelected(AppUser? user) {
    setState(() {
      _selectedUser = user;
      if (user != null) {
        _fullNameController.text = user.fullName;
        _usernameController.text = user.username;
        _passwordController.text = user.password ?? '';
        _phoneController.text = user.phone ?? '';
        _addressController.text = user.address ?? '';
        _selectedRole = user.roles.isNotEmpty ? user.roles.first : UserRole.staff;
        _errorMessage = null;
      }
    });
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate() || _selectedUser == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final username = _usernameController.text.trim().toLowerCase();

      if (username != _selectedUser!.username) {
        final taken = await _authService.isUsernameTaken(username);
        if (taken) {
          setState(() {
            _errorMessage = widget.lang.tr('username_taken');
            _isSaving = false;
          });
          return;
        }
      }

      await _authService.updateUserAdmin(
        uid: _selectedUser!.id,
        fullName: _fullNameController.text.trim(),
        username: username,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        roles: [_selectedRole],
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      );

      // Refresh user list
      await _loadUsers();

      if (mounted) {
        final isTr = widget.lang.currentLang == 'tr';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.get('user_details_updated', isTr ? 'tr' : 'en'),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.card,
          ),
        );
        setState(() {
          _isSaving = false;
          _selectedUser = _allUsers.firstWhere((u) => u.id == _selectedUser!.id);
        });
      }
    } catch (e) {
      if (mounted) {
        final isTr = widget.lang.currentLang == 'tr';
        setState(() {
          _errorMessage = AppStrings.get('an_error_occurred_during_update', isTr ? 'tr' : 'en');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';

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
              Icon(Icons.manage_accounts_rounded, color: AppColors.accentLight),
              const SizedBox(width: 8),
              Text(
                AppStrings.get('edit_profiles', isTr ? 'tr' : 'en'),
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.accentLight))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildLabel(AppStrings.get('select_user', isTr ? 'tr' : 'en')),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AppUser?>(
                        isExpanded: true,
                        hint: Text(
                          AppStrings.get('select_a_person', isTr ? 'tr' : 'en'),
                          style: TextStyle(color: AppColors.textHint),
                        ),
                        value: _selectedUser,
                        dropdownColor: AppColors.card,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        items: _allUsers.map((user) {
                          return DropdownMenuItem<AppUser?>(
                            value: user,
                            child: Text(
                              '${user.fullName} (@${user.username})',
                              style: GoogleFonts.inter(color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: _onUserSelected,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_selectedUser != null)
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(AppStrings.get('full_name', isTr ? 'tr' : 'en')),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _fullNameController,
                            hintText: AppStrings.get('e_g_john_doe', isTr ? 'tr' : 'en'),
                            icon: Icons.badge_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty) ? (AppStrings.get('required', isTr ? 'tr' : 'en')) : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(AppStrings.get('username', isTr ? 'tr' : 'en')),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _usernameController,
                            hintText: 'ahmet.yilmaz',
                            icon: Icons.alternate_email_rounded,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._]')),
                              LengthLimitingTextInputFormatter(30),
                            ],
                            validator: (v) => (v == null || v.trim().length < 3) ? (AppStrings.get('min_3_chars', isTr ? 'tr' : 'en')) : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(AppStrings.get('phone_number', isTr ? 'tr' : 'en')),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _phoneController,
                            hintText: AppStrings.get('e_g_05551234567', isTr ? 'tr' : 'en'),
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(AppStrings.get('address', isTr ? 'tr' : 'en')),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _addressController,
                            hintText: AppStrings.get('for_service_route', isTr ? 'tr' : 'en'),
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(AppStrings.get('password', isTr ? 'tr' : 'en')),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: AppStrings.get('set_new_password', isTr ? 'tr' : 'en'),
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) => (v != null && v.isNotEmpty && v.length < 6) ? (AppStrings.get('min_6_chars', isTr ? 'tr' : 'en')) : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(AppStrings.get('role', isTr ? 'tr' : 'en')),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<UserRole>(
                                isExpanded: true,
                                value: _selectedRole,
                                dropdownColor: AppColors.card,
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                                items: [
                                  DropdownMenuItem(value: UserRole.staff, child: Text(AppStrings.get('staff', isTr ? 'tr' : 'en'), style: GoogleFonts.inter(color: AppColors.textPrimary))),
                                  DropdownMenuItem(value: UserRole.manager, child: Text(AppStrings.get('manager', isTr ? 'tr' : 'en'), style: GoogleFonts.inter(color: AppColors.textPrimary))),
                                  DropdownMenuItem(value: UserRole.owner, child: Text(AppStrings.get('owner', isTr ? 'tr' : 'en'), style: GoogleFonts.inter(color: AppColors.textPrimary))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedRole = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_errorMessage != null)
                            Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(_errorMessage!, style: TextStyle(color: AppColors.danger)),
                            ),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _handleUpdate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentLight,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : Text(AppStrings.get('update', isTr ? 'tr' : 'en'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
