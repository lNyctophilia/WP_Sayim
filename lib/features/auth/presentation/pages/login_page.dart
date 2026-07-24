import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/utils/pwa_check.dart';
import 'register_page.dart';

class LockoutException implements Exception {
  final String message;
  LockoutException(this.message);
  @override
  String toString() => message;
}

/// Login ekranı — kullanıcı adı + şifre ile giriş
class LoginPage extends StatefulWidget {
  final LanguageService lang;
  final void Function(String uid) onLoginSuccess;

  const LoginPage({
    super.key,
    required this.lang,
    required this.onLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkLockoutStatus(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntilStr = prefs.getString('login_locked_until_$username');
    if (lockedUntilStr != null) {
      final lockedUntil = DateTime.parse(lockedUntilStr);
      if (DateTime.now().isBefore(lockedUntil)) {
        final diff = lockedUntil.difference(DateTime.now());
        if (diff.inSeconds < 60) {
          throw LockoutException('Hesap kilitli. Lütfen ${diff.inSeconds} saniye sonra tekrar deneyin.');
        } else {
          final minutes = diff.inMinutes;
          throw LockoutException('Hesap kilitli. Lütfen $minutes dakika sonra tekrar deneyin.');
        }
      }
    }
  }

  Future<void> _handleFailedAttempt(String username) async {
    final prefs = await SharedPreferences.getInstance();
    int attempts = prefs.getInt('login_failed_attempts_$username') ?? 0;
    attempts++;
    await prefs.setInt('login_failed_attempts_$username', attempts);

    if (attempts >= 30) {
      int secondsToLock = 30 * (1 << ((attempts - 30) ~/ 2));
      if (secondsToLock > 86400) secondsToLock = 86400; // max 24 hours

      final lockedUntil = DateTime.now().add(Duration(seconds: secondsToLock));
      await prefs.setString('login_locked_until_$username', lockedUntil.toIso8601String());
      
      final lockMessage = secondsToLock < 60 
          ? '$secondsToLock saniye' 
          : '${secondsToLock ~/ 60} dakika';
      throw LockoutException('Çok fazla hatalı giriş. Hesap $lockMessage kilitlendi.');
    }
  }

  Future<void> _resetAttempts(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_failed_attempts_$username');
    await prefs.remove('login_locked_until_$username');
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim().toLowerCase();

    try {
      await _checkLockoutStatus(username);

      final user = await _authService.login(
        username,
        _passwordController.text,
      );

      if (user != null && mounted) {
        await _resetAttempts(username);
        widget.onLoginSuccess(user.id);
      } else if (mounted) {
        await _handleFailedAttempt(username);
        setState(() {
          _errorMessage = widget.lang.tr('login_failed');
        });
      }
    } on LockoutException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } on FirebaseAuthException catch (e) {
      try { await _handleFailedAttempt(username); } on LockoutException catch (le) {
        if (mounted) {
          setState(() {
            _errorMessage = le.message;
            _isLoading = false;
          });
        }
        return;
      }
      
      if (mounted) {
        String message;
        switch (e.code) {
          case 'user-not-found':
          case 'invalid-credential':
            message = widget.lang.tr('login_invalid_credentials');
            break;
          case 'wrong-password':
            message = widget.lang.tr('login_invalid_credentials');
            break;
          case 'user-disabled':
            message = widget.lang.tr('login_account_disabled');
            break;
          case 'not-approved':
            message = widget.lang.tr('pending_approval');
            break;
          case 'too-many-requests':
            message = widget.lang.tr('login_too_many_attempts');
            break;
          default:
            message = widget.lang.tr('login_error');
        }
        setState(() {
          _errorMessage = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = widget.lang.tr('login_error');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo / İkon
                    _buildLogo(),
                    const SizedBox(height: 12),

                    // Uygulama adı
                    Text(
                      'WP Sayım ${kIsWeb ? "W" : "N"}-${isMobileBrowser() ? "M" : "D"}-${isPWA() ? "P" : "B"}',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Alt başlık
                    Text(
                      widget.lang.tr('login_subtitle'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Form
                    _buildForm(),
                    const SizedBox(height: 16),

                    // Hata mesajı
                    if (_errorMessage != null) _buildErrorMessage(),

                    const SizedBox(height: 24),

                    // Giriş butonu
                    _buildLoginButton(),

                    const SizedBox(height: 16),

                    // Kayıt Ol butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.lang.tr('no_account'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RegisterPage(lang: widget.lang),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accentLight,
                          ),
                          child: Text(
                            widget.lang.tr('register'),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Alt bilgi
                    Text(
                      '© 2026 lNyctophilia',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentLight,
            AppColors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentLight.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Kullanıcı adı (Telefon numarası)
          TextFormField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            autocorrect: false,
            enableSuggestions: false,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              hintText: widget.lang.tr('login_username_hint'),
              filled: true,
              fillColor: AppColors.surface,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return widget.lang.tr('login_username_required');
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Şifre
          TextFormField(
            controller: _passwordController,
            textInputAction: TextInputAction.done,
            obscureText: _obscurePassword,
            onFieldSubmitted: (_) => _handleLogin(),
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              hintText: widget.lang.tr('login_password_hint'),
              filled: true,
              fillColor: AppColors.surface,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return widget.lang.tr('login_password_required');
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
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
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accentLight.withValues(alpha: 0.5),
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
                widget.lang.tr('login_button'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
