import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../presentation/pages/manager_panel_page.dart';
import '../../../settings/presentation/pages/global_settings_page.dart';

class ManagerDrawer extends StatelessWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final StorageService storage;

  const ManagerDrawer({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    final isTr = lang.currentLang == 'tr';
    
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.card,
            ),
            accountName: Text(
              currentUser.fullName,
              style: const TextStyle(
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
                style: const TextStyle(
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
                _buildSectionTitle(isTr ? 'Yönetici Araçları' : 'Manager Tools'),
                
                ListTile(
                  leading: const Icon(Icons.dashboard_rounded, color: AppColors.textSecondary),
                  title: Text(isTr ? 'Yönetici Paneli' : 'Manager Panel', style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(isTr ? 'Sayımlar ve Personeller' : 'Counts and Staff', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManagerPanelPage(
                          currentUser: currentUser,
                          storage: storage,
                          lang: lang,
                          onLogout: () {},
                        ),
                      ),
                    );
                  },
                ),
                
                if (currentUser.isOwner) ...[
                  const Divider(color: AppColors.divider),
                  _buildSectionTitle(isTr ? 'Sistem Araçları' : 'System Tools'),
                  
                  ListTile(
                    leading: const Icon(Icons.settings_suggest_rounded, color: AppColors.textSecondary),
                    title: Text(isTr ? 'Genel Ücret Ayarları' : 'Global Wage Settings', style: const TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GlobalSettingsPage(lang: lang),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          
          const Divider(color: AppColors.divider),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text(isTr ? 'Çıkış Yap' : 'Logout', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              await AuthService().logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.accentLight,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
