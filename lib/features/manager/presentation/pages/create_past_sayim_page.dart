import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/sayim_service.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/grup_selector.dart';
import '../widgets/staff_picker.dart';
import '../widgets/manager_drawer.dart';
import '../../../../features/home/presentation/widgets/custom_top_bar.dart';
import 'manager_panel_page.dart';

class CreatePastSayimPage extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final StorageService storage;
  final bool isEmbedded;

  const CreatePastSayimPage({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.storage,
    this.isEmbedded = false,
  });

  @override
  State<CreatePastSayimPage> createState() => _CreatePastSayimPageState();
}

class _CreatePastSayimPageState extends State<CreatePastSayimPage> {
  final _formKey = GlobalKey<FormState>();
  final _sayimService = SayimService();
  final _authService = AuthService();

  final _noteController = TextEditingController();
  final _maxKisiController = TextEditingController(text: '20');
  final _maxYoneticiController = TextEditingController(text: '2');
  DateTime _selectedDate = DateTime.now();
  
  SehirTipi _sehirTipi = SehirTipi.ici;
  double _globalMultiplier = 1.0;

  List<SayimGrup> _gruplar = [];
  List<AppUser> _allUsers = [];
  List<SelectedUserConfig> _selectedUsers = [];
  List<String> _busyUserIds = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.storage.setLastPanel('create_past');
    _loadUsers();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _maxKisiController.dispose();
    _maxYoneticiController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.getAllUsers();
      final busyUsers = await _sayimService.getBusyUsersOnDate(_selectedDate);
      setState(() {
        _allUsers = users;
        _busyUserIds = busyUsers;
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
      firstDate: DateTime(2020),
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
        _isLoading = true;
      });
      try {
        final busyUsers = await _sayimService.getBusyUsersOnDate(picked);
        if (mounted) {
          setState(() {
            _busyUserIds = busyUsers;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
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

    final targetPersonel = int.tryParse(_maxKisiController.text) ?? 20;
    final targetYonetici = int.tryParse(_maxYoneticiController.text) ?? 2;

    int selectedPersonel = 0;
    int selectedYonetici = 0;
    for (var config in _selectedUsers) {
      if (config.role == DavetRole.staff) {
        selectedPersonel++;
      } else if (config.role == DavetRole.manager) {
        selectedYonetici++;
      }
    }

    if (selectedPersonel > targetPersonel || selectedYonetici > targetYonetici) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.lang.currentLang == 'tr' 
              ? 'Standart sayıdan fazla kişi seçemezsiniz!\nPersonel: $selectedPersonel/$targetPersonel, Yönetici: $selectedYonetici/$targetYonetici'
              : 'You cannot select more people than the standard count!\nPersonnel: $selectedPersonel/$targetPersonel, Manager: $selectedYonetici/$targetYonetici'
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    } else if (selectedPersonel < targetPersonel || selectedYonetici < targetYonetici) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(widget.lang.currentLang == 'tr' ? 'Eksik Kişi Seçimi' : 'Missing Personnel', style: const TextStyle(color: AppColors.textPrimary)),
          content: Text(
            widget.lang.currentLang == 'tr' 
              ? 'Sayım için hedeflenen sayıdan az kişi seçtiniz.\nEksik Personel: ${targetPersonel - selectedPersonel}\nEksik Yönetici: ${targetYonetici - selectedYonetici}\nYine de oluşturmak istiyor musunuz? (Sonradan kişi ekleyebilirsiniz)'
              : 'You have selected fewer people than targeted.\nMissing Personnel: ${targetPersonel - selectedPersonel}\nMissing Manager: ${targetYonetici - selectedYonetici}\nDo you still want to create it? (You can add people later)',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(widget.lang.currentLang == 'tr' ? 'İptal' : 'Cancel', style: const TextStyle(color: AppColors.textHint)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(widget.lang.currentLang == 'tr' ? 'Oluştur' : 'Create', style: const TextStyle(color: AppColors.accentLight)),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // 1. Sayım oluştur
      final sayim = Sayim(
        id: '', // Firestore auto-id
        note: _noteController.text.trim(),
        date: _selectedDate,
        maxKisi: targetPersonel,
        maxYonetici: targetYonetici,
        createdBy: widget.currentUser.id,
        status: SayimStatus.closed,
        gruplar: _gruplar,
        invitedUserIds: _selectedUsers.map((e) => e.user.id).toList(),
        sehirTipi: _sehirTipi,
        globalMultiplier: _globalMultiplier,
        isPast: true,
        createdAt: DateTime.now(),
      );

      // 2. Davetleri hazırla
      final davetler = _selectedUsers.map((config) {
        return Davet(
          id: '', // Firestore auto-id
          sayimId: '', // Serviste ayarlanacak
          userId: config.user.id,
          status: DavetStatus.accepted,
          role: config.role,
          grupId: config.grupId,
          sehirIciDisi: _sehirTipi,
          ucret: config.ucret,
          multiplier: config.multiplier,
          isPast: true,
          respondedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );
      }).toList();

      await _sayimService.createPastSayimFull(sayim, davetler);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.lang.currentLang == 'tr' ? 'Geçmiş sayım başarıyla kaydedildi.' : 'Past count saved successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ManagerPanelPage(
              currentUser: widget.currentUser,
              storage: widget.storage,
              lang: widget.lang,
              onLogout: () {},
            ),
            transitionDuration: Duration.zero,
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

    Widget content = Column(
      children: [
        if (!widget.isEmbedded)
          CustomTopBar(currentUser: widget.currentUser, lang: widget.lang, storage: widget.storage),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.accentLight),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Geçmiş Sayım Ekle' : 'Add Past Count',
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
          child: _isLoading && _allUsers.isEmpty
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
                    InkWell(
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _maxKisiController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState((){}),
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: isTr ? 'Standart Personel' : 'Standard Personnel',
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxYoneticiController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState((){}),
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: isTr ? 'Standart Yönetici' : 'Standard Manager',
                              labelStyle: const TextStyle(color: AppColors.textHint),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.supervisor_account_rounded, color: AppColors.textSecondary),
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
                              labelText: isTr ? 'Yevmiye Çarpanı' : 'Global Multiplier',
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
                      targetPersonel: int.tryParse(_maxKisiController.text) ?? 0,
                      targetYonetici: int.tryParse(_maxYoneticiController.text) ?? 0,
                      busyUserIds: _busyUserIds,
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
                                isTr ? 'Sayımı Kaydet' : 'Save Count',
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
        ),
        body: SafeArea(child: content),
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
