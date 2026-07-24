import 'package:daytrack/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/user_list_tab.dart';
import '../widgets/sayim_list_tab.dart';
import '../../../../features/home/presentation/widgets/custom_top_bar.dart';
import '../widgets/manager_drawer.dart';
import '../../../../core/theme/theme_service.dart';

/// Yönetici Paneli — Tab yapısı
/// Owner: Yönetici Yönetimi + Personel Yönetimi + Sayımlar
/// Manager: Personel Yönetimi + Sayımlar
class ManagerPanelPage extends StatefulWidget {
  final AppUser currentUser;
  final StorageService storage;
  final LanguageService lang;
  final ThemeService themeService;
  final VoidCallback onLogout;
  final bool isEmbedded;

  const ManagerPanelPage({
    super.key,
    required this.currentUser,
    required this.storage,
    required this.lang,
    required this.themeService,
    required this.onLogout,
    this.isEmbedded = false,
  });

  @override
  State<ManagerPanelPage> createState() => _ManagerPanelPageState();
}

class _ManagerPanelPageState extends State<ManagerPanelPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.storage.getLastManagerTab();
    _tabController = TabController(
      initialIndex: initialIndex < 3 ? initialIndex : 0,
      length: 3,
      vsync: this,
    );
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.storage.setLastManagerTab(_tabController.index);
      }
    });
    
    // Panel state'ini kaydet
    widget.storage.setLastPanel('manager');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ManagerDrawer(
        currentUser: widget.currentUser,
        lang: widget.lang,
        storage: widget.storage,
        themeService: widget.themeService,
      ),
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(
              currentUser: widget.currentUser,
              lang: widget.lang,
              storage: widget.storage,
              themeService: widget.themeService,
            ),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }


  Widget _buildTabBar() {
    final isTr = widget.lang.currentLang == 'tr';

    final tabs = <Widget>[
      Tab(
        icon: const Icon(Icons.inventory_2_rounded, size: 20),
        text: AppStrings.get('counts', isTr ? 'tr' : 'en'),
      ),
      Tab(
        icon: const Icon(Icons.supervisor_account_rounded, size: 20),
        text: AppStrings.get('managers', isTr ? 'tr' : 'en'),
      ),
      Tab(
        icon: const Icon(Icons.people_rounded, size: 20),
        text: AppStrings.get('staff', isTr ? 'tr' : 'en'),
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
      SayimListTab(
        currentUser: widget.currentUser,
        lang: widget.lang,
      ),
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
    ];

    return TabBarView(
      controller: _tabController,
      children: views,
    );
  }

}
