import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/sayim_service.dart';
import '../pages/create_sayim_page.dart';
import '../pages/sayim_detail_page.dart';

class SayimListTab extends StatelessWidget {
  final AppUser currentUser;
  final LanguageService lang;

  const SayimListTab({
    super.key,
    required this.currentUser,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final isTr = lang.currentLang == 'tr';
    final sayimService = SayimService();

    return Stack(
      children: [
        StreamBuilder<List<Sayim>>(
          stream: sayimService.getSayimlar(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accentLight));
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    isTr ? 'Bir hata oluştu:\n${snapshot.error}' : 'An error occurred:\n${snapshot.error}',
                    style: const TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final sayimlar = snapshot.data ?? [];

            if (sayimlar.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 48,
                      color: AppColors.textHint.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isTr ? 'Henüz sayım bulunmuyor.' : 'No counts found yet.',
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

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: sayimlar.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sayim = sayimlar[index];
                return _buildSayimCard(context, sayim, isTr);
              },
            );
          },
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            backgroundColor: AppColors.accentLight,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateSayimPage(
                    currentUser: currentUser,
                    lang: lang,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildSayimCard(BuildContext context, Sayim sayim, bool isTr) {
    final bool isOpen = sayim.status == SayimStatus.open;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SayimDetailPage(
              sayim: sayim,
              currentUser: currentUser,
              lang: lang,
            ),
          ),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sayim.note.isNotEmpty
                      ? sayim.note
                      : (isTr ? 'İsimsiz Sayım' : 'Unnamed Count'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOpen ? AppColors.success : AppColors.textHint)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOpen
                      ? (isTr ? 'Açık' : 'Open')
                      : (isTr ? 'Kapalı' : 'Closed'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOpen ? AppColors.success : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${sayim.date.day.toString().padLeft(2, '0')}.${sayim.date.month.toString().padLeft(2, '0')}.${sayim.date.year}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.group_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${sayim.invitedUserIds.length}/${sayim.maxKisi + sayim.maxYonetici}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (sayim.invitedUserIds.length < (sayim.maxKisi + sayim.maxYonetici)) ...[
                const SizedBox(width: 6),
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
              ],
            ],
          ),
        ],
      ),
    ));
  }
}
