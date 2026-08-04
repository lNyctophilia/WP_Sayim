import 'package:daytrack/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/davet_service.dart';
import '../../../../core/services/sayim_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/notification_service.dart';
import 'add_person_to_sayim_page.dart';
import 'edit_sayim_page.dart';

class SayimDetailPage extends StatefulWidget {
  final Sayim sayim;
  final AppUser currentUser;
  final LanguageService lang;

  const SayimDetailPage({
    super.key,
    required this.sayim,
    required this.currentUser,
    required this.lang,
  });

  @override
  State<SayimDetailPage> createState() => _SayimDetailPageState();
}

class _SayimDetailPageState extends State<SayimDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DavetService _davetService = DavetService();
  final AuthService _authService = AuthService();
  final SayimService _sayimService = SayimService();
  
  // Önbellek: Her seferinde Firestore'dan çekmemek için
  final Map<String, AppUser> _userCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<AppUser?> _getUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }
    final user = await _authService.getUserData(userId);
    if (user != null) {
      _userCache[userId] = user;
    }
    return user;
  }

  Future<void> _confirmDeleteSayim(List<Davet> davetler, Sayim currentSayim) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(AppStrings.get('delete_count', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentSayim.effectiveStatus == SayimStatus.open
                  ? AppStrings.get('are_you_sure_you_want_to_delete_this_count_and_all_related_invitations_calendar_records_this_action_cannot_be_undone', isTr ? 'tr' : 'en')
                  : AppStrings.get('delete_closed_count_msg', isTr ? 'tr' : 'en'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (currentSayim.effectiveStatus == SayimStatus.open) ...[
              const SizedBox(height: 12),
              Text(
                AppStrings.get('delete_open_count_warning', isTr ? 'tr' : 'en'),
                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.get('cancel', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.get('delete', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      }
      if (currentSayim.effectiveStatus == SayimStatus.open) {
        final NotificationService notificationService = NotificationService();
        final acceptedDavetler = davetler.where((d) => d.isAccepted).toList();
        for (final davet in acceptedDavetler) {
          final user = await _getUser(davet.userId);
          if (user != null && user.email != null && user.email!.isNotEmpty) {
            await notificationService.sendEmailNotification(
              targetUserId: davet.userId,
              subject: AppStrings.get('sayim_cancelled', isTr ? 'tr' : 'en') ?? 'Sayım İptali',
              textContent: 'Merhaba ${user.fullName},\n\nKabul ettiğiniz "${currentSayim.toplanmaYeri}" isimli sayım iptal edilmiştir.\n\nBilginize.',
            );
          }
        }
      }

      await _sayimService.deleteSayimFull(currentSayim.id, isSayimClosed: currentSayim.effectiveStatus == SayimStatus.closed);
      if (mounted) {
        Navigator.pop(context); // loading pop
        Navigator.pop(context); // page pop
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get('count_deleted_successfully', isTr ? 'tr' : 'en'))));
      }
    }
  }

  bool get isTr => widget.lang.currentLang == 'tr';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Sayim?>(
      stream: _sayimService.getSayimStream(widget.sayim.id),
      builder: (context, sayimSnapshot) {
        if (sayimSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.accentLight)),
          );
        }
        
        final currentSayim = sayimSnapshot.data;
        if (currentSayim == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(child: Text(AppStrings.get('count_not_found_or_deleted', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textSecondary))),
          );
        }

        return StreamBuilder<List<Davet>>(
          stream: _davetService.getDavetlerBySayim(currentSayim.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator(color: AppColors.accentLight)),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: Text(AppStrings.get('an_error_occurred', isTr ? 'tr' : 'en'))),
              );
            }

            final davetler = snapshot.data ?? [];
            final accepted = davetler.where((d) => d.isAccepted).toList();
            final pending = davetler.where((d) => d.isPending).toList();
            final declined = davetler.where((d) => d.isDeclined).toList();

            final activeDavetler = [...accepted, ...pending];
            int currentPersonel = activeDavetler.where((d) => d.role == DavetRole.staff).length;
            int currentYonetici = activeDavetler.where((d) => d.role == DavetRole.manager).length;
            
            int missingPersonel = currentSayim.maxKisi - currentPersonel;
            int missingYonetici = currentSayim.maxYonetici - currentYonetici;
            bool hasMissing = missingPersonel > 0 || missingYonetici > 0;

            return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppStrings.get('count_details', isTr ? 'tr' : 'en'),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              if (widget.currentUser.id == currentSayim.createdBy || widget.currentUser.isOwner) ...[
                if (currentSayim.effectiveStatus == SayimStatus.open)
                  IconButton(
                    icon: Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 20),
                    tooltip: AppStrings.get('close_count', isTr ? 'tr' : 'en'),
                    onPressed: () => _sayimService.closeSayim(currentSayim.id),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.lock_open_rounded, color: AppColors.success, size: 20),
                    tooltip: AppStrings.get('open_count', isTr ? 'tr' : 'en'),
                    onPressed: () => _sayimService.openSayim(currentSayim.id),
                  ),
                if (currentSayim.effectiveStatus == SayimStatus.open || widget.currentUser.isOwner)
                  IconButton(
                    icon: Icon(Icons.edit_rounded, color: AppColors.textPrimary, size: 20),
                    tooltip: AppStrings.get('edit', isTr ? 'tr' : 'en'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditSayimPage(
                            sayim: currentSayim,
                            existingDavets: davetler,
                            currentUser: widget.currentUser,
                            lang: widget.lang,
                          ),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.delete_rounded, color: AppColors.danger, size: 20),
                  tooltip: AppStrings.get('delete_count', isTr ? 'tr' : 'en'),
                  onPressed: () => _confirmDeleteSayim(davetler, currentSayim),
                ),
              ],
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.accentLight,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor: AppColors.accentLight,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: AppStrings.get('accepted', isTr ? 'tr' : 'en')),
                Tab(text: AppStrings.get('pending', isTr ? 'tr' : 'en')),
                Tab(text: AppStrings.get('declined', isTr ? 'tr' : 'en')),
              ],
            ),
          ),
          body: Column(
            children: [
              if (hasMissing)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.get('missing_people_prefix', isTr ? 'tr' : 'en') + (missingPersonel > 0 ? AppStrings.getFormat('missing_staff', isTr ? 'tr' : 'en', [missingPersonel]) : '') + (missingYonetici > 0 ? AppStrings.getFormat('missing_manager', isTr ? 'tr' : 'en', [missingYonetici]) : '') + (isTr ? ' eksik.' : ' missing.'),
                          style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDavetList(accepted, DavetStatus.accepted, currentSayim),
                    _buildDavetList(pending, DavetStatus.pending, currentSayim),
                    _buildDavetList(declined, DavetStatus.declined, currentSayim),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: ((widget.currentUser.id == currentSayim.createdBy || widget.currentUser.isOwner) && (currentSayim.effectiveStatus == SayimStatus.open || widget.currentUser.isOwner)) 
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.accentLight,
                foregroundColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPersonToSayimPage(
                        sayim: currentSayim,
                        currentUser: widget.currentUser,
                        lang: widget.lang,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_rounded),
                label: Text(AppStrings.get('add_person', isTr ? 'tr' : 'en')),
              ) 
            : null,
        );
          },
        );
      },
    );
  }

  Widget _buildDavetList(List<Davet> davetler, DavetStatus status, Sayim currentSayim) {
    if (davetler.isEmpty) {
      return Center(
        child: Text(
          AppStrings.get('no_one_found', isTr ? 'tr' : 'en'),
          style: TextStyle(color: AppColors.textHint),
        ),
      );
    }

    final isCreator = (widget.currentUser.id == currentSayim.createdBy || widget.currentUser.isOwner) && (currentSayim.effectiveStatus == SayimStatus.open || widget.currentUser.isOwner);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: davetler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final davet = davetler[index];
        return FutureBuilder<AppUser?>(
          future: _getUser(davet.userId),
          builder: (context, userSnapshot) {
            final userName = userSnapshot.data?.fullName ?? (AppStrings.get('loading', isTr ? 'tr' : 'en'));
            final grupAdi = currentSayim.gruplar.firstWhere((g) => g.grupId == davet.grupId, orElse: () => const SayimGrup(grupId: -1, saat: '')).saat;
            
            return Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.accentLight.withValues(alpha: 0.1),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(
                          color: AppColors.accentLight, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userSnapshot.data?.isDeleted == true ? '$userName (${AppStrings.get('deleted', isTr ? 'tr' : 'en')})' : userName,
                                style: TextStyle(
                                    color: userSnapshot.data?.isDeleted == true ? AppColors.danger : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    decoration: userSnapshot.data?.isDeleted == true ? TextDecoration.lineThrough : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (userSnapshot.hasData && userSnapshot.data != null && !userSnapshot.data!.isDeleted) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: userSnapshot.data!.isOwner 
                                      ? AppColors.danger.withValues(alpha: 0.1)
                                      : userSnapshot.data!.isManager 
                                          ? AppColors.accentLight.withValues(alpha: 0.1) 
                                          : AppColors.divider.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  userSnapshot.data!.isOwner 
                                      ? 'Admin' 
                                      : userSnapshot.data!.isManager 
                                          ? (AppStrings.get('manager', isTr ? 'tr' : 'en')) 
                                          : (AppStrings.get('staff', isTr ? 'tr' : 'en')),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: userSnapshot.data!.isOwner 
                                        ? AppColors.danger
                                        : userSnapshot.data!.isManager 
                                            ? AppColors.accentLight 
                                            : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${AppStrings.get('wage', isTr ? 'tr' : 'en')}: ₺${davet.ucret.toStringAsFixed(0)}${grupAdi.isNotEmpty ? ' • Saat: $grupAdi' : ''}',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (status == DavetStatus.pending && isCreator) ...[
                    IconButton(
                      icon: Icon(Icons.notifications_active_rounded,
                          color: AppColors.accentLight, size: 20),
                      tooltip: AppStrings.get('remind', isTr ? 'tr' : 'en'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.background,
                            title: Text(AppStrings.get('send_reminder_confirm_title', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary)),
                            content: Text(
                              AppStrings.get('send_reminder_confirm_msg', isTr ? 'tr' : 'en'),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(AppStrings.get('cancel', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textHint)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(AppStrings.get('remind', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.accentLight)),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;


                        // Cooldown: 5 dakika dolmadan tekrar hatırlatma atılmasını engelle
                        if (davet.lastReminderAt != null) {
                          final diff = DateTime.now().difference(davet.lastReminderAt!);
                          if (diff.inMinutes < 5) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppStrings.get('please_wait_5_minutes_before_sending_another_reminder', isTr ? 'tr' : 'en')),
                                  backgroundColor: AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            return;
                          }
                        }

                        await _davetService.updateLastReminder(davet.id);
                        
                        if (currentSayim.effectiveStatus == SayimStatus.open && userSnapshot.data != null && userSnapshot.data!.email != null && userSnapshot.data!.email!.isNotEmpty) {
                          final NotificationService _notificationService = NotificationService();
                          final sayimTarihi = "${currentSayim.date.day.toString().padLeft(2, '0')}.${currentSayim.date.month.toString().padLeft(2, '0')}.${currentSayim.date.year}";
                          await _notificationService.sendEmailNotification(
                            targetUserId: davet.userId,
                            subject: AppStrings.get('new_sayim_invitation', isTr ? 'tr' : 'en') ?? 'Yeni Sayım Daveti',
                            textContent: 'Merhaba ${userSnapshot.data!.fullName},\n\nYeni bir sayım için davet edildiniz!\n\nTarih: $sayimTarihi\nSaat: $grupAdi\nNot: ${currentSayim.note}\n\nLütfen uygulamaya girerek daveti yanıtlayın.',
                          );
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.get('reminder_sent', isTr ? 'tr' : 'en')),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.person_remove_rounded,
                          color: AppColors.danger, size: 20),
                      tooltip: AppStrings.get('cancel', isTr ? 'tr' : 'en'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.background,
                            title: Text(AppStrings.get('cancel_invitation_confirm_title', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary)),
                            content: Text(
                              AppStrings.get('cancel_invitation_confirm_msg', isTr ? 'tr' : 'en'),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(AppStrings.get('cancel', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textHint)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(AppStrings.get('cancel', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        await _davetService.deleteDavet(davet.id, isSayimClosed: currentSayim.effectiveStatus == SayimStatus.closed);
                        
                        // Remove from invitedUserIds
                        final updatedInvited = List<String>.from(currentSayim.invitedUserIds)..remove(davet.userId);
                        final updatedSayim = currentSayim.copyWith(invitedUserIds: updatedInvited);
                        await _sayimService.updateSayim(updatedSayim);
                      },
                    ),
                  ],
                  if (status == DavetStatus.accepted && isCreator) ...[
                    IconButton(
                      icon: Icon(Icons.person_remove_rounded,
                          color: AppColors.danger, size: 20),
                      tooltip: AppStrings.get('remove', isTr ? 'tr' : 'en'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.background,
                            title: Text(AppStrings.get('remove_person', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary)),
                            content: Text(
                              currentSayim.effectiveStatus == SayimStatus.open
                                  ? AppStrings.getFormat('are_you_sure_you_want_to_remove_username_from_this_count_a_cancellation_notification_will_be_sent_to_the_user', isTr ? 'tr' : 'en', [userName])
                                  : AppStrings.getFormat('are_you_sure_you_want_to_remove_username_from_this_count', isTr ? 'tr' : 'en', [userName]),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(AppStrings.get('cancel', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textHint)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(AppStrings.get('remove', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          if (currentSayim.effectiveStatus == SayimStatus.open && userSnapshot.data != null && userSnapshot.data!.email != null && userSnapshot.data!.email!.isNotEmpty) {
                            final NotificationService notificationService = NotificationService();
                            await notificationService.sendEmailNotification(
                              targetUserId: davet.userId,
                              subject: AppStrings.get('sayim_cancelled', isTr ? 'tr' : 'en') ?? 'Sayım İptali',
                              textContent: 'Merhaba ${userName},\n\nKabul ettiğiniz "${currentSayim.toplanmaYeri}" isimli sayımdan çıkarıldınız.\n\nBilginize.',
                            );
                          }

                          await _davetService.deleteDavet(davet.id, isSayimClosed: currentSayim.effectiveStatus == SayimStatus.closed);
                          
                          // Remove from invitedUserIds
                          final updatedInvited = List<String>.from(currentSayim.invitedUserIds)..remove(davet.userId);
                          final updatedSayim = currentSayim.copyWith(invitedUserIds: updatedInvited);
                          await _sayimService.updateSayim(updatedSayim);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppStrings.get(
                                  currentSayim.effectiveStatus == SayimStatus.open
                                      ? 'person_successfully_removed_and_notification_sent'
                                      : 'person_successfully_removed',
                                  isTr ? 'tr' : 'en'
                                )),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                  if (status == DavetStatus.declined && isCreator) ...[
                    IconButton(
                      icon: Icon(Icons.refresh_rounded,
                          color: AppColors.success, size: 20),
                      tooltip: AppStrings.get('re_invite', isTr ? 'tr' : 'en'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.background,
                            title: Text(AppStrings.get('reinvite_confirm_title', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary)),
                            content: Text(
                              AppStrings.get('reinvite_confirm_msg', isTr ? 'tr' : 'en'),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(AppStrings.get('cancel', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textHint)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(AppStrings.get('re_invite', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.success)),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        await _davetService.resetDavet(davet.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.get('reinvited', isTr ? 'tr' : 'en')),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.person_remove_rounded,
                          color: AppColors.danger, size: 20),
                      tooltip: AppStrings.get('remove', isTr ? 'tr' : 'en'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.background,
                            title: Text(AppStrings.get('remove_invitation_confirm_title', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary)),
                            content: Text(
                              AppStrings.get('remove_invitation_confirm_msg', isTr ? 'tr' : 'en'),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(AppStrings.get('cancel', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textHint)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(AppStrings.get('remove', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        await _davetService.deleteDavet(davet.id, isSayimClosed: currentSayim.effectiveStatus == SayimStatus.closed);
                        
                        // Remove from invitedUserIds
                        final updatedInvited = List<String>.from(currentSayim.invitedUserIds)..remove(davet.userId);
                        final updatedSayim = currentSayim.copyWith(invitedUserIds: updatedInvited);
                        await _sayimService.updateSayim(updatedSayim);
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
