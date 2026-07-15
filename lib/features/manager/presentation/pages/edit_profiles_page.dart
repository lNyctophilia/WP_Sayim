import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';

class EditProfilesPage extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;

  const EditProfilesPage({
    super.key,
    required this.currentUser,
    required this.lang,
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
  UserRole _selectedRole = UserRole.staff;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.getAllUsers();
      // If we also want to allow editing the current user (owner), 
      // getAllUsers() might filter out owners. 
      // Let's get them manually or use the current list.
      // Wait, getAllUsers() in auth_service excludes the owner currently.
      // Let's just fetch all active users if we need everyone.
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
      );

      // Refresh user list
      await _loadUsers();

      if (mounted) {
        final isTr = widget.lang.currentLang == 'tr';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTr ? 'Kullanıcı bilgileri güncellendi.' : 'User details updated.',
              style: const TextStyle(color: AppColors.textPrimary),
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
          _errorMessage = isTr ? 'Güncelleme sırasında bir hata oluştu.' : 'An error occurred during update.';
          _isSaving = false;
        });
      }
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isTr ? 'Profilleri Düzenle' : 'Edit Profiles',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentLight))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(isTr ? 'Kullanıcı Seçin' : 'Select User'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AppUser>(
                        isExpanded: true,
                        hint: Text(
                          isTr ? 'Bir kişi seçin' : 'Select a person',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                        value: _selectedUser,
                        dropdownColor: AppColors.card,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        items: _allUsers.map((user) {
                          return DropdownMenuItem<AppUser>(
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
                          _buildLabel(isTr ? 'Ad Soyad' : 'Full Name'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _fullNameController,
                            hintText: isTr ? 'Örn: Ahmet Yılmaz' : 'e.g. John Doe',
                            icon: Icons.badge_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty) ? (isTr ? 'Gerekli' : 'Required') : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(isTr ? 'Kullanıcı Adı' : 'Username'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _usernameController,
                            hintText: 'ahmet.yilmaz',
                            icon: Icons.alternate_email_rounded,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._]')),
                              LengthLimitingTextInputFormatter(30),
                            ],
                            validator: (v) => (v == null || v.trim().length < 3) ? (isTr ? 'En az 3 karakter' : 'Min 3 chars') : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(isTr ? 'Şifre' : 'Password'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: isTr ? 'Yeni şifre belirleyin' : 'Set new password',
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
                            validator: (v) => (v != null && v.isNotEmpty && v.length < 6) ? (isTr ? 'En az 6 karakter' : 'Min 6 chars') : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(isTr ? 'Rol' : 'Role'),
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
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                                items: [
                                  DropdownMenuItem(value: UserRole.staff, child: Text(isTr ? 'Personel' : 'Staff', style: GoogleFonts.inter(color: AppColors.textPrimary))),
                                  DropdownMenuItem(value: UserRole.manager, child: Text(isTr ? 'Yönetici' : 'Manager', style: GoogleFonts.inter(color: AppColors.textPrimary))),
                                  DropdownMenuItem(value: UserRole.owner, child: Text(isTr ? 'Sahip (Owner)' : 'Owner', style: GoogleFonts.inter(color: AppColors.textPrimary))),
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
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
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
                                  : Text(isTr ? 'Güncelle' : 'Update', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
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
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
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
