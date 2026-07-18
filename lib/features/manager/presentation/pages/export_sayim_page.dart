import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart' as ex;
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/services/sayim_service.dart';
import '../../../../core/services/davet_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';

class ExportSayimPage extends StatefulWidget {
  final LanguageService lang;

  const ExportSayimPage({
    super.key,
    required this.lang,
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

  Future<void> _exportToExcel() async {
    if (_selectedSayim == null) return;

    setState(() => _isLoading = true);
    
    try {
      // 1. İzin İsteği
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }

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
      var excel = ex.Excel.createExcel();
      ex.Sheet sheetObject = excel['Sayım Raporu'];
      excel.setDefaultSheet('Sayım Raporu');

      ex.CellStyle headerStyle = ex.CellStyle(
        bold: true,
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        horizontalAlign: ex.HorizontalAlign.Center,
      );

      var rowHeader = ['İsim Soyisim', 'Görevi', 'Saat Grubu', 'Ücret', 'Kabul/Red Durumu'];
      sheetObject.appendRow(rowHeader.map((e) => ex.TextCellValue(e)).toList());

      for (int col = 0; col < rowHeader.length; col++) {
        var cell = sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.cellStyle = headerStyle;
      }

      // 5. Verileri Ekle
      for (var davet in acceptedDavetler) {
        final user = userMap[davet.userId];
        final fullName = user?.fullName ?? 'Bilinmeyen Kullanıcı';
        final roleStr = user?.isManager == true ? 'Yönetici' : 'Personel';
        
        final grup = _selectedSayim!.gruplar.firstWhere(
          (g) => g.grupId == davet.grupId,
          orElse: () => const SayimGrup(grupId: 1, saat: ''),
        );

        sheetObject.appendRow([
          ex.TextCellValue(fullName),
          ex.TextCellValue(roleStr),
          ex.TextCellValue(grup.saat),
          ex.DoubleCellValue(davet.ucret),
          ex.TextCellValue('Kabul Edildi'),
        ]);
      }

      // 6. Dosyayı Kaydet
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedSayim!.date);
      final safeName = _selectedSayim!.note.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\s]'), '').trim();
      final String fileName = 'Sayim_$safeName\_$dateStr.xlsx';
      final String filePath = '${directory!.path}/$fileName';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel dosyası başarıyla indirildi:\n$filePath'),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isTr ? 'Excel Çıktısı Al' : 'Export Excel',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isTr ? 'Lütfen Excel çıktısı almak istediğiniz sayımı seçin.' : 'Please select a count to export to Excel.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Sayim>>(
              stream: _sayimService.getSayimlar(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accentLight));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    isTr ? 'Henüz hiç sayım yok.' : 'No counts found.',
                    style: const TextStyle(color: AppColors.textSecondary),
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
                  value: _selectedSayim,
                  hint: Text(
                    isTr ? 'Sayım Seçin' : 'Select Count',
                    style: const TextStyle(color: AppColors.textHint),
                  ),
                  items: sayimlar.map((sayim) {
                    final dateStr = DateFormat('dd.MM.yyyy').format(sayim.date);
                    return DropdownMenuItem<Sayim>(
                      value: sayim,
                      child: Text(
                        '${sayim.note} ($dateStr)',
                        style: const TextStyle(color: AppColors.textPrimary),
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
                      isTr ? 'Sayım Özeti' : 'Count Summary',
                      style: const TextStyle(
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
                    _buildSummaryRow(Icons.groups_rounded, '${_selectedSayim!.invitedUserIds.length} ${isTr ? "Kişi Davet Edildi" : "Invited"}'),
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
                  isTr ? 'Excel İndir' : 'Download Excel',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
