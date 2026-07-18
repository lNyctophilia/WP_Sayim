import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/services/davet_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/models/app_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InvitationsPage extends StatefulWidget {
  final AppUser currentUser;

  const InvitationsPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  final DavetService _davetService = DavetService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<List<Davet>> _davetStream;

  @override
  void initState() {
    super.initState();
    _davetStream = _davetService.getDavetlerByUser(widget.currentUser.id);
  }

  Future<void> _onRefresh() async {
    setState(() {
      _davetStream = _davetService.getDavetlerByUser(widget.currentUser.id);
    });
    // Provide some visual feedback time for the refresh indicator
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _acceptDavet(Davet davet) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.accentLight)),
      );

      await _davetService.acceptDavet(davet.id);

      if (mounted) {
        Navigator.pop(context); // Yükleniyor'u kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Davet kabul edildi ve takvime eklendi!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _declineDavet(Davet davet) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.accentLight)),
      );

      await _davetService.declineDavet(davet.id);

      if (mounted) {
        Navigator.pop(context); // Yükleniyor'u kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Davet reddedildi.'),
            backgroundColor: AppColors.textHint,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          title: const Text(
            'Davetler',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: AppColors.accentLight,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.accentLight,
            tabs: [
              Tab(text: 'Bekleyenler'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: StreamBuilder<List<Davet>>(
          stream: _davetStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accentLight));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Bir hata oluştu: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.danger),
                ),
              );
            }

            final allDavetler = snapshot.data ?? [];
            final pendingDavetler = allDavetler.where((d) => d.status == DavetStatus.pending).toList();
            final pastDavetler = allDavetler.where((d) => d.status != DavetStatus.pending).toList();
            
            pastDavetler.sort((a, b) {
              final dateA = a.respondedAt ?? a.createdAt;
              final dateB = b.respondedAt ?? b.createdAt;
              return dateB.compareTo(dateA);
            });

            return TabBarView(
              children: [
                _buildList(pendingDavetler, true),
                _buildPastTab(pastDavetler),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isPending) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.accentLight,
      backgroundColor: AppColors.card,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPending ? Icons.inbox_rounded : Icons.history_rounded,
                    size: 64,
                    color: AppColors.textHint.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPending ? 'Bekleyen davetiniz bulunmuyor.' : 'Geçmiş bildirim bulunmuyor.',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Davet> davetler, bool isPending) {
    if (davetler.isEmpty) {
      return _buildEmptyState(isPending);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.accentLight,
      backgroundColor: AppColors.card,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: davetler.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final davet = davetler[index];
          return _buildDavetCard(davet, isPast: !isPending);
        },
      ),
    );
  }

  Widget _buildDavetCard(Davet davet, {bool isPast = false}) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('sayimlar').doc(davet.sayimId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accentLight),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink(); // Sayım silinmiş olabilir
        }

        final sayim = Sayim.fromFirestore(snapshot.data!);
        final grup = sayim.gruplar.firstWhere(
          (g) => g.grupId == davet.grupId,
          orElse: () => const SayimGrup(grupId: 1, saat: ''),
        );

        final String dateStr = "${sayim.date.day.toString().padLeft(2, '0')}.${sayim.date.month.toString().padLeft(2, '0')}.${sayim.date.year}";

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentLight.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: AppColors.accentLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sayim.note,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dateStr - ${grup.saat}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (davet.sehirIciDisi == SehirTipi.ici ? AppColors.cityInner : AppColors.cityOuter).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      davet.sehirIciDisi == SehirTipi.ici ? 'Ş. İçi' : 'Ş. Dışı',
                      style: TextStyle(
                        color: davet.sehirIciDisi == SehirTipi.ici ? AppColors.cityInner : AppColors.cityOuter,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ücret',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                      Text(
                        '₺${davet.ucret.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (!isPast)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _declineDavet(davet),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reddet', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _acceptDavet(davet),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Kabul Et', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: (davet.status == DavetStatus.accepted ? AppColors.success : AppColors.danger).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        davet.status == DavetStatus.accepted ? 'Kabul Edildi' : 'Reddedildi',
                        style: TextStyle(
                          color: davet.status == DavetStatus.accepted ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPastTab(List<Davet> pastDavetler) {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getNotificationsByUser(widget.currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentLight));
        }

        final notifications = (snapshot.data ?? [])
            .where((n) => n.type != 'davet') // Filter out generic davet notifications to avoid duplicates with Davet cards
            .toList();

        // Merge both lists into a single List<dynamic>
        final List<dynamic> merged = [...pastDavetler, ...notifications];

        // Sort descending by date
        merged.sort((a, b) {
          final DateTime dateA = (a is Davet) ? (a.respondedAt ?? a.createdAt) : (a as AppNotification).createdAt;
          final DateTime dateB = (b is Davet) ? (b.respondedAt ?? b.createdAt) : (b as AppNotification).createdAt;
          return dateB.compareTo(dateA);
        });

        if (merged.isEmpty) {
          return _buildEmptyState(false);
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.accentLight,
          backgroundColor: AppColors.card,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: merged.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = merged[index];
              if (item is Davet) {
                return _buildDavetCard(item, isPast: true);
              } else if (item is AppNotification) {
                return _buildNotificationCard(item);
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    // Okunmamışsa tıklandığında okundu işaretle (veya otomatik yapalım)
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'davet_cancelled':
        icon = Icons.cancel_rounded;
        iconColor = AppColors.danger;
        break;
      case 'davet_response':
      case 'approval':
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
        break;
      case 'sayim_auto_reminder':
      case 'davet_reminder':
        icon = Icons.notifications_active_rounded;
        iconColor = AppColors.cityInner; // Orange/Warning color would be better, but use cityInner for now
        break;
      case 'system_log':
        icon = Icons.settings_system_daydream_rounded;
        iconColor = AppColors.accentLight;
        break;
      case 'system_log_danger':
        icon = Icons.delete_forever_rounded;
        iconColor = AppColors.danger;
        break;
      default:
        icon = Icons.info_rounded;
        iconColor = AppColors.accentLight;
    }

    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(notification.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
