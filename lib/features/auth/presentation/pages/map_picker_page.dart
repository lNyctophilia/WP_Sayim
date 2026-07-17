import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_keys.dart';
import '../../../../core/constants/app_colors.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _mapController;
  // Varsayılan olarak İstanbul
  LatLng _center = const LatLng(41.0082, 28.9784);
  bool _isMoving = false;
  String _currentAddress = "Konum aranıyor...";

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateAddress(_center);
  }

  void _onCameraMoveStarted() {
    setState(() {
      _isMoving = true;
    });
  }

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
  }

  void _onCameraIdle() {
    setState(() {
      _isMoving = false;
    });
    _updateAddress(_center);
  }

  Future<void> _updateAddress(LatLng pos) async {
    setState(() {
      _currentAddress = "Konum aranıyor...";
    });
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&key=${ApiKeys.googleMapsKey}&language=tr');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            setState(() {
              _currentAddress = results.first['formatted_address'] as String;
            });
            return;
          }
        }
      }
      
      setState(() {
        _currentAddress = "Adres bulunamadı";
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Adres bulunamadı ($e)";
      });
    }
  }

  void _confirmLocation() {
    Navigator.of(context).pop({
      'latitude': _center.latitude,
      'longitude': _center.longitude,
      'address': _currentAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text("Konum Seç", style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 15.0,
            ),
            onCameraMoveStarted: _onCameraMoveStarted,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, _isMoving ? -15 : 0, 0),
                child: const Icon(
                  Icons.location_on,
                  size: 40,
                  color: AppColors.accentLight,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentAddress,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isMoving ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Konumu Onayla", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
