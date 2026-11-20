import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/preset_location.dart';
import '../services/language_service.dart';
import '../services/location_service.dart';

/// Hazır konum seçimi için alttan açılan BottomSheet penceresi
Future<PresetLocation?> showPresetLocationPicker(
  BuildContext context, {
  required LanguageService lang,
}) {
  return showModalBottomSheet<PresetLocation>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PresetLocationPickerSheet(lang: lang),
  );
}

class _PresetLocationPickerSheet extends StatefulWidget {
  final LanguageService lang;

  const _PresetLocationPickerSheet({required this.lang});

  @override
  State<_PresetLocationPickerSheet> createState() => _PresetLocationPickerSheetState();
}

class _PresetLocationPickerSheetState extends State<_PresetLocationPickerSheet> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Üst çekme çubuğu (Drag Handle)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Başlık ve Kapat Butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.place_rounded, color: AppColors.accentLight, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get('select_from_preset_locations', isTr ? 'tr' : 'en'),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isTr ? 'Hazır AVM ve mekan konumları' : 'Preset mall and venue locations',
                            style: TextStyle(color: AppColors.textHint, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Arama Çubuğu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: AppStrings.get('search_preset_location', isTr ? 'tr' : 'en'),
                    hintStyle: TextStyle(color: AppColors.textHint.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: AppColors.textHint, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              Divider(color: AppColors.divider, height: 1),

              // Konumlar Listesi
              Expanded(
                child: StreamBuilder<List<PresetLocation>>(
                  stream: _locationService.getPresetLocations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          isTr ? 'Konumlar yüklenirken hata oluştu' : 'Failed to load locations',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      );
                    }

                    final allLocations = snapshot.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? allLocations
                        : allLocations.where((loc) {
                            final nameMatch = loc.name.toLowerCase().contains(_searchQuery);
                            final urlMatch = loc.url.toLowerCase().contains(_searchQuery);
                            return nameMatch || urlMatch;
                          }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_off_rounded, size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? AppStrings.get('no_preset_locations', isTr ? 'tr' : 'en')
                                    : (isTr ? 'Eşleşen konum bulunamadı' : 'No matching locations found'),
                                style: TextStyle(color: AppColors.textHint, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  isTr
                                      ? 'Admin panelindeki "Hazır Konumlar" sayfasından yeni konumlar ekleyebilirsiniz.'
                                      : 'You can add preset locations from the admin panel.',
                                  style: TextStyle(color: AppColors.textHint.withValues(alpha: 0.7), fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final loc = filtered[index];
                        return Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => Navigator.pop(context, loc),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentLight.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.location_on_rounded, color: AppColors.accentLight, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.name,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          loc.url,
                                          style: TextStyle(
                                            color: AppColors.textHint.withValues(alpha: 0.6),
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.check_circle_outline_rounded, color: AppColors.accentLight, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
