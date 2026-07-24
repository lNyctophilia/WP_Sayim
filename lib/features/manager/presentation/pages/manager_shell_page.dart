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

  @override
  void initState() {
    super.initState();
    _currentPanel = widget.initialPanel;
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
        if (_currentPanel != 'manager') {
          switchPanel('manager');
        } else {
          // Zaten ana paneldeysek uygulamadan çıkış yap veya arka plana at.
          // SystemNavigator.pop() çalışabilir, ancak Flutter Web'de hiçbir şey yapmaz.
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: ManagerDrawer(
          currentUser: widget.currentUser,
          lang: widget.lang,
          storage: widget.storage,
          themeService: widget.themeService,
          onPanelSelected: switchPanel,
        ),
        body: Column(
          children: [
            CustomTopBar(
              currentUser: widget.currentUser,
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
          currentUser: widget.currentUser,
          storage: widget.storage,
          lang: widget.lang,
          themeService: widget.themeService,
          isEmbedded: true,
        );
      case 'export':
        return ExportSayimPage(
          currentUser: widget.currentUser,
          storage: widget.storage,
          lang: widget.lang,
          themeService: widget.themeService,
          isEmbedded: true,
        );
      case 'edit_profiles':
        if (widget.currentUser.isOwner) {
          return EditProfilesPage(
            currentUser: widget.currentUser,
            storage: widget.storage,
            lang: widget.lang,
            themeService: widget.themeService,
            isEmbedded: true,
          );
        }
        break;
      case 'create_past':
        if (widget.currentUser.isOwner) {
          return CreatePastSayimPage(
            currentUser: widget.currentUser,
            storage: widget.storage,
            lang: widget.lang,
            themeService: widget.themeService,
            isEmbedded: true,
          );
        }
        break;
      case 'global_settings':
        if (widget.currentUser.isOwner) {
          return GlobalSettingsPage(
            currentUser: widget.currentUser,
            storage: widget.storage,
            lang: widget.lang,
            themeService: widget.themeService,
            isEmbedded: true,
          );
        }
        break;
      case 'manager':
      default:
        return ManagerPanelPage(
          currentUser: widget.currentUser,
          storage: widget.storage,
          lang: widget.lang,
          themeService: widget.themeService,
          onLogout: widget.onLogout ?? () {},
          isEmbedded: true,
        );
    }
    // Varsayılan
    return ManagerPanelPage(
      currentUser: widget.currentUser,
      storage: widget.storage,
      lang: widget.lang,
      themeService: widget.themeService,
      onLogout: widget.onLogout ?? () {},
      isEmbedded: true,
    );
  }
}
