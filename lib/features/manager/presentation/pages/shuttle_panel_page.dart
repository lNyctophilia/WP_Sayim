import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/manager_drawer.dart';
import '../../../../features/home/presentation/widgets/custom_top_bar.dart';
import 'manager_panel_page.dart';

class ShuttlePanelPage extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final StorageService storage;
  final bool isEmbedded;

  const ShuttlePanelPage({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.storage,
    this.isEmbedded = false,
  });

  @override
  State<ShuttlePanelPage> createState() => _ShuttlePanelPageState();
}

class _ShuttlePanelPageState extends State<ShuttlePanelPage> {
  bool _isLoading = true;
  List<AppUser> _allStaff = [];
  final List<AppUser> _selectedStaff = [];
  final int _maxSelection = 9;

  @override
  void initState() {
    super.initState();
    widget.storage.setLastPanel('shuttle');
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('active', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .get();

      final staffList = snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .where((user) => user.id != widget.currentUser.id && user.isStaff) // Hariç tut
          .toList();

      setState(() {
        _allStaff = staffList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Personel yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(AppUser user) {
    setState(() {
      if (_selectedStaff.contains(user)) {
        _selectedStaff.remove(user);
      } else {
        if (_selectedStaff.length >= _maxSelection) {
          _showMaxSelectionWarning();
          return;
        }
        _selectedStaff.add(user);
      }
    });
  }

  void _showMaxSelectionWarning() {
    final isTr = widget.lang.currentLang == 'tr';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isTr
            ? 'En fazla $_maxSelection kişi seçebilirsiniz!'
            : 'You can select up to $_maxSelection people!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _getLocationString(AppUser user) {
    if (user.latitude != null && user.longitude != null) {
      return '${user.latitude},${user.longitude}';
    }
    if (user.address != null && user.address!.isNotEmpty) {
      return user.address!;
    }
    return '';
  }

  Future<void> _openGoogleMaps() async {
    final isTr = widget.lang.currentLang == 'tr';

    // 1. Yönetici (CurrentUser) lokasyonu kontrolü
    final destLocation = _getLocationString(widget.currentUser);
    if (destLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTr
              ? 'Lütfen kendi profilinize bir adres veya konum ekleyin. Bitiş noktası sizin konumunuz olacaktır.'
              : 'Please add an address or location to your profile. The destination will be your location.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTr
              ? 'Lütfen en az bir personel seçin.'
              : 'Please select at least one staff.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Seçilen personellerin lokasyonlarını al
    List<String> waypoints = [];
    List<String> missingLocationStaff = [];

    for (var staff in _selectedStaff) {
      String loc = _getLocationString(staff);
      if (loc.isEmpty) {
        missingLocationStaff.add(staff.fullName);
      } else {
        waypoints.add(Uri.encodeComponent(loc));
      }
    }

    if (missingLocationStaff.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTr
              ? 'Şu personellerin konumu yok ve rotaya eklenemedi: ${missingLocationStaff.join(', ')}'
              : 'These staff members have no location and were skipped: ${missingLocationStaff.join(', ')}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    if (waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTr
              ? 'Geçerli konuma sahip seçili personel yok.'
              : 'No selected staff with valid location.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // URL'yi oluştur
    final destination = Uri.encodeComponent(destLocation);
    final waypointsString = waypoints.join('%7C'); // %7C is '|'

    final urlString =
        'https://www.google.com/maps/dir/?api=1&destination=$destination&waypoints=$waypointsString';

    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTr
                ? 'Harita açılamadı: $e'
                : 'Could not open map: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';

    Widget scaffold = Scaffold(
      backgroundColor: widget.isEmbedded ? Colors.transparent : AppColors.background,
      drawer: widget.isEmbedded ? null : ManagerDrawer(
        currentUser: widget.currentUser,
        lang: widget.lang,
        storage: widget.storage,
      ),
      body: Column(
        children: [
          if (!widget.isEmbedded)
            CustomTopBar(currentUser: widget.currentUser, lang: widget.lang, storage: widget.storage),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.directions_bus_rounded, color: AppColors.accentLight),
                const SizedBox(width: 8),
                Text(
                  isTr ? 'Servis / Rota Planlama' : 'Shuttle / Route Planning',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentLight))
                : Column(
                      children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.accentLight, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isTr
                                  ? 'Rota "Mevcut Konum"dan başlar, seçilen personellere uğrar ve sizin konumunuzda (${widget.currentUser.fullName}) biter.'
                                  : 'The route starts at "Current Location", visits selected staff, and ends at your location (${widget.currentUser.fullName}).',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isTr
                                ? 'Seçilen: ${_selectedStaff.length} / $_maxSelection'
                                : 'Selected: ${_selectedStaff.length} / $_maxSelection',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allStaff.length,
                    itemBuilder: (context, index) {
                      final staff = _allStaff[index];
                      final isSelected = _selectedStaff.contains(staff);
                      final hasLocation = _getLocationString(staff).isNotEmpty;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppColors.accentLight
                              : AppColors.card,
                          child: Text(
                            staff.fullName[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        title: Text(
                          staff.fullName,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          hasLocation
                              ? (staff.address ?? (isTr ? 'Konum kayıtlı' : 'Location saved'))
                              : (isTr ? 'Konum/Adres bilgisi yok!' : 'No location/address!'),
                          style: TextStyle(
                            color: hasLocation ? AppColors.textSecondary : Colors.red,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: hasLocation
                              ? (val) => _toggleSelection(staff)
                              : null, // Konumu yoksa seçimi engelle
                          activeColor: AppColors.accentLight,
                        ),
                        onTap: hasLocation ? () => _toggleSelection(staff) : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _isLoading || _selectedStaff.isEmpty ? null : _openGoogleMaps,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppColors.accentLight.withValues(alpha: 0.5),
            ),
            icon: const Icon(Icons.map_rounded),
            label: Text(
              isTr ? 'Rotayı Haritada Aç' : 'Open Route on Map',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.isEmbedded) {
      return scaffold;
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
      child: scaffold,
    );
  }
}
