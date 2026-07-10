import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/davet_service.dart';
import '../../../../core/services/language_service.dart';

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

  bool get isTr => widget.lang.currentLang == 'tr';

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<List<Davet>>(
        stream: _davetService.getDavetlerBySayim(widget.sayim.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accentLight));
          }
          if (snapshot.hasError) {
            return Center(child: Text(isTr ? 'Hata oluştu' : 'An error occurred'));
          }

          final davetler = snapshot.data ?? [];
          
          final accepted = davetler.where((d) => d.isAccepted).toList();
          final pending = davetler.where((d) => d.isPending).toList();
          final declined = davetler.where((d) => d.isDeclined).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDavetList(accepted, DavetStatus.accepted),
              _buildDavetList(pending, DavetStatus.pending),
              _buildDavetList(declined, DavetStatus.declined),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentLight,
        foregroundColor: Colors.white,
        onPressed: () {
          // TODO: Yeni personel ekleme modalı/sayfası açılacak
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isTr ? 'Yakında eklenecek' : 'Coming soon')),
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: Text(isTr ? 'Kişi Ekle' : 'Add Person'),
      ),
    );
  }

  Widget _buildDavetList(List<Davet> davetler, DavetStatus status) {
    if (davetler.isEmpty) {
      return Center(
        child: Text(
          isTr ? 'Kimse bulunamadı' : 'No one found',
          style: const TextStyle(color: AppColors.textHint),
        ),
      );
    }

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
                        Text(
                          userName,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isTr ? 'Ücret' : 'Wage'}: ₺${davet.ucret.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (status == DavetStatus.pending)
                    IconButton(
                      icon: const Icon(Icons.notifications_active_rounded,
                          color: AppColors.accentLight, size: 20),
                      tooltip: isTr ? 'Hatırlat' : 'Remind',
                      onPressed: () async {
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
                  if (status == DavetStatus.declined)
                    IconButton(
                      icon: const Icon(Icons.person_remove_rounded,
                          color: AppColors.danger, size: 20),
                      tooltip: isTr ? 'Kaldır' : 'Remove',
                      onPressed: () async {
                        await _davetService.deleteDavet(davet.id);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
