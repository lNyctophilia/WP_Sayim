import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../presentation/pages/manager_panel_page.dart';
import '../../../settings/presentation/pages/global_settings_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../pages/edit_profiles_page.dart';
import '../pages/create_past_sayim_page.dart';
import '../pages/export_sayim_page.dart';

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

          // Profilleri Düzenle Butonu (Sadece Admin/Owner görebilir)
          if (currentUser.isOwner) ...[
            ListTile(
              leading: const Icon(Icons.manage_accounts_rounded, color: AppColors.accentLight),
              title: Text(isTr ? 'Profilleri Düzenle' : 'Edit Profiles', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilesPage(
                      currentUser: currentUser,
                      lang: lang,
                    ),
                  ),
                );
              },
            ),
            const Divider(color: AppColors.divider, height: 1),
          ],
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionTitle(isTr ? 'Personel Paneli' : 'Staff Panel'),
                
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded, color: AppColors.textSecondary),
                  title: Text(isTr ? 'Takvim / İş Takip' : 'Calendar / Dashboard', style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(isTr ? 'Personel Ana Ekranı' : 'Staff Home Screen', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomePage(
                          currentUser: currentUser,
                          storage: storage,
                          lang: lang,
                        ),
                      ),
                    );
                  },
                ),
                
                const Divider(color: AppColors.divider),
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
                    ).then((_) {
                      // Geri dönüldüğünde (örneğin ana sayfaya) paneli güncelle
                      storage.setLastPanel('home');
                    });
                  },
                ),
                
                if (currentUser.isOwner) ...[
                  const Divider(color: AppColors.divider),
                  _buildSectionTitle(isTr ? 'Sistem Araçları' : 'System Tools'),
                  
                  ListTile(
                    leading: const Icon(Icons.history_edu_rounded, color: AppColors.textSecondary),
                    title: Text(isTr ? 'Geçmiş Sayım Ekle' : 'Add Past Count', style: const TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePastSayimPage(
                            currentUser: currentUser,
                            lang: lang,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.settings_suggest_rounded, color: AppColors.textSecondary),
                    title: Text(isTr ? 'Genel Ücret Ayarları' : 'Global Wage Settings', style: const TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GlobalSettingsPage(
                            lang: lang,
                            currentUser: currentUser,
                            storage: storage,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.sim_card_download_rounded, color: AppColors.textSecondary),
                    title: Text(isTr ? 'Excel Çıktısı Al' : 'Export Excel', style: const TextStyle(color: AppColors.textPrimary)),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExportSayimPage(
                            lang: lang,
                          ),
                        ),
                      );
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
