import 'package:daytrack/core/constants/app_strings.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:screenshot/screenshot.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/services/sayim_service.dart';
import '../../../../core/services/davet_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/manager_drawer.dart';
import '../../../../features/home/presentation/widgets/custom_top_bar.dart';
import 'manager_panel_page.dart';
import '../../../../core/theme/theme_service.dart';

class ExportSayimPage extends StatefulWidget {
  final LanguageService lang;
  final StorageService storage;
  final AppUser currentUser;
  final ThemeService themeService;
  final bool isEmbedded;

  const ExportSayimPage({
    super.key,
    required this.lang,
    required this.storage,
    required this.currentUser,
    required this.themeService,
    this.isEmbedded = false,
  });

  @override
  State<ExportSayimPage> createState() => _ExportSayimPageState();
}

class _ExportSayimPageState extends State<ExportSayimPage> {
  final SayimService _sayimService = SayimService();
  final DavetService _davetService = DavetService();
  final AuthService _authService = AuthService();

  Sayim? _selectedSayim;
  String? _selectedMonthKey;
  String? _selectedCity;
  String? _selectedReportType;
  bool _isExcelLoading = false;
  bool _isPngLoading = false;
  bool _isSummaryExpanded = false;

  @override
  void initState() {
    super.initState();
    widget.storage.setLastPanel('export');
  }

  Future<void> _exportToExcel() async {
    if (_selectedReportType == 'sayim') {
      await _exportSayimRaporu();
    } else if (_selectedReportType == 'aylik') {
      await _exportAylikRapor();
    }
  }

  Future<void> _exportToPng() async {
    if (_selectedSayim == null) return;
    setState(() => _isPngLoading = true);
    
    try {
      final davetler = await _davetService.getDavetlerBySayimFuture(_selectedSayim!.id);
      final acceptedDavetler = davetler.where((d) => d.status == DavetStatus.accepted).toList();

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

      String firmaAdi = _selectedSayim!.firmaAdi.isNotEmpty ? _selectedSayim!.firmaAdi : 'Bilinmeyen Firma';
      String not = _selectedSayim!.note;
      List<String> words = not.split(' ').where((w) => w.trim().isNotEmpty).toList();
      String magazaAdi = firmaAdi;
      if (words.isNotEmpty) {
        magazaAdi = "$firmaAdi-${words.join('-')}";
      }
      final dateStrFormatted = DateFormat('dd.MM.yyyy').format(_selectedSayim!.date);

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
                    child: Text('${_selectedSayim!.firmaAdi} - ${_selectedSayim!.city} - ${_selectedSayim!.note}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                final grp = _selectedSayim!.gruplar.firstWhere((g) => g.grupId == davet.grupId);
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
                final grp = _selectedSayim!.gruplar.firstWhere((g) => g.grupId == davet.grupId);
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

      final String fileName = dateStrFormatted;

      final savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: imageBytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PNG dosyası başarıyla indirildi:\n$savedPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isPngLoading = false);
    }
  }

