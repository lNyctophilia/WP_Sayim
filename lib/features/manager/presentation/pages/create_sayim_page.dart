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

class CreateSayimPage extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;

  const CreateSayimPage({
    super.key,
    required this.currentUser,
    required this.lang,
  });

  @override
  State<CreateSayimPage> createState() => _CreateSayimPageState();
}

class _CreateSayimPageState extends State<CreateSayimPage> {
  final _formKey = GlobalKey<FormState>();
  final _sayimService = SayimService();
  final _davetService = DavetService();
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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _allUsers = users;
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

    if (selectedPersonel != targetPersonel || selectedYonetici != targetYonetici) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.lang.currentLang == 'tr' 
              ? 'Seçilen personel veya yönetici sayısı standart sayı ile tam olarak eşleşmiyor!\nPersonel: $selectedPersonel/$targetPersonel, Yönetici: $selectedYonetici/$targetYonetici'
              : 'Selected personnel or manager count does not exactly match the standard!\nPersonnel: $selectedPersonel/$targetPersonel, Manager: $selectedYonetici/$targetYonetici'
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
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
        gruplar: _gruplar,
        invitedUserIds: _selectedUsers.map((e) => e.user.id).toList(),
        sehirTipi: _sehirTipi,
        globalMultiplier: _globalMultiplier,
        createdAt: DateTime.now(),
      );

      final sayimId = await _sayimService.createSayim(sayim);

      // 2. Davetleri oluştur
      for (var config in _selectedUsers) {
        final davet = Davet(
          id: '', // Firestore auto-id
          sayimId: sayimId,
          userId: config.user.id,
          role: config.role,
          grupId: config.grupId,
          sehirIciDisi: _sehirTipi, // Sayımın şehrini kullanıyoruz
          ucret: config.ucret,
          multiplier: config.multiplier,
          createdAt: DateTime.now(),
        );
        final createdDavetId = await _davetService.createDavet(davet);

        // Kendi oluşturduğu sayımda kendine davet atıyorsa otomatik kabul et
        if (config.user.id == widget.currentUser.id) {
          await _davetService.acceptDavet(createdDavetId);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.lang.currentLang == 'tr' ? 'Sayım başarıyla oluşturuldu ve davetler gönderildi.' : 'Count created successfully and invitations sent.'),
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
          isTr ? 'Yeni Sayım Oluştur' : 'Create New Count',
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
                      targetPersonel: int.tryParse(_maxKisiController.text) ?? 0,
                      targetYonetici: int.tryParse(_maxYoneticiController.text) ?? 0,
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
                                isTr ? 'Davet Gönder' : 'Send Invitations',
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
