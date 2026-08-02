import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/sayim_service.dart';
import '../pages/create_sayim_page.dart';
import '../pages/sayim_detail_page.dart';

class SayimListTab extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;

  const SayimListTab({
    super.key,
    required this.currentUser,
    required this.lang,
  });

  @override
  State<SayimListTab> createState() => _SayimListTabState();
}

class _SayimListTabState extends State<SayimListTab> {
  late int _currentYear;
  late int _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
  }

  void _previousMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
  }

  Widget _buildMonthNavigator(int year, int month) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sol ok
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
            // Ay ve yıl — ortalanmış
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Bugünün ayına dön
                  setState(() {
                    final now = DateTime.now();
                    _currentYear = now.year;
                    _currentMonth = now.month;
                  });
                },
                child: Column(
                  children: [
                    Text(
                      widget.lang.monthName(month),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // Sağ ok
            IconButton(
              onPressed: _nextMonth,
              icon: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';
    final sayimService = SayimService();

    return Stack(
      children: [
        StreamBuilder<List<Sayim>>(
          stream: sayimService.getSayimlar(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: AppColors.accentLight));
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    widget.lang.tr('error_occurred') + '${snapshot.error}',
                    style: TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final allSayimlar = snapshot.data ?? [];
            final sayimlar = allSayimlar
                .where((s) =>
                    s.date.year == _currentYear &&
                    s.date.month == _currentMonth)
                .toList();

            return Column(
              children: [
                _buildMonthNavigator(_currentYear, _currentMonth),
                Expanded(
                  child: sayimlar.isEmpty
                      ? Center(
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
                                widget.lang.tr('no_counts_found'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textHint,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: sayimlar.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final sayim = sayimlar[index];
                            return _buildSayimCard(context, sayim, isTr);
                          },
                        ),
                ),
              ],
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
                    currentUser: widget.currentUser,
                    lang: widget.lang,
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
    final bool isOpen = sayim.effectiveStatus == SayimStatus.open;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SayimDetailPage(
              sayim: sayim,
              currentUser: widget.currentUser,
              lang: widget.lang,
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
                    (sayim.firmaAdi.isNotEmpty || sayim.note.isNotEmpty)
                        ? '${sayim.firmaAdi} ${sayim.note}'.trim()
                        : widget.lang.tr('unnamed_count'),
                    style: TextStyle(
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
                        ? widget.lang.tr('status_open')
                        : widget.lang.tr('status_closed'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOpen ? AppColors.success : AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${sayim.date.day.toString().padLeft(2, '0')}.${sayim.date.month.toString().padLeft(2, '0')}.${sayim.date.year}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.group_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${sayim.invitedUserIds.length}/${sayim.maxKisi + sayim.maxYonetici}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (sayim.invitedUserIds.length <
                    (sayim.maxKisi + sayim.maxYonetici)) ...[
                  SizedBox(width: 6),
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.warning),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
