import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/davet_service.dart';
import '../../../../core/services/sayim_service.dart';
import '../../../../core/services/language_service.dart';
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

  Future<void> _confirmDeleteSayim() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(isTr ? 'Sayımı Sil' : 'Delete Count', style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          isTr 
            ? 'Bu sayımı ve bağlantılı tüm davet/takvim kayıtlarını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'
            : 'Are you sure you want to delete this count and all related invitations/calendar records? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isTr ? 'Sil' : 'Delete', style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      }
      await _sayimService.deleteSayimFull(widget.sayim.id);
      if (mounted) {
        Navigator.pop(context); // loading pop
        Navigator.pop(context); // page pop
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTr ? 'Sayım başarıyla silindi.' : 'Count deleted successfully.')));
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
          return const Scaffold(
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(child: Text(isTr ? 'Sayım bulunamadı veya silinmiş.' : 'Count not found or deleted.', style: const TextStyle(color: AppColors.textSecondary))),
          );
        }

        return StreamBuilder<List<Davet>>(
          stream: _davetService.getDavetlerBySayim(currentSayim.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator(color: AppColors.accentLight)),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: Text(isTr ? 'Hata oluştu' : 'An error occurred')),
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isTr ? 'Sayım Detayı' : 'Count Details',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              if (widget.currentUser.id == currentSayim.createdBy || widget.currentUser.isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.textPrimary, size: 20),
                  tooltip: isTr ? 'Düzenle' : 'Edit',
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
                  icon: const Icon(Icons.delete_rounded, color: AppColors.danger, size: 20),
                  tooltip: isTr ? 'Sayımı Sil' : 'Delete Count',
                  onPressed: _confirmDeleteSayim,
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
                Tab(text: isTr ? 'Kabul' : 'Accepted'),
                Tab(text: isTr ? 'Bekliyor' : 'Pending'),
                Tab(text: isTr ? 'Red' : 'Declined'),
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
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isTr
                              ? 'Eksik Kişi! ${missingPersonel > 0 ? '$missingPersonel Personel ' : ''}${missingYonetici > 0 ? '$missingYonetici Yönetici' : ''} eksik.'
                              : 'Missing People! ${missingPersonel > 0 ? '$missingPersonel Staff ' : ''}${missingYonetici > 0 ? '$missingYonetici Manager' : ''} missing.',
                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13),
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
          floatingActionButton: (widget.currentUser.id == currentSayim.createdBy || widget.currentUser.isOwner) 
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
                label: Text(isTr ? 'Kişi Ekle' : 'Add Person'),
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
          isTr ? 'Kimse bulunamadı' : 'No one found',
          style: const TextStyle(color: AppColors.textHint),
        ),
      );
    }

    final isCreator = widget.currentUser.id == currentSayim.createdBy || widget.currentUser.isOwner;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: davetler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final davet = davetler[index];
        return FutureBuilder<AppUser?>(
          future: _getUser(davet.userId),
          builder: (context, userSnapshot) {
            final userName = userSnapshot.data?.fullName ?? (isTr ? 'Yükleniyor...' : 'Loading...');
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
                      style: const TextStyle(
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
                                userSnapshot.data?.isDeleted == true ? '$userName (${isTr ? "Silindi" : "Deleted"})' : userName,
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
                                          ? (isTr ? 'Yönetici' : 'Manager') 
                                          : (isTr ? 'Personel' : 'Staff'),
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
                        const SizedBox(height: 4),
                        Text(
                          '${isTr ? 'Ücret' : 'Wage'}: ₺${davet.ucret.toStringAsFixed(0)}${grupAdi.isNotEmpty ? ' • Saat: $grupAdi' : ''}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (status == DavetStatus.pending && isCreator) ...[
                    IconButton(
                      icon: const Icon(Icons.notifications_active_rounded,
                          color: AppColors.accentLight, size: 20),
                      tooltip: isTr ? 'Hatırlat' : 'Remind',
                      onPressed: () async {
                        // Cooldown: 5 dakika dolmadan tekrar hatırlatma atılmasını engelle
                        if (davet.lastReminderAt != null) {
                          final diff = DateTime.now().difference(davet.lastReminderAt!);
                          if (diff.inMinutes < 5) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isTr ? 'Lütfen yeni bir hatırlatma göndermeden önce 5 dakika bekleyin.' : 'Please wait 5 minutes before sending another reminder.'),
                                  backgroundColor: AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            return;
                          }
                        }

                        await _davetService.updateLastReminder(davet.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isTr ? 'Hatırlatma gönderildi.' : 'Reminder sent.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_remove_rounded,
                          color: AppColors.danger, size: 20),
                      tooltip: isTr ? 'İptal Et' : 'Cancel',
                      onPressed: () async {
                        await _davetService.deleteDavet(davet.id);
                      },
                    ),
                  ],
                  if (status == DavetStatus.accepted && isCreator) ...[
                    IconButton(
                      icon: const Icon(Icons.person_remove_rounded,
                          color: AppColors.danger, size: 20),
                      tooltip: isTr ? 'Kaldır' : 'Remove',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.background,
                            title: Text(isTr ? 'Kişiyi Çıkar' : 'Remove Person', style: const TextStyle(color: AppColors.textPrimary)),
                            content: Text(
                              isTr 
                                ? '$userName isimli personeli bu sayımdan çıkarmak istediğinize emin misiniz? (Kullanıcıya iptal bildirimi gönderilecektir)'
                                : 'Are you sure you want to remove $userName from this count? (A cancellation notification will be sent to the user)',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: AppColors.textHint)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(isTr ? 'Çıkar' : 'Remove', style: const TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _davetService.deleteDavet(davet.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isTr ? 'Kişi başarıyla çıkarıldı ve bildirim gönderildi.' : 'Person successfully removed and notification sent.'),
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
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.success, size: 20),
                      tooltip: isTr ? 'Tekrar Davet Et' : 'Re-invite',
                      onPressed: () async {
                        await _davetService.resetDavet(davet.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isTr ? 'Yeniden davet gönderildi' : 'Reinvited'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_remove_rounded,
                          color: AppColors.danger, size: 20),
                      tooltip: isTr ? 'Kaldır' : 'Remove',
                      onPressed: () async {
                        await _davetService.deleteDavet(davet.id);
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
