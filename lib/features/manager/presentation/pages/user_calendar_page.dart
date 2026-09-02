import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/language_service.dart';
import '../../../home/data/models/monthly_data.dart';
import '../../../home/data/models/work_day.dart';
import '../../../home/data/repositories/work_day_repository.dart';
import '../../../home/presentation/widgets/calendar_grid.dart';
import '../../../home/presentation/widgets/summary_card.dart';

class UserCalendarPage extends StatefulWidget {
  final AppUser selectedUser;
  final LanguageService lang;
  final int? initialYear;
  final int? initialMonth;

  const UserCalendarPage({
    super.key,
    required this.selectedUser,
    required this.lang,
    this.initialYear,
    this.initialMonth,
  });

  @override
  State<UserCalendarPage> createState() => _UserCalendarPageState();
}

class _UserCalendarPageState extends State<UserCalendarPage> with TickerProviderStateMixin {
  late WorkDayRepository _repository;
  late int _currentYear;
  late int _currentMonth;
  MonthlyData _monthlyData = MonthlyData.empty(2026, 1);
  bool _isLoading = true;
  StreamSubscription<MonthlyData>? _subscription;

  AnimationController? _slideController;
  late Animation<Offset> _inSlideAnimation;
  late Animation<Offset> _outSlideAnimation;
  late Animation<double> _inFadeAnimation;
  late Animation<double> _outFadeAnimation;

