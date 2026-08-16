import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/utils/polyline_decoder.dart';

class WaypointState {
  bool isTarget = false;
  bool isReached = false;
  bool isPassed = false;
  double minDistanceSeen = double.infinity;
}

class ShuttleRouteMapPage extends StatefulWidget {
  final List<Map<String, dynamic>> optimizedWaypoints;
  final String encodedPolyline;
  final LanguageService lang;

  const ShuttleRouteMapPage({
    super.key,
    required this.optimizedWaypoints,
    required this.encodedPolyline,
    required this.lang,
  });

  @override
  State<ShuttleRouteMapPage> createState() => _ShuttleRouteMapPageState();
}

class _ShuttleRouteMapPageState extends State<ShuttleRouteMapPage> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  late List<WaypointState> _waypointStates;
  bool _isFollowingUser = true;

  @override
  void initState() {
    super.initState();
    _routePoints = PolylineDecoder.decode(widget.encodedPolyline);
    _waypointStates = List.generate(
      widget.optimizedWaypoints.length,
      (index) => WaypointState(),
    );
    
    // Set the first actual passenger stop as target initially
    if (_waypointStates.length > 1) {
      _waypointStates[1].isTarget = true;
    }

    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final initialPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(initialPos.latitude, initialPos.longitude);
      });
      _fitBounds();
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // update every 2 meters
      ),
    ).listen((Position position) {
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateWaypointStates();
        if (_isFollowingUser) {
          _mapController.move(_currentLocation!, _mapController.camera.zoom);
        }
      });
    });
  }

  void _updateWaypointStates() {
    if (_currentLocation == null) return;

    int activeIndex = -1;
    // Find first unpassed waypoint (skip index 0 which is 'Start')
    for (int i = 1; i < widget.optimizedWaypoints.length - 1; i++) {
      if (!_waypointStates[i].isPassed) {
        activeIndex = i;
        break;
      }
    }

    if (activeIndex != -1) {
      final target = widget.optimizedWaypoints[activeIndex];
      double dist = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        target['lat'],
        target['lon'],
      );

      _waypointStates[activeIndex].isTarget = true;

      if (dist < _waypointStates[activeIndex].minDistanceSeen) {
        _waypointStates[activeIndex].minDistanceSeen = dist;
      }

      // Approach threshold 50m
      if (dist <= 50.0 && !_waypointStates[activeIndex].isReached) {
        _waypointStates[activeIndex].isReached = true;
        
        // Highlight next stop too
        if (activeIndex + 1 < widget.optimizedWaypoints.length - 1) {
          _waypointStates[activeIndex + 1].isTarget = true;
        }
      }

      // Passed threshold: moved 20m away from closest point, or completely left 50m zone
      if (_waypointStates[activeIndex].isReached) {
        if (dist > _waypointStates[activeIndex].minDistanceSeen + 20.0 || dist > 50.0) {
          _waypointStates[activeIndex].isPassed = true;
          _waypointStates[activeIndex].isTarget = false;
        }
      }
    }
  }

  void _fitBounds() {
    if (_routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50.0),
      ),
    );
  }

  void _showWaypointDetails(Map<String, dynamic> waypoint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.accentLight,
                    radius: 24,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          waypoint['name'] ?? 'Bilinmeyen',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (waypoint['id'] != null)
                           Text(
                            'ID: ${waypoint['id']}',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                           ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.location_on, color: AppColors.accentLight),
                title: Text(
                  widget.lang.currentLang == 'tr' ? 'Konum' : 'Location',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                subtitle: Text(
                  '${waypoint['lat'].toStringAsFixed(6)}, ${waypoint['lon'].toStringAsFixed(6)}',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final lat = waypoint['lat'];
                        final lon = waypoint['lon'];
                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.map, color: Colors.white, size: 20),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: Text(
                        widget.lang.currentLang == 'tr' ? 'Haritada Aç' : 'Open Map',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLight,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        widget.lang.currentLang == 'tr' ? 'Kapat' : 'Close',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text(
          AppStrings.get('shuttle_route_planning', isTr ? 'tr' : 'en'),
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _routePoints.isNotEmpty ? _routePoints.first : const LatLng(41.0, 28.9),
              initialZoom: 13.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _isFollowingUser = false;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.daytrack.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: AppColors.accentLight.withValues(alpha: 0.8),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Waypoints
                  for (int i = 0; i < widget.optimizedWaypoints.length; i++)
                    Marker(
                      point: LatLng(widget.optimizedWaypoints[i]['lat'], widget.optimizedWaypoints[i]['lon']),
                      width: 150, // Enough width for names
                      height: 80,
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onLongPress: () => _showWaypointDetails(widget.optimizedWaypoints[i]),
                        onTap: () => _showWaypointDetails(widget.optimizedWaypoints[i]),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _waypointStates[i].isTarget 
                                    ? AppColors.accentLight 
                                    : (_waypointStates[i].isPassed ? Colors.grey : AppColors.card),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _waypointStates[i].isTarget ? Colors.white : AppColors.divider,
                                  width: _waypointStates[i].isTarget ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (_waypointStates[i].isTarget)
                                    BoxShadow(
                                      color: AppColors.accentLight.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                ],
                              ),
                              child: Text(
                                (i == 0 || i == widget.optimizedWaypoints.length - 1)
                                    ? (widget.optimizedWaypoints[i]['name'] ?? '')
                                    : '$i. ${widget.optimizedWaypoints[i]['name'] ?? ''}',
                                style: TextStyle(
                                  color: _waypointStates[i].isTarget ? Colors.white : AppColors.textPrimary,
                                  fontWeight: _waypointStates[i].isTarget ? FontWeight.bold : FontWeight.normal,
                                  fontSize: _waypointStates[i].isTarget ? 16 : 12,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Current Location
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Recenter Button
          if (!_isFollowingUser)
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: AppColors.card,
                onPressed: () {
                  setState(() {
                    _isFollowingUser = true;
                  });
                  if (_currentLocation != null) {
                    _mapController.move(_currentLocation!, 15.0);
                  }
                },
                child: Icon(Icons.my_location, color: AppColors.accentLight),
              ),
            ),
        ],
      ),
    );
  }
}
