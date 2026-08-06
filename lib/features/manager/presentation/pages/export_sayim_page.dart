import 'package:daytrack/core/constants/app_strings.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
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
  String? _selectedReportType;
  bool _isLoading = false;

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

  Future<void> _exportSayimRaporu() async {
    if (_selectedSayim == null) return;

    setState(() => _isLoading = true);
    
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportAylikRapor() async {
    if (_selectedMonthKey == null) return;
    
    setState(() => _isLoading = true);
    final isTr = widget.lang.currentLang == 'tr';
    final unknownUserStr = AppStrings.get('unknown_user', isTr ? 'tr' : 'en');
    
    try {
      // 1. Get all counts for the month
      final sayimlar = await _sayimService.getSayimlar().first;
      final filteredSayimlar = sayimlar.where((s) {
        final key = "${s.date.year}-${s.date.month.toString().padLeft(2, '0')}";
        return key == _selectedMonthKey;
      }).toList();

      if (filteredSayimlar.isEmpty) {
        throw Exception(AppStrings.get('no_counts_found', isTr ? 'tr' : 'en'));
      }

      // 2. Fetch davets for all counts
      final Map<String, int> userWorkCount = {};
      int totalPersonelCalistirma = 0;
      int totalSayim = filteredSayimlar.length;
      
      final Map<String, AppUser> userMap = {};
      final allUsers = await _authService.getAllUsers();
      for (var u in allUsers) {
        userMap[u.id] = u;
      }

      for (var sayim in filteredSayimlar) {
        final davetler = await _davetService.getDavetlerBySayimFuture(sayim.id);
        final acceptedDavetler = davetler.where((d) => d.status == DavetStatus.accepted).toList();
        
        for (var d in acceptedDavetler) {
          userWorkCount[d.userId] = (userWorkCount[d.userId] ?? 0) + 1;
          totalPersonelCalistirma++;
        }
      }

      // 3. Sort users A-Z
      final List<MapEntry<String, int>> sortedUsers = userWorkCount.entries.toList();
      
      sortedUsers.sort((a, b) {
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
      sheet.getRangeByIndex(2, 1, 2, 3).cellStyle = headerStyle;

      // Row 3: Summary Table Headers
      sheet.getRangeByIndex(3, 1).setText(isTr ? 'Veri Adı' : 'Data Name');
      sheet.getRangeByIndex(3, 1, 3, 2).merge();
      sheet.getRangeByIndex(3, 3).setText(isTr ? 'Miktar' : 'Amount');
      sheet.getRangeByIndex(3, 1, 3, 3).cellStyle = headerStyle;

      // Row 4: Total Counts
      sheet.getRangeByIndex(4, 1).setText(AppStrings.get('total_counts_in_month', isTr ? 'tr' : 'en').replaceAll(':', '').trim());
      sheet.getRangeByIndex(4, 1, 4, 2).merge();
      sheet.getRangeByIndex(4, 3).setNumber(totalSayim.toDouble());
      
      // Row 5: Total Shifts
      sheet.getRangeByIndex(5, 1).setText(AppStrings.get('total_personnel_shifts', isTr ? 'tr' : 'en').replaceAll(':', '').trim());
      sheet.getRangeByIndex(5, 1, 5, 2).merge();
      sheet.getRangeByIndex(5, 3).setNumber(totalPersonelCalistirma.toDouble());

      // Style for Rows 4 and 5
      sheet.getRangeByIndex(4, 1, 5, 2).cellStyle.hAlign = xlsio.HAlignType.left;
      sheet.getRangeByIndex(4, 1, 5, 2).cellStyle.vAlign = xlsio.VAlignType.center;
      sheet.getRangeByIndex(4, 1, 5, 2).cellStyle.bold = true;
      sheet.getRangeByIndex(4, 3, 5, 3).cellStyle.hAlign = xlsio.HAlignType.center;
      sheet.getRangeByIndex(4, 3, 5, 3).cellStyle.vAlign = xlsio.VAlignType.center;
      sheet.getRangeByIndex(4, 3, 5, 3).cellStyle.bold = true;

      // Row 7: Table Headers (Row 6 is left blank for separation)
      sheet.getRangeByIndex(7, 1).setText(AppStrings.get('order', isTr ? 'tr' : 'en'));
      sheet.getRangeByIndex(7, 2).setText(AppStrings.get('personnel_name', isTr ? 'tr' : 'en'));
      sheet.getRangeByIndex(7, 3).setText(AppStrings.get('participated_counts', isTr ? 'tr' : 'en'));
      sheet.getRangeByIndex(7, 1, 7, 3).cellStyle = headerStyle;

      // Data Rows
      int r = 8;
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
      setState(() => _isLoading = false);
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
          child: Padding(
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
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: AppColors.card,
                      value: _selectedReportType,
                      hint: Text(
                        AppStrings.get('report_type', isTr ? 'tr' : 'en'),
                        style: TextStyle(color: AppColors.textHint),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: 'sayim',
                          child: Text(
                            AppStrings.get('report_type_sayim', isTr ? 'tr' : 'en'),
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'aylik',
                          child: Text(
                            AppStrings.get('report_type_aylik', isTr ? 'tr' : 'en'),
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedReportType = val;
                          _selectedMonthKey = null;
                          _selectedSayim = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Ay Seçimi
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _selectedReportType == null ? AppColors.card.withOpacity(0.5) : AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: AppColors.card,
                      value: availableMonths.contains(_selectedMonthKey) ? _selectedMonthKey : null,
                      hint: Text(
                        _selectedReportType == null 
                          ? AppStrings.get('select_report_type_first', isTr ? 'tr' : 'en')
                          : AppStrings.get('select_month', isTr ? 'tr' : 'en'),
                        style: TextStyle(color: _selectedReportType == null ? AppColors.textHint.withOpacity(0.5) : AppColors.textHint),
                      ),
                      items: availableMonths.map((mKey) {
                        final parts = mKey.split('-');
                        final year = parts[0];
                        final month = int.parse(parts[1]);
                        final monthName = AppStrings.getMonth(month, isTr ? 'tr' : 'en');
                        
                        return DropdownMenuItem<String>(
                          value: mKey,
                          child: Text(
                            '$monthName $year',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: _selectedReportType == null 
                        ? null 
                        : (val) {
                            setState(() {
                              _selectedMonthKey = val;
                              _selectedSayim = null; // Ay değiştiğinde sayım seçimini sıfırla
                            });
                          },
                      disabledHint: Text(
                        AppStrings.get('select_report_type_first', isTr ? 'tr' : 'en'),
                        style: TextStyle(color: AppColors.textHint.withOpacity(0.5)),
                      ),
                    ),
                    if (_selectedReportType == 'sayim') ...[
                      const SizedBox(height: 16),
                      // Sayım Seçimi
                      DropdownButtonFormField<Sayim>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _selectedMonthKey == null ? AppColors.card.withOpacity(0.5) : AppColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        dropdownColor: AppColors.card,
                        value: currentSelectedSayim,
                        hint: Text(
                          _selectedMonthKey == null 
                            ? AppStrings.get('select_month_first', isTr ? 'tr' : 'en')
                            : AppStrings.get('select_count', isTr ? 'tr' : 'en'),
                          style: TextStyle(
                            color: _selectedMonthKey == null ? AppColors.textHint.withOpacity(0.5) : AppColors.textHint
                          ),
                        ),
                        items: filteredSayimlar.map((sayim) {
                          final dateStr = DateFormat('dd.MM.yyyy').format(sayim.date);
                          return DropdownMenuItem<Sayim>(
                            value: sayim,
                            child: Text(
                              '${sayim.firmaAdi} ${sayim.note} ($dateStr)',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: _selectedMonthKey == null 
                          ? null 
                          : (val) {
                              setState(() {
                                _selectedSayim = val;
                              });
                            },
                        disabledHint: Text(
                          AppStrings.get('select_month_first', isTr ? 'tr' : 'en'),
                          style: TextStyle(color: AppColors.textHint.withOpacity(0.5)),
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
                    _buildSummaryRow(Icons.location_on_rounded, _selectedSayim!.note),
                    const SizedBox(height: 8),
                    _buildSummaryRow(Icons.calendar_month_rounded, DateFormat('dd.MM.yyyy').format(_selectedSayim!.date)),
                    if (_selectedSayim!.startTime != null && _selectedSayim!.startTime!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(Icons.access_time_rounded, _selectedSayim!.startTime!),
                    ],
                    const SizedBox(height: 8),
                    _buildSummaryRow(Icons.groups_rounded, '${_selectedSayim!.invitedUserIds.length} ${AppStrings.get('invited', isTr ? 'tr' : 'en')}'),
                  ],
                ),
              ),
            
            if ((_selectedReportType == 'sayim' && _selectedSayim != null) ||
                (_selectedReportType == 'aylik' && _selectedMonthKey != null)) ...[
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _exportToExcel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _isLoading 
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
              const SizedBox(height: 32),
            ]
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
}
