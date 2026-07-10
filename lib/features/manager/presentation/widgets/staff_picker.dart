import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/models/davet.dart';

class SelectedUserConfig {
  final AppUser user;
  int grupId;
  SehirTipi sehirTipi;
  double ucret;
  DavetRole role;
  bool isSelected;

  SelectedUserConfig({
    required this.user,
    this.grupId = 1,
    this.sehirTipi = SehirTipi.ici,
    this.ucret = 0.0,
    this.role = DavetRole.staff,
    this.isSelected = false,
  });
}

class StaffPicker extends StatefulWidget {
  final List<AppUser> users;
  final List<SayimGrup> availableGroups;
  final Function(List<SelectedUserConfig>) onSelectionChanged;
  final bool isTr;
  final AppUser currentUser;

  const StaffPicker({
    super.key,
    required this.users,
    required this.availableGroups,
    required this.onSelectionChanged,
    required this.isTr,
    required this.currentUser,
  });

  @override
  State<StaffPicker> createState() => _StaffPickerState();
}

class _StaffPickerState extends State<StaffPicker> {
  late List<SelectedUserConfig> _configs;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _initConfigs();
  }

  @override
  void didUpdateWidget(covariant StaffPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users ||
        oldWidget.availableGroups != widget.availableGroups) {
      _initConfigs(preserveSelection: true);
    }
  }

  void _initConfigs({bool preserveSelection = false}) {
    final oldConfigs = preserveSelection ? _configs : <SelectedUserConfig>[];
    _configs = widget.users.map((u) {
      final old = preserveSelection
          ? oldConfigs.where((c) => c.user.id == u.id).firstOrNull
          : null;
      
      // Default to the first available group if the old group is no longer available
      int defaultGrupId = widget.availableGroups.isNotEmpty
          ? widget.availableGroups.first.grupId
          : 1;
          
      if (old != null) {
        bool groupExists = widget.availableGroups.any((g) => g.grupId == old.grupId);
        return SelectedUserConfig(
          user: u,
          isSelected: old.isSelected,
          grupId: groupExists ? old.grupId : defaultGrupId,
          role: old.role,
          sehirTipi: old.sehirTipi,
          ucret: old.ucret,
        );
      }

      return SelectedUserConfig(
        user: u,
        ucret: u.defaultWage ?? 0.0,
        role: u.isManager || u.isOwner ? DavetRole.manager : DavetRole.staff,
        grupId: defaultGrupId,
      );
    }).toList();
  }

  void _notifyChanges() {
    widget.onSelectionChanged(_configs.where((c) => c.isSelected).toList());
  }

  void _toggleSelectAll(bool? val) {
    if (val == null) return;
    setState(() {
      _selectAll = val;
      for (var c in _configs) {
        c.isSelected = val;
      }
    });
    _notifyChanges();
  }

  @override
  Widget build(BuildContext context) {
    if (_configs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.isTr
                ? 'Seçilebilecek personel bulunmuyor.'
                : 'No personnel available.',
            style: const TextStyle(color: AppColors.textHint),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.isTr ? 'Personel Seçimi' : 'Staff Selection',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                Text(
                  widget.isTr ? 'Hepsini Seç' : 'Select All',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Checkbox(
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                  activeColor: AppColors.accentLight,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _configs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final config = _configs[index];
            return _buildUserCard(config);
          },
        ),
      ],
    );
  }

  Widget _buildUserCard(SelectedUserConfig config) {
    final u = config.user;
    final isMe = u.id == widget.currentUser.id;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.isSelected
              ? AppColors.accentLight
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: config.isSelected,
                onChanged: (val) {
                  setState(() {
                    config.isSelected = val ?? false;
                    _selectAll = _configs.every((c) => c.isSelected);
                  });
                  _notifyChanges();
                },
                activeColor: AppColors.accentLight,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.fullName + (isMe ? (widget.isTr ? ' (Ben)' : ' (Me)') : ''),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      u.username,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (config.isSelected)
                DropdownButton<DavetRole>(
                  value: config.role,
                  dropdownColor: AppColors.surface,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentLight,
                  ),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: AppColors.accentLight, size: 20),
                  items: [
                    DropdownMenuItem(
                      value: DavetRole.staff,
                      child: Text(widget.isTr ? 'Personel' : 'Staff'),
                    ),
                    DropdownMenuItem(
                      value: DavetRole.manager,
                      child: Text(widget.isTr ? 'Yönetici' : 'Manager'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        config.role = val;
                      });
                      _notifyChanges();
                    }
                  },
                ),
            ],
          ),
          if (config.isSelected) ...[
            const Divider(color: AppColors.surface),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: config.grupId,
                    decoration: InputDecoration(
                      labelText: widget.isTr ? 'Grup Seç' : 'Select Group',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    dropdownColor: AppColors.card,
                    items: widget.availableGroups.map((g) {
                      return DropdownMenuItem(
                        value: g.grupId,
                        child: Text(
                          '${widget.isTr ? 'Grup' : 'Group'} ${g.grupId} (${g.saat})',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => config.grupId = val);
                        _notifyChanges();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<SehirTipi>(
                    initialValue: config.sehirTipi,
                    decoration: InputDecoration(
                      labelText: widget.isTr ? 'Şehir' : 'City',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    dropdownColor: AppColors.card,
                    items: SehirTipi.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(
                          t == SehirTipi.ici
                              ? (widget.isTr ? 'Şehir İçi' : 'In City')
                              : (widget.isTr ? 'Şehir Dışı' : 'Out of City'),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => config.sehirTipi = val);
                        _notifyChanges();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: config.ucret > 0 ? config.ucret.toStringAsFixed(0) : '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: widget.isTr ? 'Ücret' : 'Wage',
                labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                config.ucret = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                _notifyChanges();
              },
            ),
          ],
        ],
      ),
    );
  }
}
