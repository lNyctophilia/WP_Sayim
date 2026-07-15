import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/services/davet_service.dart';
import '../../../staff/presentation/pages/invitations_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/language_service.dart';

class CustomTopBar extends StatelessWidget {
  final AppUser? currentUser;
  final LanguageService lang;
  final StorageService storage;
  
  const CustomTopBar({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    final hasDrawer = currentUser != null && (currentUser!.isOwner || currentUser!.isManager);
    final davetService = DavetService();
    
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
              // App ikon veya Drawer ikonu
              InkWell(
                onTap: hasDrawer ? () => Scaffold.of(context).openDrawer() : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasDrawer ? Icons.menu_rounded : Icons.calendar_month_rounded,
                    color: AppColors.accentLight,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: hasDrawer ? 30 : 10),
              // App isim — ayrı yazılış
              const Text(
                'WP Sayım',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              if (currentUser != null) ...[
                // Bildirim Butonu
                StreamBuilder<List<Davet>>(
                  stream: davetService.getDavetlerByUser(currentUser!.id),
                  builder: (context, snapshot) {
                    final pendingCount = snapshot.data
                            ?.where((d) => d.status == DavetStatus.pending)
                            .length ??
                        0;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => InvitationsPage(
                                  currentUser: currentUser!,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_rounded,
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
                        if (pendingCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                pendingCount > 9 ? '9+' : pendingCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 10),
                // Ayarlar butonu
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsPage(
                          lang: lang,
                          storage: storage,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.settings_rounded,
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
            ],
          ),
        ),
      ),
    );
  }
}
