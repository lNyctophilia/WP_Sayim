import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';
import 'create_user_dialog.dart';

/// Kullanıcı listesi sekmesi — Yönetici veya Personel listesi
/// [targetRole] ile hangi roldeki kullanıcıları göstereceğini belirler
class UserListTab extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final UserRole targetRole;

  const UserListTab({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.targetRole,
  });

  @override
  State<UserListTab> createState() => _UserListTabState();
}

class _UserListTabState extends State<UserListTab>
    with AutomaticKeepAliveClientMixin {
  final AuthService _authService = AuthService();
  List<AppUser> _users = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.getUsersByRole(widget.targetRole);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreateUserDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateUserDialog(
        currentUser: widget.currentUser,
        lang: widget.lang,
        targetRole: widget.targetRole,
        onUserCreated: _loadUsers,
      ),
    );
  }

  Future<void> _toggleUserActive(AppUser user) async {
    final isTr = widget.lang.currentLang == 'tr';
    final action = user.active
        ? (isTr ? 'devre dışı bırak' : 'deactivate')
        : (isTr ? 'aktif et' : 'activate');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          isTr
              ? 'Bu kullanıcıyı $action etmek istediğinize emin misiniz?'
              : 'Are you sure you want to $action this user?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.lang.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  user.active ? AppColors.danger : AppColors.success,
            ),
            child: Text(action.substring(0, 1).toUpperCase() +
                action.substring(1)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (user.active) {
        await _authService.deactivateUser(user.id);
      } else {
        await _authService.activateUser(user.id);
      }
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isTr = widget.lang.currentLang == 'tr';
    final isManagerList = widget.targetRole == UserRole.manager;
    final title = isManagerList
        ? (isTr ? 'Yöneticiler' : 'Managers')
        : (isTr ? 'Personel' : 'Staff');

    return Column(
      children: [
        // Başlık + Ekle butonu
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title (${_users.length})',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              // Ekleme butonu
              ElevatedButton.icon(
                onPressed: _showCreateUserDialog,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text(
                  isTr ? 'Ekle' : 'Add',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLight,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),

        // Liste
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentLight,
                  ),
                )
              : _users.isEmpty
                  ? _buildEmptyState(isTr, isManagerList)
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      color: AppColors.accentLight,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: _users.length,
                        itemBuilder: (context, index) =>
                            _buildUserCard(_users[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isTr, bool isManagerList) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isManagerList
                ? Icons.supervisor_account_rounded
                : Icons.people_outline_rounded,
            size: 56,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            isManagerList
                ? (isTr ? 'Henüz yönetici yok' : 'No managers yet')
                : (isTr ? 'Henüz personel yok' : 'No staff yet'),
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isTr
                ? 'Ekle butonuna basarak oluşturun'
                : 'Tap Add to create one',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textHint.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final isTr = widget.lang.currentLang == 'tr';
    final roleLabel = user.isOwner
        ? (isTr ? 'Sahip' : 'Owner')
        : user.isManager
            ? (isTr ? 'Yönetici' : 'Manager')
            : (isTr ? 'Personel' : 'Staff');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: user.active
            ? null
            : Border.all(
                color: AppColors.danger.withValues(alpha: 0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: user.active
                ? AppColors.accentLight.withValues(alpha: 0.15)
                : AppColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              user.fullName.isNotEmpty
                  ? user.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: user.active ? AppColors.accentLight : AppColors.danger,
              ),
            ),
          ),
        ),
        title: Text(
          user.fullName,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: user.active
                ? AppColors.textPrimary
                : AppColors.textHint,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '@${user.username}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: user.active
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.active
                    ? roleLabel
                    : (isTr ? 'Pasif' : 'Inactive'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: user.active ? AppColors.success : AppColors.danger,
                ),
              ),
            ),
          ],
        ),
        trailing: // Owner kendini deaktif edemez
            user.id != widget.currentUser.id
                ? IconButton(
                    icon: Icon(
                      user.active
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      color: user.active
                          ? AppColors.danger.withValues(alpha: 0.7)
                          : AppColors.success.withValues(alpha: 0.7),
                      size: 22,
                    ),
                    onPressed: () => _toggleUserActive(user),
                  )
                : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