  int? _prevYear;
  int? _prevMonth;
  MonthlyData? _prevMonthlyData;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _repository = WorkDayRepository(userId: widget.selectedUser.id);
    _currentYear = widget.initialYear ?? DateTime.now().year;
    _currentMonth = widget.initialMonth ?? DateTime.now().month;
    _monthlyData = MonthlyData.empty(_currentYear, _currentMonth);
    _loadData();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _slideController?.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    _subscription?.cancel();
    final completer = Completer<void>();
    _subscription = _repository.getMonthlyDataStream(_currentYear, _currentMonth).listen((data) {
      if (mounted) {
        setState(() {
          _monthlyData = data;
          _isLoading = false;
        });
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  void _changeMonth(int direction) {
    if (_isAnimating) return;
    _prevYear = _currentYear;
    _prevMonth = _currentMonth;
    _prevMonthlyData = _monthlyData;
    if (direction == 1) {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    } else {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    }
    final originalTimeDilation = timeDilation;
    timeDilation = 1.0;
    _slideController?.dispose();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _inSlideAnimation = Tween<Offset>(
      begin: Offset(-direction.toDouble(), 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeOutCubic,
    ));
    _outSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(direction.toDouble(), 0),
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeInCubic,
    ));
    _inFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController!, curve: Curves.easeOut),
    );
    _outFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController!, curve: Curves.easeIn),
    );
    setState(() => _isAnimating = true);
    _loadData(silent: true);
    _slideController!.forward().then((_) {
      timeDilation = originalTimeDilation;
      if (mounted) {
        setState(() {
          _isAnimating = false;
          _prevMonthlyData = null;
          _prevYear = null;
          _prevMonth = null;
        });
      }
    });
  }

  void _previousMonth() => _changeMonth(1);
  void _nextMonth() => _changeMonth(-1);

  void _showNotePreview(DateTime date, WorkDay? existing) {
    HapticFeedback.mediumImpact();
    final hasEntry = existing != null;
    final hasNote = hasEntry && existing.displayNote.trim().isNotEmpty;
    final dayNames = widget.lang.currentLang == 'tr'
        ? ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']
        : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[date.weekday - 1];
    final monthName = widget.lang.monthName(date.month);
    final formattedDate = '${date.day} $monthName, $dayName';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasNote
                  ? AppColors.accentLight.withValues(alpha: 0.3)
                  : AppColors.textHint.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasNote ? Icons.sticky_note_2_rounded : Icons.event_note_rounded,
                      color: hasNote ? AppColors.accentLight : AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close_rounded, color: AppColors.textHint, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: hasNote
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (existing.isCityCenter ? AppColors.cityInner : AppColors.cityOuter).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    existing.isCityCenter ? widget.lang.tr('city_inner') : widget.lang.tr('city_outer'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: existing.isCityCenter ? AppColors.cityInner : AppColors.cityOuter,
                                    ),
                                  ),
                                ),
                                if (existing.payment > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${existing.payment.toInt()} ₺',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              existing.displayNote.trim(),
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            hasEntry ? Icons.note_outlined : Icons.event_busy_rounded,
                            color: AppColors.textHint,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasEntry ? widget.lang.tr('no_note') : widget.lang.tr('no_entry'),
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 14, color: AppColors.textHint),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.lang.currentLang == 'tr' ? 'İş Takvimi' : 'Work Calendar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accentLight))
          : Center(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadData();
                },
                color: AppColors.accentLight,
                backgroundColor: AppColors.card,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _isAnimating ? _buildAnimatedContent() : _buildStaticContent(),
                ),
              ),
            ),
    );
  }

  Widget _buildStaticContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGreeting(),
        _buildMonthNavigator(_currentYear, _currentMonth),
        const SizedBox(height: 16),
        CalendarGrid(
          year: _currentYear,
          month: _currentMonth,
          monthlyData: _monthlyData,
          lang: widget.lang,
          onDayTapped: _showNotePreview,
          onDayLongPressed: (date, existing) {},
        ),
        const SizedBox(height: 15),
        SummaryCard(
          totalDays: _monthlyData.totalDays,
          totalEarnings: _monthlyData.totalEarnings,
          lang: widget.lang,
        ),
        _buildRecentNotes(_monthlyData),
      ],
    );
  }

  Widget _buildAnimatedContent() {
    return Stack(
      children: [
        if (_prevMonthlyData != null)
          SlideTransition(
            position: _outSlideAnimation,
            child: FadeTransition(
              opacity: _outFadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(),
                  _buildMonthNavigator(_prevYear!, _prevMonth!),
                  const SizedBox(height: 16),
                  CalendarGrid(
                    year: _prevYear!,
                    month: _prevMonth!,
                    monthlyData: _prevMonthlyData!,
                    lang: widget.lang,
                    onDayTapped: _showNotePreview,
                    onDayLongPressed: (date, existing) {},
                  ),
                  const SizedBox(height: 15),
                  SummaryCard(
                    totalDays: _prevMonthlyData!.totalDays,
                    totalEarnings: _prevMonthlyData!.totalEarnings,
                    lang: widget.lang,
                  ),
                  _buildRecentNotes(_prevMonthlyData!),
                ],
              ),
            ),
          ),
        SlideTransition(
          position: _inSlideAnimation,
          child: FadeTransition(
            opacity: _inFadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(),
                _buildMonthNavigator(_currentYear, _currentMonth),
                const SizedBox(height: 16),
                CalendarGrid(
                  year: _currentYear,
                  month: _currentMonth,
                  monthlyData: _monthlyData,
                  lang: widget.lang,
                  onDayTapped: _showNotePreview,
                  onDayLongPressed: (date, existing) {},
                ),
                const SizedBox(height: 15),
                SummaryCard(
                  totalDays: _monthlyData.totalDays,
                  totalEarnings: _monthlyData.totalEarnings,
                  lang: widget.lang,
                ),
                _buildRecentNotes(_monthlyData),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigator(int year, int month) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 28),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentYear = DateTime.now().year;
                    _currentMonth = DateTime.now().month;
                  });
                  _loadData();
                },
                child: Column(
                  children: [
                    Text(
                      widget.lang.monthName(month),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '$year',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final String fullName = widget.selectedUser.fullName;
    final String firstName = fullName.trim().isNotEmpty ? fullName.trim().split(' ').first : '';
    final title = widget.lang.currentLang == 'tr' ? 'İş Takvimi ($firstName)' : 'Work Calendar ($firstName)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildRecentNotes(MonthlyData data) {
    final daysWithNotes = data.workDays.where((d) => d.displayNote.trim().isNotEmpty).toList();
    daysWithNotes.sort((a, b) => b.date.compareTo(a.date));

    final isTr = widget.lang.currentLang == 'tr';
    final title = isTr ? 'Son Rotalar' : 'Recent Routes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        if (daysWithNotes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              isTr ? 'Bu ay henüz rota eklenmedi.' : 'No routes added this month yet.',
              style: TextStyle(fontSize: 14, color: AppColors.textHint, fontStyle: FontStyle.italic),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: daysWithNotes.length,
              itemBuilder: (context, index) {
                final day = daysWithNotes[index];
                final monthName = widget.lang.monthName(day.date.month);
                final dateStr = '${day.date.day} $monthName';

                return Container(
                  width: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sticky_note_2_rounded, size: 14, color: AppColors.accentLight),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          if (day.payment > 0) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${day.payment.toInt()} ₺',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          day.displayNote.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
