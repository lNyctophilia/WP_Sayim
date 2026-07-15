import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/sayim_service.dart';
import '../../../../core/services/davet_service.dart';
import '../widgets/grup_selector.dart';
import '../widgets/staff_picker.dart';

class EditSayimPage extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final Sayim sayim;
  final List<Davet> existingDavets;

  const EditSayimPage({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.sayim,
    required this.existingDavets,
  });

  @override
  State<EditSayimPage> createState() => _EditSayimPageState();
}

class _EditSayimPageState extends State<EditSayimPage> {
  final _formKey = GlobalKey<FormState>();
  final _sayimService = SayimService();
  final _davetService = DavetService();
  final _authService = AuthService();

  final _noteController = TextEditingController();
  final _maxKisiController = TextEditingController(text: '20');
  DateTime _selectedDate = DateTime.now();
  
  SehirTipi _sehirTipi = SehirTipi.ici;
  double _globalMultiplier = 1.0;

  List<SayimGrup> _gruplar = [];
  List<AppUser> _allUsers = [];
  List<SelectedUserConfig> _selectedUsers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.sayim.note;
    _maxKisiController.text = widget.sayim.maxKisi.toString();
    _selectedDate = widget.sayim.date;
    _sehirTipi = widget.sayim.sehirTipi;
    _globalMultiplier = widget.sayim.globalMultiplier;
    _gruplar = List.from(widget.sayim.gruplar);

    _loadUsers();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _maxKisiController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.getAllUsers();
      
      final selected = <SelectedUserConfig>[];
      for (var davet in widget.existingDavets) {
        try {
          final u = users.firstWhere((usr) => usr.id == davet.userId);
          selected.add(SelectedUserConfig(
            user: u,
            role: davet.role,
            grupId: davet.grupId,
            ucret: davet.ucret,
            multiplier: davet.multiplier,
            isSelected: true,
          ));
        } catch (_) {}
      }

      setState(() {
        _allUsers = users;
        _selectedUsers = selected;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentLight,
              surface: AppColors.card,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_gruplar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.lang.currentLang == 'tr' ? 'En az bir saat grubu eklemelisiniz.' : 'You must add at least one time group.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Sayımı güncelle
      final updatedSayim = widget.sayim.copyWith(
        note: _noteController.text.trim(),
        date: _selectedDate,
        maxKisi: int.tryParse(_maxKisiController.text) ?? 20,
        gruplar: _gruplar,
        invitedUserIds: _selectedUsers.map((e) => e.user.id).toList(),
        sehirTipi: _sehirTipi,
        globalMultiplier: _globalMultiplier,
      );

      await _sayimService.updateSayim(updatedSayim);

      // 2. Davetleri yönet (Silinen, Eklenen, Güncellenen)
      for (var davet in widget.existingDavets) {
        final configIndex = _selectedUsers.indexWhere((c) => c.user.id == davet.userId);
        if (configIndex == -1) {
          await _davetService.deleteDavet(davet.id);
        } else {
          final config = _selectedUsers[configIndex];
          if (config.ucret != davet.ucret || config.grupId != davet.grupId || (config.multiplier ?? 1.0) != davet.multiplier) {
            await _davetService.updateDavetDetails(davet.id, config.ucret, config.grupId, config.multiplier ?? 1.0);
          }
        }
      }

      for (var config in _selectedUsers) {
        final existing = widget.existingDavets.any((d) => d.userId == config.user.id);
        if (!existing) {
          final newDavet = Davet(
            id: '', 
            sayimId: updatedSayim.id,
            userId: config.user.id,
            role: config.role,
            grupId: config.grupId,
            sehirIciDisi: _sehirTipi,
            ucret: config.ucret,
            multiplier: config.multiplier,
            createdAt: DateTime.now(),
          );
          final createdId = await _davetService.createDavet(newDavet);
          if (config.user.id == widget.currentUser.id) {
            await _davetService.acceptDavet(createdId);
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.lang.currentLang == 'tr' ? 'Sayım başarıyla güncellendi.' : 'Count updated successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text(
          isTr ? 'Sayımı Düzenle' : 'Edit Count',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading && _allUsers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentLight))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TEMEL BİLGİLER ---
                    _buildSectionTitle(isTr ? 'Temel Bilgiler' : 'Basic Info'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: isTr ? 'Not / İş / Yer' : 'Note / Job / Location',
                        labelStyle: const TextStyle(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.place_rounded, color: AppColors.textSecondary),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? (isTr ? 'Boş bırakılamaz' : 'Cannot be empty')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxKisiController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: isTr ? 'Max Kişi' : 'Max Persons',
                              labelStyle: const TextStyle(color: AppColors.textHint),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.group_rounded, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<SehirTipi>(
                            value: _sehirTipi,
                            decoration: InputDecoration(
                              labelText: isTr ? 'Şehir İçi/Dışı' : 'City Type',
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            dropdownColor: AppColors.card,
                            items: [
                              DropdownMenuItem(value: SehirTipi.ici, child: Text(isTr ? 'Şehir İçi' : 'In-City', style: const TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: SehirTipi.disi, child: Text(isTr ? 'Şehir Dışı' : 'Out-of-City', style: const TextStyle(color: AppColors.textPrimary))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _sehirTipi = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<double>(
                            value: _globalMultiplier,
                            decoration: InputDecoration(
                              labelText: isTr ? 'Genel Çarpan' : 'Global Multiplier',
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            dropdownColor: AppColors.card,
                            items: [1.0, 1.5, 2.0].map((m) {
                              return DropdownMenuItem(value: m, child: Text('${m}x', style: const TextStyle(color: AppColors.textPrimary)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _globalMultiplier = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.surface),
                    const SizedBox(height: 16),

                    // --- GRUP SEÇİMİ ---
                    GrupSelector(
                      initialGruplar: _gruplar,
                      isTr: isTr,
                      onChanged: (gruplar) {
                        setState(() {
                          _gruplar = gruplar;
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppColors.surface),
                    const SizedBox(height: 16),

                    // --- PERSONEL SEÇİMİ ---
                    StaffPicker(
                      users: _allUsers,
                      availableGroups: _gruplar,
                      isTr: isTr,
                      currentUser: widget.currentUser,
                      sayimSehirTipi: _sehirTipi,
                      globalMultiplier: _globalMultiplier,
                      initialSelections: _selectedUsers,
                      onSelectionChanged: (selected) {
                        setState(() {
                          _selectedUsers = selected;
                        });
                      },
                    ),

                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isTr ? 'Güncelle' : 'Update',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
