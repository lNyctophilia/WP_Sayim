import 'package:daytrack/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:screenshot/screenshot.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:intl/intl.dart';
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
            final formattedDate = '${currentSayim.date.day.toString().padLeft(2, '0')}.${currentSayim.date.month.toString().padLeft(2, '0')}.${currentSayim.date.year}';
            final timeStr = currentSayim.startTime ?? (currentSayim.gruplar.isNotEmpty ? currentSayim.gruplar.first.saat : '');
            await notificationService.sendEmailNotification(
              targetUserId: davet.userId,
              subject: AppStrings.get('sayim_cancelled', isTr ? 'tr' : 'en') ?? 'Sayım İptali',
              textContent: 'Merhaba ${user.fullName},\n\nKabul ettiğiniz "${currentSayim.firmaAdi}" isimli sayım iptal edilmiştir.\n\nTarih & Saat: $formattedDate $timeStr\nToplanma Yeri: ${currentSayim.toplanmaYeri}\n\nBilginize.',
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

  Future<void> _exportSayimRaporu(Sayim selectedSayim, List<Davet> acceptedDavetler) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final Map<String, AppUser> userMap = {};
      final allUsers = await _authService.getAllUsers();
      for (var u in allUsers) {
        userMap[u.id] = u;
      }
      
      for (var d in acceptedDavetler) {
        if (!userMap.containsKey(d.userId)) {
          final u = await _authService.getUserData(d.userId);
          if (u != null) {
            userMap[u.id] = u;
          }
        }
      }

      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Sayım Raporu';

      final xlsio.Style headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.backColor = '#003366'; // Koyu mavi
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.bold = true;
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.vAlign = xlsio.VAlignType.center;

      final xlsio.Style centerStyle = workbook.styles.add('CenterStyle');
      centerStyle.hAlign = xlsio.HAlignType.center;
      centerStyle.vAlign = xlsio.VAlignType.center;

      final managerDavetler = acceptedDavetler.where((d) => d.role == DavetRole.manager).toList();
      final personnelDavetler = acceptedDavetler.where((d) => d.role != DavetRole.manager).toList();

      String firmaAdi = selectedSayim.firmaAdi.isNotEmpty ? selectedSayim.firmaAdi : 'Bilinmeyen Firma';
      String not = selectedSayim.note;
      List<String> words = not.split(' ').where((w) => w.trim().isNotEmpty).toList();
      String magazaAdi = firmaAdi;
      
      if (words.isNotEmpty) {
        magazaAdi = "$firmaAdi-${words.join('-')}";
      }

      sheet.getRangeByIndex(1, 1).setText('Working Partners Stok Sayım Hiz. A.Ş.');
      sheet.getRangeByIndex(1, 1, 1, 3).merge();
      sheet.getRangeByIndex(1, 1, 1, 3).cellStyle = headerStyle;

      sheet.getRangeByIndex(2, 1).setText('Sayım Tarihi');
      sheet.getRangeByIndex(2, 2).setText('Başlangıç Saati');
      sheet.getRangeByIndex(2, 3).setText('Firma Adı');
      sheet.getRangeByIndex(2, 1, 2, 3).cellStyle = headerStyle;

      final dateStrFormatted = DateFormat('dd.MM.yyyy').format(selectedSayim.date);
      sheet.getRangeByIndex(3, 1).setText(dateStrFormatted);
      sheet.getRangeByIndex(3, 2).setText(selectedSayim.startTime ?? '');
      sheet.getRangeByIndex(3, 3).setText(firmaAdi);
      sheet.getRangeByIndex(3, 1, 3, 3).cellStyle = centerStyle;

      sheet.getRangeByIndex(4, 1).setText('Mağaza Adı');
      sheet.getRangeByIndex(4, 1, 4, 2).merge();
      sheet.getRangeByIndex(4, 3).setText('Sayıma Katılacak Kişi Sayısı');
      sheet.getRangeByIndex(4, 1, 4, 3).cellStyle = headerStyle;

      sheet.getRangeByIndex(5, 1).setText(magazaAdi);
      sheet.getRangeByIndex(5, 1, 5, 2).merge();
      sheet.getRangeByIndex(5, 3).setText('${personnelDavetler.length}+${managerDavetler.length}');
      sheet.getRangeByIndex(5, 1, 5, 3).cellStyle = centerStyle;

      sheet.getRangeByIndex(6, 1).setText('WP Sayım Firması Yetkilileri (Sayıma Olası Katılabilecekler)');
      sheet.getRangeByIndex(6, 1, 6, 3).merge();
      sheet.getRangeByIndex(6, 1, 6, 3).cellStyle = headerStyle;

      int r = 7;
      void addContact(String title, String name, String detail) {
        sheet.getRangeByIndex(r, 1).setText(title);
        sheet.getRangeByIndex(r, 2).setText(name);
        sheet.getRangeByIndex(r, 3).setText(detail);
        sheet.getRangeByIndex(r, 1, r, 3).cellStyle = centerStyle;
        r++;
      }
      addContact('Bölge Müdürü', 'Emin Körpe', '05498147929');
      addContact('Bölge Müdürü Yrd.', '', '');
      addContact('Operasyon Müdürü', 'Kadir Özer', '05059732202');
      addContact('İç Denetim', 'Mustafa Koray Göç', 'm.goc@workingpartners.com.tr');
      addContact('İç Denetim', 'Erdem Köhneli', 'e.kohneli@workingpartners.com.tr');
      addContact('Bilgi İşlem', 'Doğan Eroğlu', 'd.eroglu@workingpartners.com.tr');

      sheet.getRangeByIndex(r, 1).setText('Sayım Yöneticileri');
      sheet.getRangeByIndex(r, 1, r, 3).merge();
      sheet.getRangeByIndex(r, 1, r, 3).cellStyle = headerStyle;
      r++;

      int counter = 1;
      for (var davet in managerDavetler) {
        final user = userMap[davet.userId];
        sheet.getRangeByIndex(r, 1).setNumber(counter.toDouble());
        sheet.getRangeByIndex(r, 2).setText(user?.fullName ?? 'Bilinmeyen Kullanıcı');
        sheet.getRangeByIndex(r, 3).setText(user?.phone ?? '');
        sheet.getRangeByIndex(r, 1, r, 3).cellStyle = centerStyle;
        r++;
        counter++;
      }

      sheet.getRangeByIndex(r, 1).setText('Sayım Personelleri');
      sheet.getRangeByIndex(r, 1, r, 3).merge();
      sheet.getRangeByIndex(r, 1, r, 3).cellStyle = headerStyle;
      r++;

      counter = 1;
      for (var davet in personnelDavetler) {
        final user = userMap[davet.userId];
        String saatStr = "";
        try {
          final grp = selectedSayim.gruplar.firstWhere((g) => g.grupId == davet.grupId);
          saatStr = grp.saat;
        } catch (e) {}

        sheet.getRangeByIndex(r, 1).setNumber(counter.toDouble());
        sheet.getRangeByIndex(r, 2).setText(user?.fullName ?? 'Bilinmeyen Kullanıcı');
        sheet.getRangeByIndex(r, 3).setText(saatStr);
        sheet.getRangeByIndex(r, 1, r, 3).cellStyle = centerStyle;
        r++;
        counter++;
      }

      sheet.setColumnWidthInPixels(1, 180);
      sheet.setColumnWidthInPixels(2, 280);
      sheet.setColumnWidthInPixels(3, 220);

      String extraName = "";
      if (words.isNotEmpty) {
        extraName = "_${words.join('_')}";
      }

      final dateStr = DateFormat('dd-MM-yyyy').format(selectedSayim.date);
      final String fileName = '${firmaAdi}${extraName}_$dateStr';

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.get('excel_downloaded_successfully', isTr ? 'tr' : 'en')}:\n$savedPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.get('error_occurred', isTr ? 'tr' : 'en')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToPng(Sayim selectedSayim, List<Davet> acceptedDavetler) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final Map<String, AppUser> userMap = {};
      final allUsers = await _authService.getAllUsers();
      for (var u in allUsers) {
        userMap[u.id] = u;
      }
      
      for (var d in acceptedDavetler) {
        if (!userMap.containsKey(d.userId)) {
          final u = await _authService.getUserData(d.userId);
          if (u != null) {
            userMap[u.id] = u;
          }
        }
      }

      final managerDavetler = acceptedDavetler.where((d) => d.role == DavetRole.manager).toList();
      final personnelDavetler = acceptedDavetler.where((d) => d.role != DavetRole.manager).toList();

      String firmaAdi = selectedSayim.firmaAdi.isNotEmpty ? selectedSayim.firmaAdi : 'Bilinmeyen Firma';
      String not = selectedSayim.note;
      List<String> words = not.split(' ').where((w) => w.trim().isNotEmpty).toList();
      String magazaAdi = firmaAdi;
      if (words.isNotEmpty) {
        magazaAdi = "$firmaAdi-${words.join('-')}";
      }
      final dateStrFormatted = DateFormat('dd.MM.yyyy').format(selectedSayim.date);

      Widget buildRow(String index, String name, String time, {bool isHeader = false, bool isEven = false}) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: isHeader 
                ? Colors.transparent 
                : isEven ? const Color(0xFF003366).withOpacity(0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(width: 40, child: Text(index, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: Colors.black87, fontSize: 16))),
              Expanded(child: Text(name, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: Colors.black87, fontSize: 16))),
              SizedBox(width: 100, child: Text(time, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, color: Colors.black87, fontSize: 16))),
            ],
          ),
        );
      }

      final pngWidget = Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003366),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${selectedSayim.firmaAdi} - ${selectedSayim.note}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  Text(dateStrFormatted, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003366),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text('Sayım Yöneticileri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            buildRow('#', 'Ad Soyad', 'Saat', isHeader: true),
            ...managerDavetler.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final davet = entry.value;
              final user = userMap[davet.userId];
              String saatStr = "";
              try {
                final grp = selectedSayim.gruplar.firstWhere((g) => g.grupId == davet.grupId);
                saatStr = grp.saat;
              } catch (e) {}
              return buildRow('$idx', user?.fullName ?? 'Bilinmeyen Kullanıcı', saatStr, isEven: entry.key % 2 == 0);
            }),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003366),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text('Sayım Personelleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            buildRow('#', 'Ad Soyad', 'Saat', isHeader: true),
            ...personnelDavetler.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final davet = entry.value;
              final user = userMap[davet.userId];
              String saatStr = "";
              try {
                final grp = selectedSayim.gruplar.firstWhere((g) => g.grupId == davet.grupId);
                saatStr = grp.saat;
              } catch (e) {}
              return buildRow('$idx', user?.fullName ?? 'Bilinmeyen Kullanıcı', saatStr, isEven: entry.key % 2 == 0);
            }),
          ],
        ),
      );

      double calculatedHeight = 200.0;
      calculatedHeight += (managerDavetler.length + 1) * 45.0 + 80.0;
      calculatedHeight += (personnelDavetler.length + 1) * 45.0 + 80.0;

      final screenshotController = ScreenshotController();
      final Uint8List imageBytes = await screenshotController.captureFromWidget(
        Material(child: pngWidget),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0,
        targetSize: Size(600, calculatedHeight),
      );

      String extraName = "";
      if (words.isNotEmpty) {
        extraName = "_${words.join('_')}";
      }
      final dateStrForFile = DateFormat('dd-MM-yyyy').format(selectedSayim.date);
      final String fileName = '${firmaAdi}${extraName}_$dateStrForFile';

      final savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: imageBytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );

      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.get('png_downloaded_successfully', isTr ? 'tr' : 'en')}:\n$savedPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.get('error_occurred', isTr ? 'tr' : 'en')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool get isTr => widget.lang.currentLang == 'tr';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Sayim?>(
      future: _sayimService.getSayimFuture(widget.sayim.id),
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

        return FutureBuilder<List<Davet>>(
          future: _davetService.getDavetlerBySayimFuture(currentSayim.id),
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
              if (widget.currentUser.hasManagerPermission || widget.currentUser.hasAdminPermission)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimary, size: 22),
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  offset: const Offset(0, 40),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
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
                        break;
                      case 'export_excel':
                        final acceptedDavets = davetler.where((d) => d.status == DavetStatus.accepted).toList();
                        _exportSayimRaporu(currentSayim, acceptedDavets);
                        break;
                      case 'export_png':
                        final acceptedDavetsPng = davetler.where((d) => d.status == DavetStatus.accepted).toList();
                        _exportToPng(currentSayim, acceptedDavetsPng);
                        break;
                      case 'toggle_status':
                        if (currentSayim.effectiveStatus == SayimStatus.open) {
                          _sayimService.closeSayim(currentSayim.id);
                        } else {
                          _sayimService.openSayim(currentSayim.id);
                        }
                        break;
                      case 'delete':
                        _confirmDeleteSayim(davetler, currentSayim);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: AppColors.textPrimary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            AppStrings.get('edit', isTr ? 'tr' : 'en'),
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'export_excel',
                      child: Row(
                        children: [
                          Icon(Icons.download_rounded, color: AppColors.textPrimary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            AppStrings.get('export_excel_output', isTr ? 'tr' : 'en'),
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'export_png',
                      child: Row(
                        children: [
                          Icon(Icons.image_rounded, color: AppColors.textPrimary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            AppStrings.get('export_png_output', isTr ? 'tr' : 'en'),
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            currentSayim.effectiveStatus == SayimStatus.open
                                ? Icons.lock_outline_rounded
                                : Icons.lock_open_rounded,
                            color: currentSayim.effectiveStatus == SayimStatus.open
                                ? AppColors.warning
                                : AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            currentSayim.effectiveStatus == SayimStatus.open
                                ? AppStrings.get('close_count', isTr ? 'tr' : 'en')
                                : AppStrings.get('open_count', isTr ? 'tr' : 'en'),
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            AppStrings.get('delete', isTr ? 'tr' : 'en'),
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    _buildDavetList(accepted, DavetStatus.accepted, currentSayim, currentPersonel, currentYonetici),
                    _buildDavetList(pending, DavetStatus.pending, currentSayim, currentPersonel, currentYonetici),
                    _buildDavetList(declined, DavetStatus.declined, currentSayim, currentPersonel, currentYonetici),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: (widget.currentUser.hasManagerPermission || widget.currentUser.hasAdminPermission)
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

  Widget _buildDavetList(List<Davet> davetler, DavetStatus status, Sayim currentSayim, int currentPersonel, int currentYonetici) {
    if (davetler.isEmpty) {
      return Center(
        child: Text(
          AppStrings.get('no_one_found', isTr ? 'tr' : 'en'),
          style: TextStyle(color: AppColors.textHint),
        ),
      );
    }

    final isCreator = widget.currentUser.hasManagerPermission || widget.currentUser.hasAdminPermission;

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
                                userName,
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (userSnapshot.hasData && userSnapshot.data != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: davet.role == DavetRole.manager
                                      ? AppColors.accentLight.withValues(alpha: 0.1) 
                                      : AppColors.divider.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  davet.role == DavetRole.manager
                                      ? (AppStrings.get('manager', isTr ? 'tr' : 'en')) 
                                      : (AppStrings.get('staff', isTr ? 'tr' : 'en')),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: davet.role == DavetRole.manager
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
                            textContent: 'Merhaba ${userSnapshot.data!.fullName},\n\nYeni bir sayım için davet edildiniz!\n\nTarih: $sayimTarihi\nSaat: $grupAdi\nToplanma Yeri: ${currentSayim.toplanmaYeri}\n\nLütfen uygulamaya girerek daveti yanıtlayın.',
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
                        final updatedInvited = List<String>.from(currentSayim.invitedUserIds)..removeWhere((id) => id == davet.userId);
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
                            final formattedDate = '${currentSayim.date.day.toString().padLeft(2, '0')}.${currentSayim.date.month.toString().padLeft(2, '0')}.${currentSayim.date.year}';
                            final timeStr = currentSayim.startTime ?? (currentSayim.gruplar.isNotEmpty ? currentSayim.gruplar.first.saat : '');
                            final NotificationService notificationService = NotificationService();
                            await notificationService.sendEmailNotification(
                              targetUserId: davet.userId,
                              subject: AppStrings.get('sayim_cancelled', isTr ? 'tr' : 'en') ?? 'Sayım İptali',
                              textContent: 'Merhaba ${userName},\n\nKabul ettiğiniz "${currentSayim.firmaAdi}" isimli sayımdan çıkarıldınız.\n\nTarih & Saat: $formattedDate $timeStr\nToplanma Yeri: ${currentSayim.toplanmaYeri}\n\nBilginize.',
                            );
                          }

                          await _davetService.deleteDavet(davet.id, isSayimClosed: currentSayim.effectiveStatus == SayimStatus.closed);
                          
                          // Remove from invitedUserIds
                          final updatedInvited = List<String>.from(currentSayim.invitedUserIds)..removeWhere((id) => id == davet.userId);
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
                        if (davet.role == DavetRole.staff && currentPersonel >= currentSayim.maxKisi) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppStrings.getFormat('you_can_select_up_to_maxselection_people', isTr ? 'tr' : 'en', [currentSayim.maxKisi])), backgroundColor: AppColors.danger),
                          );
                          return;
                        }
                        if (davet.role == DavetRole.manager && currentYonetici >= currentSayim.maxYonetici) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppStrings.getFormat('you_can_select_up_to_maxselection_people', isTr ? 'tr' : 'en', [currentSayim.maxYonetici])), backgroundColor: AppColors.danger),
                          );
                          return;
                        }

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
                        final updatedInvited = List<String>.from(currentSayim.invitedUserIds)..removeWhere((id) => id == davet.userId);
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
