import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';

/// Yeni kullanıcı oluşturma dialog'u — Bottom sheet olarak açılır
class CreateUserDialog extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final UserRole targetRole;
  final VoidCallback onUserCreated;

  const CreateUserDialog({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.targetRole,
    required this.onUserCreated,
  });

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _wageController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final username = _usernameController.text.trim().toLowerCase();

      // Kullanıcı adı kontrolü
      final taken = await _authService.isUsernameTaken(username);
      if (taken) {
        setState(() {
          _errorMessage = widget.lang.tr('username_taken');
          _isLoading = false;
        });
        return;
      }

      final wage = double.tryParse(
          _wageController.text.replaceAll(',', '.'));

      await _authService.createUser(
        username: username,
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        roles: [widget.targetRole],
        createdByUid: widget.currentUser.id,
        defaultWage: wage,
      );

      // Oluşturan kişinin oturumunu tekrar aç
      // createUser mevcut oturumu kapatır (Firebase limitasyonu)
      // NOT: Bu workaround şifre gerektiriyor — daha uygun çözüm
      // Cloud Functions ile yapılacak. Şimdilik kullanıcı tekrar login olacak.

      if (mounted) {
        widget.onUserCreated();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.lang.tr('user_created_success'),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.card,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message;
        switch (e.code) {
          case 'email-already-in-use':
            message = widget.lang.tr('username_taken');
            break;
          case 'weak-password':
            message = widget.lang.tr('password_too_weak');
            break;
          default:
            message = widget.lang.tr('user_create_error');
        }
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = widget.lang.tr('user_create_error');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';
    final isManager = widget.targetRole == UserRole.manager;
    final title = isManager
        ? (isTr ? 'Yeni Yönetici' : 'New Manager')
        : (isTr ? 'Yeni Personel' : 'New Staff');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Çizgi tutamaç
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Başlık
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isManager
                          ? Icons.supervisor_account_rounded
                          : Icons.person_add_rounded,
                      color: AppColors.accentLight,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Ad Soyad
              _buildLabel(isTr ? 'Ad Soyad' : 'Full Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: isTr ? 'Örn: Ahmet Yılmaz' : 'e.g. John Doe',
                  prefixIcon: const Icon(Icons.badge_outlined,
                      color: AppColors.textSecondary, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isTr ? 'Ad soyad gerekli' : 'Full name required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kullanıcı Adı
              _buildLabel(isTr ? 'Kullanıcı Adı' : 'Username'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._]')),
                  LengthLimitingTextInputFormatter(30),
                ],
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: isTr ? 'Örn: ahmet.yilmaz' : 'e.g. john.doe',
                  prefixIcon: const Icon(Icons.alternate_email_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isTr
                        ? 'Kullanıcı adı gerekli'
                        : 'Username required';
                  }
                  if (value.trim().length < 3) {
                    return isTr
                        ? 'En az 3 karakter olmalı'
                        : 'At least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Şifre
              _buildLabel(isTr ? 'Şifre' : 'Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                textInputAction: TextInputAction.next,
                obscureText: _obscurePassword,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: isTr ? 'En az 6 karakter' : 'At least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isTr ? 'Şifre gerekli' : 'Password required';
                  }
                  if (value.length < 6) {
                    return isTr
                        ? 'En az 6 karakter olmalı'
                        : 'At least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Varsayılan Ücret (opsiyonel)
              _buildLabel(
                  isTr ? 'Varsayılan Ücret (opsiyonel)' : 'Default Wage (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _wageController,
                textInputAction: TextInputAction.done,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onFieldSubmitted: (_) => _handleCreate(),
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: isTr ? 'Örn: 1500' : 'e.g. 1500',
                  prefixIcon: const Icon(Icons.payments_outlined,
                      color: AppColors.textSecondary, size: 20),
                  prefixText: '₺ ',
                  prefixStyle: GoogleFonts.inter(
                    color: AppColors.accentLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Hata mesajı
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            color: AppColors.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Oluştur butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLight,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.accentLight.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isTr ? 'Oluştur' : 'Create',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