  Future<void> _exportSayimRaporu() async {
    if (_selectedSayim == null) return;

    setState(() => _isExcelLoading = true);
    
    try {
      // 2. Davetleri getir (sadece kabul edenler)
      final davetler = await _davetService.getDavetlerBySayimFuture(_selectedSayim!.id);
      final acceptedDavetler = davetler.where((d) => d.status == DavetStatus.accepted).toList();

      // 3. Kullanıcıları getir
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

      // 4. Excel Oluştur
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Sayım Raporu';

      // Stil Tanımlamaları
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

      // Firma ve Mağaza Adı Çıkarımı
      String firmaAdi = _selectedSayim!.firmaAdi.isNotEmpty ? _selectedSayim!.firmaAdi : 'Bilinmeyen Firma';
      String not = _selectedSayim!.note;
      List<String> words = not.split(' ').where((w) => w.trim().isNotEmpty).toList();
      String magazaAdi = firmaAdi;
      
      if (words.isNotEmpty) {
        magazaAdi = "$firmaAdi-${words.join('-')}";
      }

      // Satır 1: Title
      sheet.getRangeByIndex(1, 1).setText('Working Partners Stok Sayım Hiz. A.Ş.');
      sheet.getRangeByIndex(1, 1, 1, 3).merge();
      sheet.getRangeByIndex(1, 1, 1, 3).cellStyle = headerStyle;

      // Satır 2: Başlıklar
      sheet.getRangeByIndex(2, 1).setText('Sayım Tarihi');
      sheet.getRangeByIndex(2, 2).setText('Başlangıç Saati');
      sheet.getRangeByIndex(2, 3).setText('Firma Adı');
      sheet.getRangeByIndex(2, 1, 2, 3).cellStyle = headerStyle;

      // Satır 3: Veriler
      final dateStrFormatted = DateFormat('dd.MM.yyyy').format(_selectedSayim!.date);
      sheet.getRangeByIndex(3, 1).setText(dateStrFormatted);
      sheet.getRangeByIndex(3, 2).setText(_selectedSayim!.startTime ?? '');
      sheet.getRangeByIndex(3, 3).setText(firmaAdi);
      sheet.getRangeByIndex(3, 1, 3, 3).cellStyle = centerStyle;

      // Satır 4: Başlıklar
      sheet.getRangeByIndex(4, 1).setText('Mağaza Adı');
      sheet.getRangeByIndex(4, 1, 4, 2).merge();
      sheet.getRangeByIndex(4, 3).setText('Sayıma Katılacak Kişi Sayısı');
      sheet.getRangeByIndex(4, 1, 4, 3).cellStyle = headerStyle;

      // Satır 5: Veriler
      sheet.getRangeByIndex(5, 1).setText(magazaAdi);
      sheet.getRangeByIndex(5, 1, 5, 2).merge();
      sheet.getRangeByIndex(5, 3).setText('${personnelDavetler.length}+${managerDavetler.length}');
      sheet.getRangeByIndex(5, 1, 5, 3).cellStyle = centerStyle;

      // Satır 6: Yetkililer Başlığı
      sheet.getRangeByIndex(6, 1).setText('WP Sayım Firması Yetkilileri (Sayıma Olası Katılabilecekler)');
      sheet.getRangeByIndex(6, 1, 6, 3).merge();
      sheet.getRangeByIndex(6, 1, 6, 3).cellStyle = headerStyle;

      // Satır 7-12: Yetkililer Statik Veri
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

      // Satır r: Yöneticiler Başlığı
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

      // Satır r: Personeller Başlığı
      sheet.getRangeByIndex(r, 1).setText('Sayım Personelleri');
      sheet.getRangeByIndex(r, 1, r, 3).merge();
      sheet.getRangeByIndex(r, 1, r, 3).cellStyle = headerStyle;
      r++;

      counter = 1;
      for (var davet in personnelDavetler) {
        final user = userMap[davet.userId];
        String saatStr = "";
        try {
          final grp = _selectedSayim!.gruplar.firstWhere((g) => g.grupId == davet.grupId);
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

      // 6. Dosyayı Kaydet
      String extraName = "";
      if (words.isNotEmpty) {
        extraName = "_${words.join('_')}";
      }

      final dateStr = DateFormat('dd-MM-yyyy').format(_selectedSayim!.date);
      final String fileName = 'Sayim_Detay_${firmaAdi}${extraName}_$dateStr';

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel dosyası başarıyla indirildi:\n$savedPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExcelLoading = false);
    }
  }

  Future<void> _exportAylikRapor() async {
    if (_selectedMonthKey == null || _selectedCity == null) return;
    
    setState(() => _isExcelLoading = true);
    final isTr = widget.lang.currentLang == 'tr';
    final unknownUserStr = AppStrings.get('unknown_user', isTr ? 'tr' : 'en');
    
    try {
      // 1. Get all counts for the month
      final sayimlar = await _sayimService.getSayimlar().first;
      final monthSayimlar = sayimlar.where((s) {
        final key = "${s.date.year}-${s.date.month.toString().padLeft(2, '0')}";
        return key == _selectedMonthKey;
      }).toList();

      // 2. Fetch davets for all counts
      final Map<String, int> userWorkCount = {};
      int totalPersonelCalistirma = 0;
      int totalSayim = monthSayimlar.where((s) => s.city == _selectedCity).length;
      
      final Map<String, AppUser> userMap = {};
      final allUsersRaw = await _authService.getAllUsers();
      for (var u in allUsersRaw) {
        if (u.city == _selectedCity) {
          userMap[u.id] = u;
          userWorkCount[u.id] = 0; // Tüm personeli sıfır olarak ekle
        }
      }

      for (var sayim in monthSayimlar) {
        final davetler = await _davetService.getDavetlerBySayimFuture(sayim.id);
        final acceptedDavetler = davetler.where((d) => d.status == DavetStatus.accepted).toList();
        
        for (var d in acceptedDavetler) {
          if (!userMap.containsKey(d.userId)) {
            final u = await _authService.getUserData(d.userId);
            if (u != null && u.city == _selectedCity) {
              userMap[u.id] = u;
              userWorkCount[u.id] = 0;
            } else {
              continue; // Farklı il veya kullanıcı yok, rapora dahil etme
            }
          }
          userWorkCount[d.userId] = (userWorkCount[d.userId] ?? 0) + 1;
          totalPersonelCalistirma++;
        }
      }

      // 3. Sort users by count (descending), then A-Z
      final List<MapEntry<String, int>> sortedUsers = userWorkCount.entries.toList();
      
      sortedUsers.sort((a, b) {
        final countCmp = b.value.compareTo(a.value); // Descending by count
        if (countCmp != 0) return countCmp;
        // Fallback to name A-Z
        final userA = userMap[a.key]?.fullName ?? unknownUserStr;
        final userB = userMap[b.key]?.fullName ?? unknownUserStr;
        return userA.compareTo(userB);
      });

      // 4. Create Excel
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = AppStrings.get('report_type_aylik', isTr ? 'tr' : 'en');

      final xlsio.Style headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.backColor = '#003366';
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.bold = true;
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.vAlign = xlsio.VAlignType.center;

      final xlsio.Style centerStyle = workbook.styles.add('CenterStyle');
      centerStyle.hAlign = xlsio.HAlignType.center;
      centerStyle.vAlign = xlsio.VAlignType.center;

      // Row 1: Title
      sheet.getRangeByIndex(1, 1).setText('Working Partners Stok Sayım Hiz. A.Ş.');
      sheet.getRangeByIndex(1, 1, 1, 3).merge();
      sheet.getRangeByIndex(1, 1, 1, 3).cellStyle = headerStyle;

      // Row 2: Report Name
      final parts = _selectedMonthKey!.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      final monthName = AppStrings.getMonth(month, isTr ? 'tr' : 'en');
      sheet.getRangeByIndex(2, 1).setText('$monthName $year ${AppStrings.get('report_type_aylik', isTr ? 'tr' : 'en')}');
      sheet.getRangeByIndex(2, 1, 2, 3).merge();
      sheet.getRangeByIndex(2, 1, 2, 3).cellStyle = centerStyle;
      sheet.getRangeByIndex(2, 1, 2, 3).cellStyle.bold = true;

      // Row 3: Boş Satır (Başlık ile özet tablo arası)

      // Row 4: Summary Table Headers
      sheet.getRangeByIndex(4, 1).setText(isTr ? 'Veri Adı' : 'Data Name');
      sheet.getRangeByIndex(4, 1, 4, 2).merge();
      sheet.getRangeByIndex(4, 3).setText(isTr ? 'Miktar' : 'Amount');
      sheet.getRangeByIndex(4, 1, 4, 3).cellStyle = headerStyle;

      // Row 5: Total Counts
      sheet.getRangeByIndex(5, 1).setText(AppStrings.get('total_counts_in_month', isTr ? 'tr' : 'en').replaceAll(':', '').trim());
      sheet.getRangeByIndex(5, 1, 5, 2).merge();
      sheet.getRangeByIndex(5, 3).setNumber(totalSayim.toDouble());
      
      // Row 6: Total Shifts
      sheet.getRangeByIndex(6, 1).setText(AppStrings.get('total_personnel_shifts', isTr ? 'tr' : 'en').replaceAll(':', '').trim());
      sheet.getRangeByIndex(6, 1, 6, 2).merge();
      sheet.getRangeByIndex(6, 3).setNumber(totalPersonelCalistirma.toDouble());

      // Style for Rows 5 and 6
      sheet.getRangeByIndex(5, 1, 6, 3).cellStyle.hAlign = xlsio.HAlignType.center;
      sheet.getRangeByIndex(5, 1, 6, 3).cellStyle.vAlign = xlsio.VAlignType.center;
      sheet.getRangeByIndex(5, 1, 6, 3).cellStyle.bold = true;

      // Row 7: Boş satır (Excel'in tabloları ayırması ve sıralamanın bozulmaması için ZORUNLU)

      // Row 8: Table Headers
      sheet.getRangeByIndex(8, 1).setText(AppStrings.get('order', isTr ? 'tr' : 'en'));
      sheet.getRangeByIndex(8, 2).setText(AppStrings.get('personnel_name', isTr ? 'tr' : 'en'));
      sheet.getRangeByIndex(8, 3).setText(AppStrings.get('participated_counts', isTr ? 'tr' : 'en'));
      sheet.getRangeByIndex(8, 1, 8, 3).cellStyle = headerStyle;

      // Data Rows
      int r = 9;
      int counter = 1;
      for (var entry in sortedUsers) {
        final user = userMap[entry.key];
        sheet.getRangeByIndex(r, 1).setNumber(counter.toDouble());
        sheet.getRangeByIndex(r, 2).setText(user?.fullName ?? unknownUserStr);
        sheet.getRangeByIndex(r, 3).setNumber(entry.value.toDouble());
        sheet.getRangeByIndex(r, 1, r, 3).cellStyle = centerStyle;
        r++;
        counter++;
      }

      // Tablo başlıklarına (Personel Adı, Katıldığı Sayım) Filtre/Sıralama özelliği ekle.
      // 1. sütun (Sıra) filtre dışında bırakıldı, böylece sıralama değişse de sıra numaraları 1,2,3... diye sabit kalır.
      if (r > 9) {
        sheet.autoFilters.filterRange = sheet.getRangeByIndex(8, 2, r - 1, 3);
      }

      sheet.setColumnWidthInPixels(1, 80);
      sheet.setColumnWidthInPixels(2, 280);
      sheet.setColumnWidthInPixels(3, 180);

      // File Name logic
      final String fileName = '${monthName}_${year}_${isTr ? "Calisma_Raporu" : "Work_Report"}';

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel dosyası başarıyla indirildi:\n$savedPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExcelLoading = false);
    }
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
              Icon(Icons.table_view_rounded, color: AppColors.accentLight),
              SizedBox(width: 8),
              Text(
                AppStrings.get('export_excel', isTr ? 'tr' : 'en'),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
            Text(
              AppStrings.get('please_select_a_count_to_export_to_excel', isTr ? 'tr' : 'en'),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Sayim>>(
              stream: _sayimService.getSayimlar(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppColors.accentLight));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    AppStrings.get('no_counts_found', isTr ? 'tr' : 'en'),
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                }

                final sayimlar = snapshot.data!;

                // Ay listesini oluştur (YYYY-MM formatında benzersiz)
                final Set<String> monthsSet = {};
                for (var s in sayimlar) {
                  final key = "${s.date.year}-${s.date.month.toString().padLeft(2, '0')}";
                  monthsSet.add(key);
                }
                
                final List<String> availableMonths = monthsSet.toList()..sort((a, b) => b.compareTo(a));

                // Seçilen aya göre sayımları filtrele
                final filteredSayimlar = _selectedMonthKey == null 
                  ? <Sayim>[] 
                  : sayimlar.where((s) {
                      final key = "${s.date.year}-${s.date.month.toString().padLeft(2, '0')}";
                      return key == _selectedMonthKey;
                    }).toList();

                // Stream'den yeni nesneler gelirse referans hatası almamak için eşleşeni bul
                Sayim? currentSelectedSayim;
                if (_selectedSayim != null) {
                  try {
                    currentSelectedSayim = filteredSayimlar.firstWhere((s) => s.id == _selectedSayim!.id);
                  } catch (_) {
                    currentSelectedSayim = null;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Rapor Türü Seçimi
                    InkWell(
                      onTap: () => _showReportTypeSheet(context, isTr),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedReportType == null
                                    ? AppStrings.get('report_type', isTr ? 'tr' : 'en')
                                    : (_selectedReportType == 'sayim'
                                        ? AppStrings.get('report_type_sayim', isTr ? 'tr' : 'en')
                                        : AppStrings.get('report_type_aylik', isTr ? 'tr' : 'en')),
                                style: TextStyle(
                                  color: _selectedReportType == null ? AppColors.textHint : AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Ay Seçimi
                    InkWell(
                      onTap: _selectedReportType == null
                          ? null
                          : () => _showMonthSheet(context, isTr, availableMonths),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedReportType == null ? AppColors.card.withOpacity(0.5) : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedReportType == null
                                    ? AppStrings.get('select_report_type_first', isTr ? 'tr' : 'en')
                                    : (_selectedMonthKey == null || !availableMonths.contains(_selectedMonthKey)
                                        ? AppStrings.get('select_month', isTr ? 'tr' : 'en')
                                        : (() {
                                            final parts = _selectedMonthKey!.split('-');
                                            final year = parts[0];
                                            final month = int.parse(parts[1]);
                                            return '${AppStrings.getMonth(month, isTr ? 'tr' : 'en')} $year';
                                          })()),
                                style: TextStyle(
                                  color: _selectedReportType == null || _selectedMonthKey == null || !availableMonths.contains(_selectedMonthKey)
                                      ? AppColors.textHint.withOpacity(_selectedReportType == null ? 0.5 : 1.0)
                                      : AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedReportType == 'aylik') ...[
                      const SizedBox(height: 16),
                      // İl Seçimi
                      InkWell(
                        onTap: _selectedMonthKey == null
                            ? null
                            : () => _showCitySheet(context, isTr),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedMonthKey == null ? AppColors.card.withOpacity(0.5) : AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedMonthKey == null
                                      ? AppStrings.get('select_month_first', isTr ? 'tr' : 'en')
                                      : (_selectedCity ?? (isTr ? 'İl Seçin' : 'Select City')),
                                  style: TextStyle(
                                    color: _selectedMonthKey == null || _selectedCity == null
                                        ? AppColors.textHint.withOpacity(_selectedMonthKey == null ? 0.5 : 1.0)
                                        : AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_selectedReportType == 'sayim') ...[
                      const SizedBox(height: 16),
                      // Sayım Seçimi
                      InkWell(
                        onTap: _selectedMonthKey == null
                            ? null
                            : () => _showSayimSheet(context, isTr, filteredSayimlar),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedMonthKey == null ? AppColors.card.withOpacity(0.5) : AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedMonthKey == null
                                      ? AppStrings.get('select_month_first', isTr ? 'tr' : 'en')
                                      : (currentSelectedSayim == null
                                          ? AppStrings.get('select_count', isTr ? 'tr' : 'en')
                                          : '${currentSelectedSayim!.firmaAdi} ${currentSelectedSayim!.note} (${DateFormat('dd.MM.yyyy').format(currentSelectedSayim!.date)})'),
                                  style: TextStyle(
                                    color: _selectedMonthKey == null || currentSelectedSayim == null
                                        ? AppColors.textHint.withOpacity(_selectedMonthKey == null ? 0.5 : 1.0)
                                        : AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            if (_selectedReportType == 'sayim' && _selectedSayim != null) 
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('count_summary', isTr ? 'tr' : 'en'),
                      style: TextStyle(
                        color: AppColors.accentLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(Icons.business_rounded, _selectedSayim!.firmaAdi.isNotEmpty ? _selectedSayim!.firmaAdi : (isTr ? 'Bilinmeyen Firma' : 'Unknown Company')),
                    const SizedBox(height: 8),
                    _buildSummaryRow(Icons.location_on_rounded, _selectedSayim!.note),
                    const SizedBox(height: 8),
                    _buildSummaryRow(Icons.calendar_month_rounded, DateFormat('dd.MM.yyyy').format(_selectedSayim!.date)),
                    if (_isSummaryExpanded) ...[
                      if (_selectedSayim!.startTime != null && _selectedSayim!.startTime!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildSummaryRow(Icons.access_time_rounded, '${isTr ? 'Başlangıç Saati:' : 'Start Time:'} ${_selectedSayim!.startTime!}'),
                      ],
                      if (_selectedSayim!.gruplar.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final gruplarText = _selectedSayim!.gruplar.map((g) => g.saat).where((s) => s.isNotEmpty).join(', ');
                            if (gruplarText.isEmpty) return const SizedBox.shrink();
                            return Column(
                              children: [
                                const SizedBox(height: 8),
                                _buildSummaryRow(Icons.schedule_rounded, '${isTr ? 'Saat Grupları:' : 'Time Groups:'} $gruplarText'),
                              ],
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      FutureBuilder<List<Davet>>(
                        future: _davetService.getDavetlerBySayimFuture(_selectedSayim!.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildSummaryRow(Icons.check_circle_outline_rounded, isTr ? 'Kişi Sayısı: Yükleniyor...' : 'Participants: Loading...');
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return _buildSummaryRow(Icons.error_outline_rounded, isTr ? 'Kişi Sayısı: Hata' : 'Participants: Error');
                          }
                          final davetler = snapshot.data!;
                          final acceptedDavetler = davetler.where((d) => d.status == DavetStatus.accepted).toList();
                          final managerDavetler = acceptedDavetler.where((d) => d.role == DavetRole.manager).toList();
                          final personnelDavetler = acceptedDavetler.where((d) => d.role != DavetRole.manager).toList();
                          
                          final acceptedText = isTr
                              ? 'Kişi Sayısı: ${personnelDavetler.length}+${managerDavetler.length}'
                              : 'Participants: ${personnelDavetler.length}+${managerDavetler.length}';
                          return _buildSummaryRow(Icons.how_to_reg_rounded, acceptedText);
                        },
                      ),
                    ],
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSummaryExpanded = !_isSummaryExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSummaryExpanded 
                                  ? (isTr ? 'Daha az göster' : 'Show less') 
                                  : (isTr ? 'Daha fazla göster' : 'Show more'),
                              style: TextStyle(
                                color: AppColors.accentLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              _isSummaryExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.accentLight,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      if ((_selectedReportType == 'sayim' && _selectedSayim != null) ||
          (_selectedReportType == 'aylik' && _selectedMonthKey != null && _selectedCity != null)) 
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _isExcelLoading ? null : _exportToExcel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _isExcelLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  AppStrings.get('download_excel', isTr ? 'tr' : 'en'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (_selectedReportType == 'sayim') ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isPngLoading ? null : _exportToPng,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLight.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isPngLoading 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.image_rounded),
                  label: Text(
                    isTr ? 'Ekran Görüntüsü Al' : 'Take Screenshot',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
            ],
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

  Widget _buildSummaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _showReportTypeSheet(BuildContext context, bool isTr) async {
    String searchQuery = '';
    
    final allTypes = [
      {'value': 'sayim', 'label': AppStrings.get('report_type_sayim', isTr ? 'tr' : 'en')},
      {'value': 'aylik', 'label': AppStrings.get('report_type_aylik', isTr ? 'tr' : 'en')},
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filteredTypes = allTypes.where((t) {
              final q = searchQuery.toLowerCase();
              return t['label']!.toLowerCase().contains(q);
            }).toList();
            
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        AppStrings.get('report_type', isTr ? 'tr' : 'en'),
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
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
                        itemCount: filteredTypes.length,
                        itemBuilder: (context, index) {
                          final type = filteredTypes[index];
                          return Container(
                            color: index % 2 == 0 ? AppColors.surface : Colors.transparent,
                            child: ListTile(
                              title: Text(type['label']!, style: TextStyle(color: AppColors.textPrimary)),
                              onTap: () {
                                setState(() {
                                  _selectedReportType = type['value'];
                                  _selectedMonthKey = null;
                                  _selectedSayim = null;
                                  _selectedCity = null;
                                });
                                Navigator.pop(context);
                              },
                            ),
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

  Future<void> _showMonthSheet(BuildContext context, bool isTr, List<String> availableMonths) async {
    String searchQuery = '';
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final List<Map<String, String>> allMonthsMap = availableMonths.map((mKey) {
              final parts = mKey.split('-');
              final year = parts[0];
              final month = int.parse(parts[1]);
              final monthName = AppStrings.getMonth(month, isTr ? 'tr' : 'en');
              return {'key': mKey, 'label': '$monthName $year'};
            }).toList();

            final filteredMonths = allMonthsMap.where((m) {
              final q = searchQuery.toLowerCase();
              return m['label']!.toLowerCase().contains(q);
            }).toList();
            
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        AppStrings.get('select_month', isTr ? 'tr' : 'en'),
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
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
                        itemCount: filteredMonths.length,
                        itemBuilder: (context, index) {
                          final m = filteredMonths[index];
                          return Container(
                            color: index % 2 == 0 ? AppColors.surface : Colors.transparent,
                            child: ListTile(
                              title: Text(m['label']!, style: TextStyle(color: AppColors.textPrimary)),
                              onTap: () {
                                setState(() {
                                  _selectedMonthKey = m['key'];
                                  _selectedSayim = null;
                                  _selectedCity = null;
                                });
                                Navigator.pop(context);
                              },
                            ),
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

  Future<void> _showCitySheet(BuildContext context, bool isTr) async {
    final cities = ['Denizli', 'Muğla'];
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isTr ? 'İl Seçin' : 'Select City',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...cities.map((c) => ListTile(
              title: Text(c, style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                setState(() {
                  _selectedCity = c;
                });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        );
      }
    );
  }

  Future<void> _showSayimSheet(BuildContext context, bool isTr, List<Sayim> filteredSayimlar) async {
    String searchQuery = '';
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final List<Map<String, dynamic>> allSayimsMap = filteredSayimlar.map((sayim) {
              final dateStr = DateFormat('dd.MM.yyyy').format(sayim.date);
              final label = '${sayim.firmaAdi} ${sayim.note} ($dateStr)';
              return {'sayim': sayim, 'label': label};
            }).toList();

            final filtered = allSayimsMap.where((s) {
              final q = searchQuery.toLowerCase();
              return s['label']!.toLowerCase().contains(q);
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
                        AppStrings.get('select_count', isTr ? 'tr' : 'en'),
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
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
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Container(
                            color: index % 2 == 0 ? AppColors.surface : Colors.transparent,
                            child: ListTile(
                              title: Text(item['label']!, style: TextStyle(color: AppColors.textPrimary)),
                              onTap: () {
                                setState(() {
                                  _selectedSayim = item['sayim'];
                                });
                                Navigator.pop(context);
                              },
                            ),
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
}
