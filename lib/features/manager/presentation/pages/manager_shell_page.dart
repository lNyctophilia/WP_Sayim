import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/theme_service.dart';
import '../../../../features/home/presentation/widgets/custom_top_bar.dart';
import '../widgets/manager_drawer.dart';

import 'manager_panel_page.dart';
import 'shuttle_panel_page.dart';
import 'export_sayim_page.dart';
import 'edit_profiles_page.dart';
import 'create_past_sayim_page.dart';
import '../../../settings/presentation/pages/global_settings_page.dart';
import 'deleted_users_calendar_page.dart';

class ManagerShellPage extends StatefulWidget {
  final AppUser currentUser;
  final StorageService storage;
  final LanguageService lang;
  final ThemeService themeService;
  final String initialPanel;
  final VoidCallback? onLogout;

  const ManagerShellPage({
    super.key,
    required this.currentUser,
    required this.storage,
    required this.lang,
    required this.themeService,
    this.initialPanel = 'manager',
    this.onLogout,
  });

  @override
  State<ManagerShellPage> createState() => ManagerShellPageState();
}

class ManagerShellPageState extends State<ManagerShellPage> {
  late String _currentPanel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  /// AppRouter'ın StreamBuilder'ından gelen en güncel kullanıcı verisi
  late AppUser _liveUser;

  @override
  void initState() {
    super.initState();
    _currentPanel = widget.initialPanel;
    _liveUser = widget.currentUser;
  }

  @override
  void didUpdateWidget(covariant ManagerShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Farklı kullanıcı geldi — state'i sıfırla
    if (oldWidget.currentUser.id != widget.currentUser.id) {
      _liveUser = widget.currentUser;
      return;
    }
    
    // Aynı kullanıcı ama veri değişmiş — yetki kontrolü yap
    final oldPermissions = Set<UserPermission>.from(_liveUser.permissions);
    final newPermissions = Set<UserPermission>.from(widget.currentUser.permissions);
    final permissionsChanged = !oldPermissions.containsAll(newPermissions) || 
                                !newPermissions.containsAll(oldPermissions);
    
    // _liveUser'ı güncelle (build() çağrılacak — setState gerekmez)
    _liveUser = widget.currentUser;
    
    // Yetki değişikliği olduysa drawer'ı otomatik aç
    if (permissionsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scaffoldKey.currentState != null) {
          _scaffoldKey.currentState!.openDrawer();
        }
      });
    }
  }

  void switchPanel(String panel) {
    setState(() {
      _currentPanel = panel;
    });
    widget.storage.setLastPanel(panel);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (_currentPanel != 'manager_denizli' && _currentPanel != 'manager_mugla') {
          switchPanel('manager_denizli');
        } else {
          // Zaten ana paneldeysek uygulamadan çıkış yap veya arka plana at.
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: ManagerDrawer(
          currentUser: _liveUser,
          lang: widget.lang,
          storage: widget.storage,
          themeService: widget.themeService,
          onPanelSelected: switchPanel,
        ),
        body: Column(
          children: [
            CustomTopBar(
              currentUser: _liveUser,
              lang: widget.lang,
              storage: widget.storage,
              themeService: widget.themeService,
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentPanel) {
      case 'shuttle':
        return ShuttlePanelPage(
          currentUser: _liveUser,
          storage: widget.storage,
          lang: widget.lang,
          themeService: widget.themeService,
          isEmbedded: true,
        );
      case 'export':
        return ExportSayimPage(
          currentUser: _liveUser,
          storage: widget.storage,
          lang: widget.lang,
          themeService: widget.themeService,
          isEmbedded: true,
        );
      case 'edit_profiles':
        if (_liveUser.hasAdminPermission) {
          return EditProfilesPage(
            currentUser: _liveUser,
            storage: widget.storage,
            lang: widget.lang,
            themeService: widget.themeService,
            isEmbedded: true,
          );
        }
        break;
      case 'create_past':
        if (_liveUser.hasAdminPermission) {
          return CreatePastSayimPage(
            currentUser: _liveUser,
            storage: widget.storage,
            lang: widget.lang,
            themeService: widget.themeService,
            isEmbedded: true,
          );
        }
        break;
      case 'global_settings':
        if (_liveUser.hasAdminPermission) {
          return GlobalSettingsPage(
            currentUser: _liveUser,
            storage: widget.storage,
            lang: widget.lang,
            themeService: widget.themeService,
            isEmbedded: true,
          );
        }
        break;
      case 'deleted_calendars':
        if (_liveUser.hasAdminPermission) {
          return DeletedUsersCalendarPage(
            currentUser: _liveUser,
            storage: widget.storage,
            lang: widget.lang,
            themeService: widget.themeService,
            isEmbedded: true,
          );
        }
        break;
      case 'manager_denizli':
        return ManagerPanelPage(
          currentUser: _liveUser,
          storage: widget.storage,
          lang: widget.lang,
          themeService: widget.themeService,
          targetCity: 'Denizli',
          onLogout: widget.onLogout ?? () {},
          isEmbedded: true,
        );
      case 'manager_mugla':
        return ManagerPanelPage(
          currentUser: _liveUser,
          storage: widget.storage,
          lang: widget.lang,
          themeService: widget.themeService,
          targetCity: 'Muğla',
          onLogout: widget.onLogout ?? () {},
          isEmbedded: true,
        );
      case 'manager':
      default:
        return ManagerPanelPage(
          currentUser: _liveUser,
          storage: widget.storage,
          lang: widget.lang,
          themeService: widget.themeService,
          targetCity: 'Denizli',
          onLogout: widget.onLogout ?? () {},
          isEmbedded: true,
        );
    }
    // Varsayılan
    return ManagerPanelPage(
      currentUser: _liveUser,
      storage: widget.storage,
      lang: widget.lang,
      themeService: widget.themeService,
      targetCity: 'Denizli',
      onLogout: widget.onLogout ?? () {},
      isEmbedded: true,
    );
  }
}
