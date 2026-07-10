import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/user_list_tab.dart';

/// Yönetici Paneli — Tab yapısı
/// Owner: Yönetici Yönetimi + Personel Yönetimi + Sayımlar
/// Manager: Personel Yönetimi + Sayımlar
class ManagerPanelPage extends StatefulWidget {
  final AppUser currentUser;
  final StorageService storage;
  final LanguageService lang;
  final VoidCallback onLogout;

  const ManagerPanelPage({
    super.key,
    required this.currentUser,
    required this.storage,
    required this.lang,
    required this.onLogout,
  });

  @override
  State<ManagerPanelPage> createState() => _ManagerPanelPageState();
}

class _ManagerPanelPageState extends State<ManagerPanelPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    final tabCount = widget.currentUser.isOwner ? 3 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          widget.lang.tr('logout'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          widget.lang.tr('logout_confirm'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.lang.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(widget.lang.tr('logout')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final isTr = widget.lang.currentLang == 'tr';
    final roleText = widget.currentUser.isOwner
        ? (isTr ? 'Sahip' : 'Owner')
        : (isTr ? 'Yönetici' : 'Manager');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
          child: Row(
            children: [
              // App ikon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.accentLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              // Kullanıcı bilgisi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.currentUser.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      roleText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentLight.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Çıkış butonu
              IconButton(
                onPressed: _handleLogout,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final isTr = widget.lang.currentLang == 'tr';

    final tabs = <Widget>[];

    if (widget.currentUser.isOwner) {
      tabs.add(Tab(
        icon: const Icon(Icons.supervisor_account_rounded, size: 20),
        text: isTr ? 'Yöneticiler' : 'Managers',
      ));
    }

    tabs.add(Tab(
      icon: const Icon(Icons.people_rounded, size: 20),
      text: isTr ? 'Personel' : 'Staff',
    ));

    tabs.add(Tab(
      icon: const Icon(Icons.inventory_2_rounded, size: 20),
      text: isTr ? 'Sayımlar' : 'Counts',
    ));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.accentLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.accentLight,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: tabs,
      ),
    );
  }

  Widget _buildTabContent() {
    final views = <Widget>[];

    // Owner: Yönetici listesi sekmesi
    if (widget.currentUser.isOwner) {
      views.add(UserListTab(
        currentUser: widget.currentUser,
        lang: widget.lang,
        targetRole: UserRole.manager,
      ));
    }

    // Personel listesi sekmesi
    views.add(UserListTab(
      currentUser: widget.currentUser,
      lang: widget.lang,
      targetRole: UserRole.staff,
    ));

    // Sayımlar sekmesi (Adım 7'de doldurulacak)
    views.add(_buildComingSoon());

    return TabBarView(
      controller: _tabController,
      children: views,
    );
  }

  Widget _buildComingSoon() {
    final isTr = widget.lang.currentLang == 'tr';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            isTr ? 'Yakında...' : 'Coming soon...',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
