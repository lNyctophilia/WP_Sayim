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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.storage.setLastPanel('export');
  }

  Future<void> _exportToExcel() async {
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

      // Title
      sheet.getRangeByIndex(1, 1).setText('Konum: ${_selectedSayim!.note}');
      sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 12;
      sheet.getRangeByIndex(1, 1, 1, 2).merge();

      // Date
      final dateStrFormatted = DateFormat('dd.MM.yyyy').format(_selectedSayim!.date);
      sheet.getRangeByIndex(2, 1).setText('Tarih: $dateStrFormatted');
      sheet.getRangeByIndex(2, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(2, 1).cellStyle.fontSize = 12;
      sheet.getRangeByIndex(2, 1, 2, 2).merge();

      final managerDavetler = acceptedDavetler.where((d) => userMap[d.userId]?.isManager == true).toList();
      final personnelDavetler = acceptedDavetler.where((d) => userMap[d.userId]?.isManager != true).toList();

      int currentRow = 4;

      void addSection(String sectionTitle, List<Davet> davetList) {
        // Section Title
        sheet.getRangeByIndex(currentRow, 1).setText(sectionTitle);
        sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
        sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 12;
        sheet.getRangeByIndex(currentRow, 1, currentRow, 2).merge();
        currentRow++;

        // Table Header
        sheet.getRangeByIndex(currentRow, 1).setText('İsim Soyisim');
        sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
        sheet.getRangeByIndex(currentRow, 1).cellStyle.hAlign = xlsio.HAlignType.center;
        currentRow++;

        // Table Data
        if (davetList.isEmpty) {
          sheet.getRangeByIndex(currentRow, 1).setText('Kayıt bulunamadı.');
          sheet.getRangeByIndex(currentRow, 1, currentRow, 2).merge();
          currentRow++;
        } else {
          for (var davet in davetList) {
            final user = userMap[davet.userId];
            final fullName = user?.fullName ?? 'Bilinmeyen Kullanıcı';

            sheet.getRangeByIndex(currentRow, 1).setText(fullName);
            sheet.getRangeByIndex(currentRow, 1).cellStyle.hAlign = xlsio.HAlignType.left;
            currentRow++;
          }
        }
        
        currentRow++;
      }

      addSection('Yöneticiler', managerDavetler);
      addSection('Personeller', personnelDavetler);

      sheet.setColumnWidthInPixels(1, 250);

      // 6. Dosyayı Kaydet
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedSayim!.date);
      final String fileName = 'Sayim_Detay_$dateStr';

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

                return DropdownButtonFormField<Sayim>(
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
                  initialValue: _selectedSayim,
                  hint: Text(
                    AppStrings.get('select_count', isTr ? 'tr' : 'en'),
                    style: TextStyle(color: AppColors.textHint),
                  ),
                  items: sayimlar.map((sayim) {
                    final dateStr = DateFormat('dd.MM.yyyy').format(sayim.date);
                    return DropdownMenuItem<Sayim>(
                      value: sayim,
                      child: Text(
                        '${sayim.note} ($dateStr)',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSayim = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            if (_selectedSayim != null) ...[
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
                    const SizedBox(height: 8),
                    _buildSummaryRow(Icons.groups_rounded, '${_selectedSayim!.invitedUserIds.length} ${AppStrings.get('invited', isTr ? 'tr' : 'en')}'),
                  ],
                ),
              ),
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
