import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';

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
  List<AppUser> _approvedUsers = [];
  List<AppUser> _pendingUsers = [];
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
          _approvedUsers = users.where((u) => u.isApproved && !u.isOwner).toList();
          _pendingUsers = users.where((u) => !u.isApproved && !u.isOwner).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveUser(AppUser user) async {
    await _authService.approveUser(user.id);
    _loadUsers();
  }

  Future<void> _rejectUser(AppUser user) async {

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(user.fullName, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          widget.lang.tr('reject_delete_confirm'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(widget.lang.tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(widget.lang.tr('reject')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.rejectUser(user.id);
      _loadUsers();
    }
  }

  Future<void> _deleteUser(AppUser user) async {

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(user.fullName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Text(
          widget.lang.tr('delete_user_confirm'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(widget.lang.tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(widget.lang.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.deleteUser(user.id);
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isTr = widget.lang.currentLang == 'tr';
    final isManagerList = widget.targetRole == UserRole.manager;
    final title = isManagerList ? widget.lang.tr('managers') : widget.lang.tr('existing_staff');

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: AppColors.accentLight,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentLight))
          : CustomScrollView(
              slivers: [
                if (!isManagerList && _pendingUsers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                      child: Text(
                        '${widget.lang.tr('pending_approvals')} (${_pendingUsers.length})',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.warning),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPendingUserCard(_pendingUsers[index]),
                      childCount: _pendingUsers.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: AppColors.divider),
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                    child: Text(
                      '$title (${_approvedUsers.length})',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                ),
                _approvedUsers.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(isTr, isManagerList),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildUserCard(_approvedUsers[index]),
                          ),
                          childCount: _approvedUsers.length,
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(bool isTr, bool isManagerList) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isManagerList ? Icons.supervisor_account_rounded : Icons.people_outline_rounded,
            size: 56,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            isManagerList ? widget.lang.tr('no_managers_yet') : widget.lang.tr('no_staff_yet'),
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.textHint, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingUserCard(AppUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.warning),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(user.phone ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            if (user.address != null && user.address!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user.address!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectUser(user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(widget.lang.tr('reject')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveUser(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(widget.lang.tr('approve')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final canEdit = widget.currentUser.isOwner || widget.currentUser.isManager;
    final roleLabel = user.isOwner
        ? widget.lang.tr('role_owner')
        : user.isManager
            ? widget.lang.tr('role_manager')
            : widget.lang.tr('role_staff');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: user.active ? null : Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: user.active ? AppColors.accentLight.withValues(alpha: 0.15) : AppColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
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
            color: user.active ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              user.phone ?? '@${user.username}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: user.active ? AppColors.success.withValues(alpha: 0.15) : AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.active ? roleLabel : widget.lang.tr('inactive'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: user.active ? AppColors.success : AppColors.danger,
                ),
              ),
            ),
          ],
        ),
        trailing: (user.id != widget.currentUser.id && canEdit)
            ? IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: AppColors.danger.withValues(alpha: 0.7), size: 20),
                onPressed: () => _deleteUser(user),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
