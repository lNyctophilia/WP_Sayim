import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/user_list_tab.dart';
import '../widgets/sayim_list_tab.dart';
import '../../../../features/home/presentation/widgets/custom_top_bar.dart';
import '../widgets/manager_drawer.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
      drawer: ManagerDrawer(
        currentUser: widget.currentUser,
        lang: widget.lang,
        storage: widget.storage,
      ),
      body: Column(
        children: [
          CustomTopBar(currentUser: widget.currentUser, lang: widget.lang, storage: widget.storage),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }


  Widget _buildTabBar() {
    final isTr = widget.lang.currentLang == 'tr';

    final tabs = <Widget>[
      Tab(
        icon: const Icon(Icons.supervisor_account_rounded, size: 20),
        text: isTr ? 'Yöneticiler' : 'Managers',
      ),
      Tab(
        icon: const Icon(Icons.people_rounded, size: 20),
        text: isTr ? 'Personel' : 'Staff',
      ),
      Tab(
        icon: const Icon(Icons.inventory_2_rounded, size: 20),
        text: isTr ? 'Sayımlar' : 'Counts',
      ),
    ];

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
    final views = <Widget>[
      UserListTab(
        currentUser: widget.currentUser,
        lang: widget.lang,
        targetRole: UserRole.manager,
      ),
      UserListTab(
        currentUser: widget.currentUser,
        lang: widget.lang,
        targetRole: UserRole.staff,
      ),
      SayimListTab(
        currentUser: widget.currentUser,
        lang: widget.lang,
      ),
    ];

    return TabBarView(
      controller: _tabController,
      children: views,
    );
  }

}
