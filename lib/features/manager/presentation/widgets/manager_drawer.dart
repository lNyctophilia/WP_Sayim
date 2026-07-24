import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/theme_service.dart';
import '../../presentation/pages/manager_panel_page.dart';
import '../../../settings/presentation/pages/global_settings_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../pages/edit_profiles_page.dart';
import '../pages/create_past_sayim_page.dart';
import '../pages/export_sayim_page.dart';
import '../pages/shuttle_panel_page.dart';

class ManagerDrawer extends StatelessWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final StorageService storage;
  final ThemeService themeService;
  final Function(String)? onPanelSelected;

  const ManagerDrawer({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.storage,
    required this.themeService,
    this.onPanelSelected,
  });

  @override
  Widget build(BuildContext context) {

    
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.card,
            ),
            accountName: Text(
              currentUser.fullName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              currentUser.roles.isNotEmpty ? currentUser.roles.first.name.toUpperCase() : 'STAFF',
              style: TextStyle(
                color: AppColors.accentLight.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.accentLight.withValues(alpha: 0.2),
              child: Text(
                currentUser.fullName.isNotEmpty ? currentUser.fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.accentLight,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),


          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (!currentUser.isOwner) ...[
                  _buildSectionTitle(lang.tr('staff_panel')),
                  
                  ListTile(
                    leading: Icon(Icons.calendar_month_rounded, color: AppColors.textSecondary),
                    title: Text(lang.tr('calendar_dashboard'), style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(lang.tr('staff_home'), style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => HomePage(
                            currentUser: currentUser,
                            storage: storage,
                            lang: lang,
                            themeService: themeService,
                          ),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                  
                  Divider(color: AppColors.divider),
                ],
                _buildSectionTitle(lang.tr('manager_tools')),
                
                ListTile(
                  leading: Icon(Icons.dashboard_rounded, color: AppColors.textSecondary),
                  title: Text(lang.tr('manager_panel'), style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(lang.tr('manager_panel_desc'), style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    if (onPanelSelected != null) {
                      onPanelSelected!('manager');
                    } else {
                      storage.setLastPanel('manager');
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => ManagerPanelPage(
                            currentUser: currentUser,
                            storage: storage,
                            lang: lang,
                            themeService: themeService,
                            onLogout: () {},
                          ),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.directions_bus_rounded, color: AppColors.textSecondary),
                  title: Text(lang.tr('shuttle_planning'), style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(lang.tr('shuttle_route_desc'), style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    if (onPanelSelected != null) {
                      onPanelSelected!('shuttle');
                    } else {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => ShuttlePanelPage(
                            currentUser: currentUser,
                            lang: lang,
                            storage: storage,
                            themeService: themeService,
                          ),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.table_view_rounded, color: AppColors.textSecondary),
                  title: Text(lang.tr('export_excel'), style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(lang.tr('export_reports'), style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    if (onPanelSelected != null) {
                      onPanelSelected!('export');
                    } else {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => ExportSayimPage(
                            lang: lang,
                            currentUser: currentUser,
                            storage: storage,
                            themeService: themeService,
                          ),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
                
                if (currentUser.isOwner) ...[
                  Divider(color: AppColors.divider),
                  _buildSectionTitle(lang.tr('system_tools')),

                  ListTile(
                    leading: Icon(Icons.manage_accounts_rounded, color: AppColors.textSecondary),
                    title: Text(lang.tr('edit_profiles'), style: TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      if (onPanelSelected != null) {
                        onPanelSelected!('edit_profiles');
                      } else {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => EditProfilesPage(
                              currentUser: currentUser,
                              lang: lang,
                              storage: storage,
                              themeService: themeService,
                            ),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      }
                    },
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.history_edu_rounded, color: AppColors.textSecondary),
                    title: Text(lang.tr('add_past_count'), style: TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      if (onPanelSelected != null) {
                        onPanelSelected!('create_past');
                      } else {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => CreatePastSayimPage(
                              currentUser: currentUser,
                              lang: lang,
                              storage: storage,
                              themeService: themeService,
                            ),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      }
                    },
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.settings_suggest_rounded, color: AppColors.textSecondary),
                    title: Text(lang.tr('global_wage_settings'), style: TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      if (onPanelSelected != null) {
                        onPanelSelected!('global_settings');
                      } else {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => GlobalSettingsPage(
                              lang: lang,
                              currentUser: currentUser,
                              storage: storage,
                              themeService: themeService,
                            ),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.accentLight,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
