import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../services/language_service.dart';

class MapLocationPicker extends StatefulWidget {
  final LanguageService lang;
  final LatLng? initialLocation;

  const MapLocationPicker({
    super.key,
    required this.lang,
    this.initialLocation,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  // Default to Istanbul if no initial location
  late LatLng _currentLocation;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isGettingLocation = false;
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation ?? const LatLng(41.0082, 28.9784); // Istanbul
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5');
      final response = await http.get(url, headers: {
        'User-Agent': 'DaytrackApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data;
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Nominatim search error: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }



  void _moveToLocation(double lat, double lon, String addressName) {
    final newLoc = LatLng(lat, lon);
    setState(() {
      _currentLocation = newLoc;
      _selectedAddress = addressName;
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(newLoc, 15.0);
    FocusScope.of(context).unfocus();
  }

  Future<void> _getAddressFromCoordinates(LatLng loc) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${loc.latitude}&lon=${loc.longitude}&format=json');
      final response = await http.get(url, headers: {
        'User-Agent': 'DaytrackApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          setState(() {
            _selectedAddress = data['display_name'];
          });
        }
      }
    } catch (e) {
      debugPrint('Nominatim reverse geocoding error: $e');
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isGettingLocation = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final newLoc = LatLng(position.latitude, position.longitude);
      _mapController.move(newLoc, 15.0);
      
      setState(() {
        _currentLocation = newLoc;
        _selectedAddress = '';
        _searchResults = [];
      });
      
      await _getAddressFromCoordinates(newLoc);
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _confirmSelection() {
    Navigator.pop(context, {
      'latitude': _currentLocation.latitude,
      'longitude': _currentLocation.longitude,
      'address': _selectedAddress.isNotEmpty ? _selectedAddress : '${_currentLocation.latitude}, ${_currentLocation.longitude}',
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text(AppStrings.get('select_location', isTr ? 'tr' : 'en'), style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: _confirmSelection,
            child: Text(
              AppStrings.get('confirm', isTr ? 'tr' : 'en'),
              style: TextStyle(color: AppColors.accentLight, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    _currentLocation = position.center!;
                    _selectedAddress = ''; // Reset address when manually moved
                  });
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  // Wait for user to stop moving, then reverse geocode
                  _getAddressFromCoordinates(_currentLocation);
                }
              }
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
            ],
          ),
          
          // Center Marker (Fixed in center)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Adjust to make the pin point at the center
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40.0,
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: AppStrings.get('search_location', isTr ? 'tr' : 'en'),
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                      suffixIcon: _isSearching 
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : IconButton(
                            icon: Icon(Icons.clear, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: Icon(Icons.location_on_outlined, color: AppColors.accentLight),
                          title: Text(
                            result['display_name'] ?? '',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            _moveToLocation(
                              double.parse(result['lat']),
                              double.parse(result['lon']),
                              result['display_name'],
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Controls (FAB + Selected Address Display)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'currentLocationBtn',
                  backgroundColor: AppColors.card,
                  onPressed: _goToCurrentLocation,
                  child: _isGettingLocation
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentLight,
                          ),
                        )
                      : Icon(Icons.my_location, color: AppColors.accentLight),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.get('selected_location', isTr ? 'tr' : 'en'),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAddress.isNotEmpty ? _selectedAddress : '${_currentLocation.latitude.toStringAsFixed(6)}, ${_currentLocation.longitude.toStringAsFixed(6)}',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _confirmSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentLight,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            AppStrings.get('confirm', isTr ? 'tr' : 'en'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
