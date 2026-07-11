import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/davet_service.dart';
import '../../../../core/services/sayim_service.dart';
import '../../../../core/services/language_service.dart';
import '../widgets/staff_picker.dart';

class AddPersonToSayimPage extends StatefulWidget {
  final Sayim sayim;
  final AppUser currentUser;
  final LanguageService lang;

  const AddPersonToSayimPage({
    super.key,
    required this.sayim,
    required this.currentUser,
    required this.lang,
  });

  @override
  State<AddPersonToSayimPage> createState() => _AddPersonToSayimPageState();
}

class _AddPersonToSayimPageState extends State<AddPersonToSayimPage> {
  final AuthService _authService = AuthService();
  final DavetService _davetService = DavetService();
  final SayimService _sayimService = SayimService();

  List<AppUser> _availableUsers = [];
  List<SelectedUserConfig> _selectedConfigs = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Tüm kullanıcıları getir
      final allUsers = await _authService.getAllUsers();
      
      // 2. Bu sayıma ait mevcut davetleri getir
      // Stream olduğu için ilk veriyi alıp kapatıyoruz
      final davetlerStream = _davetService.getDavetlerBySayim(widget.sayim.id);
      final davetlerList = await davetlerStream.first;
      
      // 3. Zaten davet edilmiş kullanıcıların ID'lerini bul
      final existingUserIds = davetlerList.map((d) => d.userId).toSet();

      // 4. Henüz davet edilmemiş kullanıcıları filtrele
      setState(() {
        _availableUsers = allUsers.where((u) => !existingUserIds.contains(u.id)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isTr ? 'Veriler yüklenirken hata oluştu' : 'Error loading data')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  bool get isTr => widget.lang.currentLang == 'tr';

  Future<void> _sendInvites() async {
    if (_selectedConfigs.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      
      // 1. Yeni davetleri oluştur
      for (var config in _selectedConfigs) {
        final davet = Davet(
          id: '',
          sayimId: widget.sayim.id,
          userId: config.user.id,
          status: DavetStatus.pending,
          role: config.role,
          grupId: config.grupId,
          sehirIciDisi: widget.sayim.sehirTipi, // Sayımın kendi sehirTipini kullan
          multiplier: config.multiplier,
          ucret: config.ucret,
          createdAt: now,
        );
        final davetId = await _davetService.createDavet(davet);
        
        // Eğer yönetici kendini eklediyse otomatik kabul et
        if (config.user.id == widget.currentUser.id) {
          await _davetService.acceptDavet(davetId);
        }
      }

      // 2. Sayım'ın invitedUserIds listesini güncelle
      final updatedInvitedIds = List<String>.from(widget.sayim.invitedUserIds);
      updatedInvitedIds.addAll(_selectedConfigs.map((c) => c.user.id));
      
      final updatedSayim = widget.sayim.copyWith(
        invitedUserIds: updatedInvitedIds,
      );
      await _sayimService.updateSayim(updatedSayim);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isTr ? 'Davetler gönderildi!' : 'Invites sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isTr ? 'Hata oluştu' : 'An error occurred')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isTr ? 'Kişi Ekle' : 'Add Person',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentLight))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StaffPicker(
                    users: _availableUsers,
                    availableGroups: widget.sayim.gruplar,
                    isTr: isTr,
                    currentUser: widget.currentUser,
                    sayimSehirTipi: widget.sayim.sehirTipi,
                    globalMultiplier: widget.sayim.globalMultiplier,
                    onSelectionChanged: (configs) {
                      setState(() {
                        _selectedConfigs = configs;
                      });
                    },
                  ),
                  const SizedBox(height: 100), // Buton için boşluk
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedConfigs.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _sendInvites,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isTr
                              ? 'Davet Gönder (${_selectedConfigs.length} Kişi)'
                              : 'Send Invites (${_selectedConfigs.length} People)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            )
          : null,
    );
  }
}
