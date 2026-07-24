import 'package:daytrack/core/constants/app_strings.dart';
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
  List<String> _busyUserIds = [];

  bool _isLoading = false;

  DateTime? _lastSnackBarTime;
  String? _lastSnackBarMsg;

  void _showErrorSnackBar(String msg) {
    final now = DateTime.now();
    
    if (_lastSnackBarTime != null && 
        msg == _lastSnackBarMsg && 
        now.difference(_lastSnackBarTime!).inMilliseconds < 2500) {
      return;
    }

    _lastSnackBarTime = now;
    _lastSnackBarMsg = msg;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

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
      final busyUsers = await _sayimService.getBusyUsersOnDate(_selectedDate);
      setState(() {
        _allUsers = users;
        _busyUserIds = busyUsers;
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Hata: $e');
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
            colorScheme: ColorScheme.dark(
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
    if (_noteController.text.trim().isEmpty) {
      final isTr = widget.lang.currentLang == 'tr';
      _showErrorSnackBar(AppStrings.get('cannot_be_empty', isTr ? 'tr' : 'en'));
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    
    if (_gruplar.isEmpty) {
      _showErrorSnackBar(AppStrings.get('add_time_group_error', widget.lang.currentLang));
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
      _showErrorSnackBar(
        AppStrings.getFormat('too_many_people_error', widget.lang.currentLang, [selectedPersonel, targetPersonel, selectedYonetici, targetYonetici])
      );
      return;
    } else if (selectedPersonel < targetPersonel || selectedYonetici < targetYonetici) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(AppStrings.get('missing_personnel_title', widget.lang.currentLang), style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
            AppStrings.getFormat('not_enough_people_msg', widget.lang.currentLang, [targetPersonel - selectedPersonel, targetYonetici - selectedYonetici]),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.get('cancel', widget.lang.currentLang), style: TextStyle(color: AppColors.textHint)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.get('create', widget.lang.currentLang), style: TextStyle(color: AppColors.accentLight)),
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
            content: Text(AppStrings.get('count_created_sent', widget.lang.currentLang)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Hata: $e');
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
          AppStrings.get('create_new_count', isTr ? 'tr' : 'en'),
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading && _allUsers.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppColors.accentLight))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TEMEL BİLGİLER ---
                    _buildSectionTitle(AppStrings.get('basic_info', isTr ? 'tr' : 'en')),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: AppStrings.get('note_job_location', isTr ? 'tr' : 'en'),
                        labelStyle: TextStyle(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.place_rounded, color: AppColors.textSecondary),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? (AppStrings.get('cannot_be_empty', isTr ? 'tr' : 'en'))
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
                            Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
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
                            style: TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: AppStrings.get('standard_personnel', isTr ? 'tr' : 'en'),
                              labelStyle: TextStyle(color: AppColors.textHint),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(Icons.group_rounded, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxYoneticiController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState((){}),
                            style: TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: AppStrings.get('standard_manager', isTr ? 'tr' : 'en'),
                              labelStyle: TextStyle(color: AppColors.textHint),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(Icons.supervisor_account_rounded, color: AppColors.textSecondary),
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
                              labelText: AppStrings.get('city_type', isTr ? 'tr' : 'en'),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            dropdownColor: AppColors.card,
                            items: [
                              DropdownMenuItem(value: SehirTipi.ici, child: Text(AppStrings.get('in_city', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: SehirTipi.disi, child: Text(AppStrings.get('out_of_city', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary))),
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
                              labelText: AppStrings.get('global_multiplier', isTr ? 'tr' : 'en'),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            dropdownColor: AppColors.card,
                            items: [1.0, 1.5, 2.0].map((m) {
                              return DropdownMenuItem(value: m, child: Text('${m}x', style: TextStyle(color: AppColors.textPrimary)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _globalMultiplier = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    Divider(color: AppColors.surface),
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

                    SizedBox(height: 24),
                    Divider(color: AppColors.surface),
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
                                AppStrings.get('send_invitations', isTr ? 'tr' : 'en'),
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
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
