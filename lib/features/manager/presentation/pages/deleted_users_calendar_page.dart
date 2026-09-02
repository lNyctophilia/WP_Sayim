import 'package:daytrack/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/manager_drawer.dart';
import '../../../../features/home/presentation/widgets/custom_top_bar.dart';
import 'manager_panel_page.dart';
import '../../../../core/theme/theme_service.dart';
import 'user_calendar_page.dart';
import '../../../home/data/repositories/work_day_repository.dart';

class DeletedUsersCalendarPage extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final StorageService storage;
  final ThemeService themeService;
  final bool isEmbedded;

  const DeletedUsersCalendarPage({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.storage,
    required this.themeService,
    this.isEmbedded = false,
  });

  @override
  State<DeletedUsersCalendarPage> createState() => _DeletedUsersCalendarPageState();
}

class _DeletedUsersCalendarPageState extends State<DeletedUsersCalendarPage> {
  final _authService = AuthService();

  List<AppUser> _deletedUsers = [];
  bool _isLoading = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    widget.storage.setLastPanel('deleted_calendars');
    _loadDeletedUsers();
  }

  Future<void> _loadDeletedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.getDeletedUsers();
      if (mounted) {
        setState(() {
          _deletedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onUserSelected(AppUser user) async {
    setState(() => _isNavigating = true);
    try {
      final repository = WorkDayRepository(userId: user.id);
      final latestWorkDay = await repository.getLatestWorkDay();
      
      int? initialYear;
      int? initialMonth;
      
      if (latestWorkDay != null) {
        initialYear = latestWorkDay.date.year;
        initialMonth = latestWorkDay.date.month;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserCalendarPage(
              selectedUser: user,
              lang: widget.lang,
              initialYear: initialYear,
              initialMonth: initialMonth,
            ),
          ),
        );
      }
    } catch (e) {
      // Handle error if necessary
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  Future<void> _showUserSelectSheet() async {
    final isTr = widget.lang.currentLang == 'tr';
    String searchQuery = '';
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filteredUsers = _deletedUsers.where((u) {
              final q = searchQuery.toLowerCase();
              return u.fullName.toLowerCase().contains(q) || u.username.toLowerCase().contains(q);
            }).toList();
            
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        AppStrings.get('select_deleted_user', isTr ? 'tr' : 'en') ?? (isTr ? 'Silinen Kullanıcı Seç' : 'Select Deleted User'),
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: AppStrings.get('search', isTr ? 'tr' : 'en'),
                          hintStyle: TextStyle(color: AppColors.textHint),
                          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setStateSheet(() {
                            searchQuery = val;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.danger.withOpacity(0.2),
                              child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?', style: TextStyle(color: AppColors.danger)),
                            ),
                            title: Text(user.fullName, style: TextStyle(color: AppColors.textPrimary)),
                            subtitle: Text('@${user.username}', style: TextStyle(color: AppColors.textSecondary)),
                            onTap: () {
                              Navigator.pop(context);
                              _onUserSelected(user);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';

    Widget content = Column(
      children: [
        if (!widget.isEmbedded)
          CustomTopBar(
            currentUser: widget.currentUser, 
            lang: widget.lang, 
            storage: widget.storage,
            themeService: widget.themeService,
          ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.calendar_view_month_rounded, color: AppColors.accentLight),
              const SizedBox(width: 8),
              Text(
                AppStrings.get('deleted_account_calendars', isTr ? 'tr' : 'en') ?? (isTr ? 'Silinen Hesap Takvimleri' : 'Deleted Account Calendars'),
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.accentLight))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get('view_deleted_calendars_desc', isTr ? 'tr' : 'en') ?? 
                        (isTr ? 'Silinen hesapların geçmişteki iş takvimlerini ve rotalarını görüntüleyebilirsiniz.' : 'You can view the past work calendars and routes of deleted accounts.'),
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppStrings.get('select_deleted_user', isTr ? 'tr' : 'en') ?? (isTr ? 'Silinen Kullanıcı Seç' : 'Select Deleted User'),
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _isNavigating ? null : _showUserSelectSheet,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.get('select_a_person', isTr ? 'tr' : 'en'),
                                style: GoogleFonts.inter(
                                  color: AppColors.textHint,
                                  fontSize: 16,
                                ),
                              ),
                              _isNavigating 
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentLight))
                                : Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ManagerPanelPage(
              currentUser: widget.currentUser,
              storage: widget.storage,
              lang: widget.lang,
              themeService: widget.themeService,
              onLogout: () {},
            ),
            transitionDuration: Duration.zero,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: ManagerDrawer(
          currentUser: widget.currentUser,
          lang: widget.lang,
          storage: widget.storage,
          themeService: widget.themeService,
        ),
        body: SafeArea(child: content),
      ),
    );
  }
}
