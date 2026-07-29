import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/constants/app_strings.dart';
import 'staff_picker.dart';

class GrupSelector extends StatefulWidget {
  final List<SayimGrup> initialGruplar;
  final Function(List<SayimGrup>) onChanged;
  final bool isTr;
  final List<SelectedUserConfig> selectedUsers;
  final Function(String userId, int newGrupId) onUserGroupChanged;

  const GrupSelector({
    super.key,
    required this.initialGruplar,
    required this.onChanged,
    required this.isTr,
    required this.selectedUsers,
    required this.onUserGroupChanged,
  });

  @override
  State<GrupSelector> createState() => _GrupSelectorState();
}

class _GrupSelectorState extends State<GrupSelector> {
  late List<SayimGrup> _gruplar;

  @override
  void initState() {
    super.initState();
    _gruplar = List.from(widget.initialGruplar);
    if (_gruplar.isEmpty) {
      // Default to 1 group at least
      _gruplar.add(const SayimGrup(grupId: 1, saat: '16:00'));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(_gruplar);
      });
    }
  }

  void _addGroup() {
    if (_gruplar.length < 10) {
      setState(() {
        int newId = 1;
        if (_gruplar.isNotEmpty) {
          newId = _gruplar.map((e) => e.grupId).reduce((a, b) => a > b ? a : b) + 1;
        }
        String defaultSaat = _gruplar.length == 1 ? '21:30' : '12:00';
        _gruplar.add(SayimGrup(grupId: newId, saat: defaultSaat));
      });
      widget.onChanged(_gruplar);
    }
  }

  void _removeGroup(int index) {
    if (_gruplar.length > 1) {
      setState(() {
        _gruplar.removeAt(index);
      });
      widget.onChanged(_gruplar);
    }
  }

  void _showGroupBottomSheet(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final grup = _gruplar[index];
            final selectedUsersForCount = widget.selectedUsers.where((u) => u.isSelected).toList();
            
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppStrings.get('group', widget.isTr ? 'tr' : 'en')} ${index + 1}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Time section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, color: AppColors.accentLight),
                                const SizedBox(width: 8),
                                Text(
                                  grup.saat,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final parts = grup.saat.split(':');
                                TimeOfDay initialTime = TimeOfDay.now();
                                if (parts.length == 2) {
                                  initialTime = TimeOfDay(
                                    hour: int.tryParse(parts[0]) ?? 8,
                                    minute: int.tryParse(parts[1]) ?? 0,
                                  );
                                }
                                
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: initialTime,
                                  builder: (context, child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                      child: Theme(
                                        data: ThemeData.dark().copyWith(
                                          colorScheme: ColorScheme.dark(
                                            primary: AppColors.accentLight,
                                            surface: AppColors.card,
                                          ),
                                        ),
                                        child: child!,
                                      ),
                                    );
                                  },
                                );
                                
                                if (picked != null) {
                                  final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  setModalState(() {
                                    _gruplar[index] = SayimGrup(grupId: grup.grupId, saat: formattedTime);
                                  });
                                  setState(() {});
                                  widget.onChanged(_gruplar);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.card,
                                foregroundColor: AppColors.textPrimary,
                                elevation: 0,
                              ),
                              child: Text(AppStrings.get('edit', widget.isTr ? 'tr' : 'en') ?? 'Değiştir'),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Text(
                        AppStrings.get('assign_personnel', widget.isTr ? 'tr' : 'en') ?? 'Bu gruba atanacak kişileri seçin:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Users List
                      Expanded(
                        child: selectedUsersForCount.isEmpty 
                          ? Center(
                              child: Text(
                                AppStrings.get('no_personnel_selected', widget.isTr ? 'tr' : 'en') ?? 'Önce personellerden kişi seçin.',
                                style: TextStyle(color: AppColors.textHint),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: selectedUsersForCount.length,
                              itemBuilder: (context, userIndex) {
                                final userConfig = selectedUsersForCount[userIndex];
                                final isSelectedForThisGroup = userConfig.grupId == grup.grupId;
                                
                                return CheckboxListTile(
                                  value: isSelectedForThisGroup,
                                  activeColor: AppColors.accentLight,
                                  checkColor: Colors.white,
                                  title: Text(
                                    userConfig.user.fullName,
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                                  ),
                                  subtitle: userConfig.grupId != grup.grupId
                                      ? Text(
                                          'Şu an: ${AppStrings.get('group', widget.isTr ? 'tr' : 'en')} ${userConfig.grupId}',
                                          style: TextStyle(color: AppColors.textHint, fontSize: 12),
                                        )
                                      : null,
                                  onChanged: (val) {
                                    if (val != null) {
                                      // Eğer unchecked yapıldıysa, ilk gruba dahil et. (ya da _gruplar.first.grupId)
                                      final fallbackGrupId = _gruplar.isNotEmpty ? _gruplar.first.grupId : 1;
                                      final newGrupId = val ? grup.grupId : fallbackGrupId;
                                      widget.onUserGroupChanged(userConfig.user.id, newGrupId);
                                      setModalState(() {});
                                    }
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.get('time_groups_max', widget.isTr ? 'tr' : 'en'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (_gruplar.length < 10)
              TextButton.icon(
                onPressed: _addGroup,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(AppStrings.get('add_group', widget.isTr ? 'tr' : 'en')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentLight,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ..._gruplar.asMap().entries.map((entry) {
          int index = entry.key;
          SayimGrup grup = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showGroupBottomSheet(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.textHint.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text(
                            '${AppStrings.get('group', widget.isTr ? 'tr' : 'en')} ${index + 1}: ${grup.saat}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_gruplar.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline_rounded,
                        color: AppColors.danger),
                    onPressed: () => _removeGroup(index),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
