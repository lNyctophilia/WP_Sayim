import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/pwa_check.dart';
import '../../../../core/widgets/map_location_picker.dart';
import 'package:latlong2/latlong.dart';

class RegisterPage extends StatefulWidget {
  final LanguageService lang;

  const RegisterPage({
    super.key,
    required this.lang,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _requiresEmail = false;
  String? _errorMessage;
  double? _selectedLat;
  double? _selectedLng;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _requiresEmail = requiresEmailForNotifications();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Bildirim iznini yükleme ekranı başlamadan İLK BAŞTA iste.
      // Kullanıcı ile doğrudan etkileşim anı olduğu için PWA vs sorun çıkarmaz.
      final token = await NotificationService().getTokenForRegistration();
      
      String phone = _phoneController.text.trim();
      
      // Kullanıcı 10 haneli girerse (başında 0 olmadan), otomatik 0 ekle.
      if (phone.length == 10 && !phone.startsWith('0')) {
        phone = '0$phone';
      }

      await _authService.register(
        phone: phone,
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _selectedLat,
        longitude: _selectedLng,
        fcmToken: token,
        email: _requiresEmail ? _emailController.text.trim() : null,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48),
            content: Text(
              widget.lang.tr('register_success'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back to login page
                },
                child: Text('OK', style: TextStyle(color: AppColors.accentLight)),
              )
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'email-already-in-use') {
            _errorMessage = widget.lang.tr('username_taken');
          } else {
            _errorMessage = e.message ?? widget.lang.tr('user_create_error');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = widget.lang.tr('user_create_error');
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.lang.tr('register'),
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.lang.tr('register_subtitle'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),

                    _buildForm(),
                    const SizedBox(height: 16),

                    if (_errorMessage != null) _buildErrorMessage(),

                    const SizedBox(height: 24),

                    _buildRegisterButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _fullNameController,
            hintText: widget.lang.tr('full_name'),
            icon: Icons.person_outline_rounded,
            validator: (value) => (value == null || value.trim().isEmpty) ? widget.lang.tr('full_name_required') : null,
          ),
          const SizedBox(height: 14),

          _buildTextField(
            controller: _phoneController,
            hintText: widget.lang.tr('phone_number_hint'),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) => (value == null || value.trim().isEmpty) ? widget.lang.tr('phone_number_required') : null,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              widget.lang.tr('phone_note'),
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _addressController,
                  hintText: widget.lang.tr('address_hint'),
                  icon: Icons.location_on_outlined,
                  validator: (value) => (value == null || value.trim().isEmpty) ? widget.lang.tr('address_required') : null,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: Icon(Icons.map_outlined, color: AppColors.accentLight),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapLocationPicker(
                          lang: widget.lang,
                          initialLocation: _selectedLat != null && _selectedLng != null 
                              ? LatLng(_selectedLat!, _selectedLng!) 
                              : null,
                        ),
                      ),
                    );
                    
                    if (result != null && mounted) {
                      setState(() {
                        _addressController.text = result['address'] ?? '';
                        _selectedLat = result['latitude'];
                        _selectedLng = result['longitude'];
                      });
                    }
                  },
                  tooltip: widget.lang.tr('select_from_map'),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              widget.lang.tr('address_note'),
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 14),

          _buildTextField(
            controller: _passwordController,
            hintText: widget.lang.tr('login_password_hint'),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) => (value == null || value.isEmpty) ? widget.lang.tr('login_password_required') : null,
          ),

          if (_requiresEmail) ...[
            const SizedBox(height: 14),
            _buildTextField(
              controller: _emailController,
              hintText: 'E-posta (Bildirimler için gerekli)',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Cihazınız bildirimleri desteklemiyor. Bildirimler için e-posta zorunludur.';
                }
                if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                  return 'Geçerli bir e-posta adresi giriniz.';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                'Cihazınız (eski iOS sürümü vb.) yerleşik bildirimleri desteklemediği için sayım duyuruları e-posta olarak gönderilecektir.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 22),
        suffixIcon: suffixIcon,
        hintText: hintText,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
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
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accentLight.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                widget.lang.tr('register'),
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
