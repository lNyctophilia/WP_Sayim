import 'package:daytrack/core/constants/app_strings.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/map_location_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/manager_drawer.dart';
import '../../../../features/home/presentation/widgets/custom_top_bar.dart';
import 'manager_panel_page.dart';
import '../../../../core/theme/theme_service.dart';

class ShuttlePanelPage extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final StorageService storage;
  final ThemeService themeService;
  final bool isEmbedded;

  const ShuttlePanelPage({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.storage,
    required this.themeService,
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
          .where((user) => user.id != widget.currentUser.id) // Personel ve yöneticileri dahil et (kendisi hariç)
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
        content: Text(AppStrings.getFormat('you_can_select_up_to_maxselection_people', isTr ? 'tr' : 'en', [_maxSelection])),
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Future<void> _calculateOptimizedRoute() async {
    final isTr = widget.lang.currentLang == 'tr';

    if (_selectedStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('please_select_at_least_one_staff', isTr ? 'tr' : 'en')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<AppUser> validStaff = [];
    List<String> missingLocationStaff = [];

    for (var staff in _selectedStaff) {
      if (staff.latitude != null && staff.longitude != null) {
        validStaff.add(staff);
      } else {
        missingLocationStaff.add(staff.fullName);
      }
    }

    if (missingLocationStaff.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.getFormat('shuttle_missing_location', isTr ? 'tr' : 'en', [missingLocationStaff.join(', ')])),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    if (validStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('no_selected_staff_with_valid_location', isTr ? 'tr' : 'en')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 1. Show Start/End Selection Dialog
    final routePoints = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => RoutePlanningDialog(
        lang: widget.lang,
        allStaff: [widget.currentUser, ..._allStaff],
      ),
    );

    if (routePoints == null) return;

    final startLoc = routePoints['start'];
    final endLoc = routePoints['end'];

    // 2. Loading state
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.card,
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.accentLight),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppStrings.get('calculating_route', isTr ? 'tr' : 'en'),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    try {
      // 3. Build coordinate list for OSRM: Start, ...staffs, End
      List<Map<String, dynamic>> allPoints = [
        {'lat': startLoc['latitude'], 'lon': startLoc['longitude'], 'name': 'Start'},
        ...validStaff.map((s) => {'lat': s.latitude!, 'lon': s.longitude!, 'name': s.fullName, 'id': s.id}),
        {'lat': endLoc['latitude'], 'lon': endLoc['longitude'], 'name': 'End'},
      ];

      // OSRM format: lon,lat;lon,lat...
      String coords = allPoints.map((p) => '${p['lon']},${p['lat']}').join(';');
      
      // 4. Fetch Matrix
      final url = Uri.parse('https://router.project-osrm.org/table/v1/driving/$coords?annotations=duration');
      final response = await http.get(url, headers: {'User-Agent': 'DaytrackApp/1.0'});

      if (response.statusCode != 200) {
        throw Exception('OSRM matrix error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final List<dynamic> durations = data['durations'];

      // durations[i][j] gives time from i to j in seconds.
      // Index 0 is Start, Index N-1 is End. Indices 1 to N-2 are Staffs.
      int numStaff = validStaff.length;
      List<int> bestOrder = [];
      double bestDuration = double.infinity;

      // Generates permutations
      void permute(List<int> arr, int k) {
        if (k == arr.length) {
          // Calculate total duration
          double total = 0;
          int prev = 0; // Start
          for (int i = 0; i < arr.length; i++) {
            int curr = arr[i] + 1; // map staff index to matrix index
            var duration = durations[prev][curr];
            if (duration == null) {
              total = double.infinity;
              break;
            }
            total += (duration as num).toDouble();
            prev = curr;
          }
          // From last staff to End
          var finalLeg = durations[prev][durations.length - 1];
          if (finalLeg == null) {
            total = double.infinity;
          } else {
            total += (finalLeg as num).toDouble();
          }

          if (total < bestDuration) {
            bestDuration = total;
            bestOrder = List.from(arr);
          }
          return;
        }

        for (int i = k; i < arr.length; i++) {
          int temp = arr[i];
          arr[i] = arr[k];
          arr[k] = temp;
          
          permute(arr, k + 1);
          
          temp = arr[i];
          arr[i] = arr[k];
          arr[k] = temp;
        }
      }

      List<int> staffIndices = List.generate(numStaff, (i) => i);
      permute(staffIndices, 0);

      if (bestDuration == double.infinity) {
        throw Exception('Could not find a valid route between points.');
      }

      List<String> orderedWaypoints = [];
      for (int i in bestOrder) {
        final st = validStaff[i];
        orderedWaypoints.add('${st.latitude},${st.longitude}');
      }

      final originStr = Uri.encodeComponent('${startLoc['latitude']},${startLoc['longitude']}');
      final destStr = Uri.encodeComponent('${endLoc['latitude']},${endLoc['longitude']}');
      final waypointsStr = orderedWaypoints.isNotEmpty 
          ? Uri.encodeComponent(orderedWaypoints.join('|')) 
          : '';

      String mapUrl = 'https://www.google.com/maps/dir/?api=1&origin=$originStr&destination=$destStr';
      if (waypointsStr.isNotEmpty) {
        mapUrl += '&waypoints=$waypointsStr';
      }
      final uri = Uri.parse(mapUrl);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } else {
        throw 'Could not launch Maps';
      }

    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('route_error', isTr ? 'tr' : 'en')),
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
        themeService: widget.themeService,
      ),
      body: Column(
        children: [
          if (!widget.isEmbedded)
            CustomTopBar(currentUser: widget.currentUser, lang: widget.lang, storage: widget.storage, themeService: widget.themeService),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.directions_bus_rounded, color: AppColors.accentLight),
                SizedBox(width: 8),
                Text(
                  AppStrings.get('shuttle_route_planning', isTr ? 'tr' : 'en'),
                  style: TextStyle(
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
                ? Center(child: CircularProgressIndicator(color: AppColors.accentLight))
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
                          Icon(Icons.info_outline, color: AppColors.accentLight, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.getFormat('shuttle_route_desc', isTr ? 'tr' : 'en', [widget.currentUser.fullName]),
                              style: TextStyle(
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
                            AppStrings.getFormat('shuttle_selected_count', isTr ? 'tr' : 'en', [_selectedStaff.length, _maxSelection]),
                            style: TextStyle(
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
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          hasLocation
                              ? (staff.address ?? (AppStrings.get('location_saved', isTr ? 'tr' : 'en')))
                              : (AppStrings.get('no_location_address', isTr ? 'tr' : 'en')),
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
            onPressed: _isLoading || _selectedStaff.isEmpty ? null : _calculateOptimizedRoute,
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
              AppStrings.get('open_route_on_map', isTr ? 'tr' : 'en'),
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
              themeService: widget.themeService,
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

class RoutePlanningDialog extends StatefulWidget {
  final LanguageService lang;
  final List<AppUser> allStaff;

  const RoutePlanningDialog({super.key, required this.lang, required this.allStaff});

  @override
  State<RoutePlanningDialog> createState() => _RoutePlanningDialogState();
}

class _RoutePlanningDialogState extends State<RoutePlanningDialog> {
  Map<String, dynamic>? _startLocation;
  Map<String, dynamic>? _endLocation;

  Future<void> _pickLocation(bool isStart) async {
    final isTr = widget.lang.currentLang == 'tr';
    
    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              isTr ? 'Konum Seçim Yöntemi' : 'Location Selection Method',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: AppColors.divider),
          ListTile(
            leading: Icon(Icons.map, color: AppColors.accentLight),
            title: Text(isTr ? 'Haritadan Seç' : 'Select from Map', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.pop(context, 'map'),
          ),
          ListTile(
            leading: Icon(Icons.list, color: AppColors.accentLight),
            title: Text(isTr ? 'Listeden Seç' : 'Select from List', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(isTr ? 'Kayıtlı kişi adreslerinden' : 'From saved staff addresses', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            onTap: () => Navigator.pop(context, 'list'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (selection == null) return;

    Map<String, dynamic>? result;

    if (selection == 'map') {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapLocationPicker(lang: widget.lang),
        ),
      );
    } else if (selection == 'list') {
      result = await _pickFromList(isTr);
    }

    if (result != null && mounted) {
      setState(() {
        if (isStart) {
          _startLocation = result;
        } else {
          _endLocation = result;
        }
      });
    }
  }

  Future<Map<String, dynamic>?> _pickFromList(bool isTr) async {
    final staffWithLocation = widget.allStaff.where((s) => s.latitude != null && s.longitude != null).toList();

    return await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isTr ? 'Kayıtlı Adresler' : 'Saved Addresses',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(color: AppColors.divider),
            Expanded(
              child: staffWithLocation.isEmpty 
                ? Center(
                    child: Text(
                      isTr ? 'Konumu kayıtlı kişi bulunamadı.' : 'No one with saved locations.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                  controller: scrollController,
                  itemCount: staffWithLocation.length,
                  itemBuilder: (context, index) {
                    final staff = staffWithLocation[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accentLight,
                        child: Text(staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(staff.fullName, style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(
                        staff.address != null && staff.address!.isNotEmpty 
                            ? staff.address! 
                            : (isTr ? 'Konum kayıtlı' : 'Location saved'),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(context, {
                          'latitude': staff.latitude,
                          'longitude': staff.longitude,
                          'address': staff.address != null && staff.address!.isNotEmpty 
                              ? staff.address 
                              : staff.fullName,
                        });
                      },
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(AppStrings.get('calculate_route', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Start location button
          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(Icons.my_location, color: AppColors.accentLight),
            title: Text(_startLocation?['address'] ?? AppStrings.get('start_point', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => _pickLocation(true),
          ),
          const SizedBox(height: 12),
          // End location button
          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.location_on, color: Colors.red),
            title: Text(_endLocation?['address'] ?? AppStrings.get('end_point', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => _pickLocation(false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.get('cancel', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _startLocation != null && _endLocation != null
              ? () {
                  Navigator.pop(context, {
                    'start': _startLocation,
                    'end': _endLocation,
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentLight),
          child: Text(AppStrings.get('confirm', isTr ? 'tr' : 'en'), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
