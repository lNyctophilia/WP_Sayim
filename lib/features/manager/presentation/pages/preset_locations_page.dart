import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/preset_location.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/theme_service.dart';
import '../../../../core/utils/bottom_toast.dart';
import '../../../../core/utils/url_helper.dart';

/// Admin paneli için Hazır Konumlar (AVM ve sık kullanılan mekanlar) Yönetim Sayfası
class PresetLocationsPage extends StatefulWidget {
  final AppUser currentUser;
  final LanguageService lang;
  final StorageService storage;
  final ThemeService themeService;
  final bool isEmbedded;

  const PresetLocationsPage({
    super.key,
    required this.currentUser,
    required this.lang,
    required this.storage,
    required this.themeService,
    this.isEmbedded = false,
  });

  @override
  State<PresetLocationsPage> createState() => _PresetLocationsPageState();
}

class _PresetLocationsPageState extends State<PresetLocationsPage> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([PresetLocation? existing]) {
    final isTr = widget.lang.currentLang == 'tr';
    final isEditing = existing != null;

    final nameController = TextEditingController(text: existing?.name ?? '');
    final urlController = TextEditingController(text: existing?.url ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
                  color: AppColors.accentLight,
                ),
                const SizedBox(width: 10),
                Text(
                  isEditing
                      ? AppStrings.get('edit_preset_location', isTr ? 'tr' : 'en')
                      : AppStrings.get('add_preset_location', isTr ? 'tr' : 'en'),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mekan / AVM Adı
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: '${AppStrings.get('location_name', isTr ? 'tr' : 'en')} *',
                        hintText: isTr ? 'Örn: Forum Çamlık AVM' : 'e.g. Forum Mall',
                        hintStyle: TextStyle(color: AppColors.textHint.withValues(alpha: 0.5)),
                        labelStyle: TextStyle(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.storefront_rounded, color: AppColors.textSecondary),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? AppStrings.get('cannot_be_empty', isTr ? 'tr' : 'en')
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Harita / Konum Linki
                    TextFormField(
                      controller: urlController,
                      style: TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: '${AppStrings.get('location_url', isTr ? 'tr' : 'en')} *',
                        hintText: 'https://maps.app.goo.gl/...',
                        hintStyle: TextStyle(color: AppColors.textHint.withValues(alpha: 0.5)),
                        labelStyle: TextStyle(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.link_rounded, color: AppColors.textSecondary),
                        suffixIcon: urlController.text.trim().isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.open_in_new_rounded, color: AppColors.accentLight, size: 20),
                                tooltip: AppStrings.get('test_location_link', isTr ? 'tr' : 'en'),
                                onPressed: () {
                                  UrlHelper.openMapUrl(context, urlController.text.trim());
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return AppStrings.get('cannot_be_empty', isTr ? 'tr' : 'en');
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  AppStrings.get('cancel', isTr ? 'tr' : 'en'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  try {
                    if (isEditing) {
                      final updated = existing.copyWith(
                        name: nameController.text.trim(),
                        url: urlController.text.trim(),
                      );
                      await _locationService.updatePresetLocation(updated);
                    } else {
                      await _locationService.addPresetLocation(
                        name: nameController.text.trim(),
                        url: urlController.text.trim(),
                      );
                    }
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                    if (mounted) {
                      BottomToast.show(
                        context,
                        isEditing
                            ? (isTr ? 'Konum güncellendi' : 'Location updated')
                            : (isTr ? 'Yeni konum eklendi' : 'New location added'),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      BottomToast.show(context, isTr ? 'Hata oluştu: $e' : 'Error: $e');
                    }
                  }
                },
                child: Text(AppStrings.get('save', isTr ? 'tr' : 'en')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(PresetLocation loc) {
    final isTr = widget.lang.currentLang == 'tr';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text(
              AppStrings.get('delete_preset_location', isTr ? 'tr' : 'en'),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '${loc.name} - ${AppStrings.get('delete_preset_location_confirm', isTr ? 'tr' : 'en')}',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              AppStrings.get('cancel', isTr ? 'tr' : 'en'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              try {
                await _locationService.deletePresetLocation(loc.id);
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
                if (mounted) {
                  BottomToast.show(
                    context,
                    isTr ? 'Konum silindi' : 'Location deleted',
                  );
                }
              } catch (e) {
                if (mounted) {
                  BottomToast.show(context, isTr ? 'Hata oluştu: $e' : 'Error: $e');
                }
              }
            },
            child: Text(AppStrings.get('delete', isTr ? 'tr' : 'en')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.lang.currentLang == 'tr';

    final content = Column(
      children: [
        // Arama ve Yeni Ekle Barı
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
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
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                label: Text(
                  isTr ? 'Yeni Ekle' : 'Add New',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showAddEditDialog(),
              ),
            ],
          ),
        ),

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
                    isTr ? 'Konumlar yüklenirken bir sorun oluştu' : 'Failed to load locations',
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
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wrong_location_outlined,
                          size: 64,
                          color: AppColors.textHint.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? AppStrings.get('no_preset_locations', isTr ? 'tr' : 'en')
                              : (isTr ? 'Arama sonucuna uygun konum bulunamadı' : 'No matching locations found'),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isTr
                              ? 'Sayım oluştururken ve düzenlerken hızlıca seçebilmek için sık kullanılan AVM ve mekan konumlarını ekleyin.'
                              : 'Add frequently used mall and venue locations for fast picking during count creation.',
                          style: TextStyle(color: AppColors.textHint, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accentLight,
                              side: BorderSide(color: AppColors.accentLight),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(AppStrings.get('add_preset_location', isTr ? 'tr' : 'en')),
                            onPressed: () => _showAddEditDialog(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final loc = filtered[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider, width: 0.8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.storefront_rounded, color: AppColors.accentLight, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.name,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => UrlHelper.openMapUrl(context, loc.url),
                                child: Row(
                                  children: [
                                    Icon(Icons.link_rounded, size: 14, color: AppColors.accentLight),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        loc.url,
                                        style: TextStyle(
                                          color: AppColors.accentLight,
                                          fontSize: 12,
                                          decoration: TextDecoration.underline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 20),
                              tooltip: AppStrings.get('edit', isTr ? 'tr' : 'en'),
                              onPressed: () => _showAddEditDialog(loc),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                              tooltip: AppStrings.get('delete', isTr ? 'tr' : 'en'),
                              onPressed: () => _confirmDelete(loc),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text(
          AppStrings.get('preset_locations', isTr ? 'tr' : 'en'),
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: content,
    );
  }
}
