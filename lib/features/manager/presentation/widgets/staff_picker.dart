import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/models/davet.dart';
import '../../../../core/models/app_settings.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/constants/app_strings.dart';

class SelectedUserConfig {
  final AppUser user;
  int grupId;
  double multiplier;
  double ucret;
  DavetRole role;
  bool isSelected;
  bool isExpanded;

  SelectedUserConfig({
    required this.user,
    this.grupId = 1,
    this.multiplier = 1.0,
    this.ucret = 0.0,
    this.role = DavetRole.staff,
    this.isSelected = false,
    this.isExpanded = false,
  });
}

class StaffPicker extends StatefulWidget {
  final List<AppUser> users;
  final List<SayimGrup> availableGroups;
  final Function(List<SelectedUserConfig>) onSelectionChanged;
  final bool isTr;
  final AppUser currentUser;
  final SehirTipi sayimSehirTipi;
  final double globalMultiplier;
  final List<SelectedUserConfig>? initialSelections;
  final int targetPersonel;
  final int targetYonetici;
  final int alreadySelectedPersonel;
  final int alreadySelectedYonetici;
  final List<String> busyUserIds;

  const StaffPicker({
    super.key,
    required this.users,
    required this.availableGroups,
    required this.onSelectionChanged,
    required this.isTr,
    required this.currentUser,
    this.sayimSehirTipi = SehirTipi.ici,
    this.globalMultiplier = 1.0,
    this.initialSelections,
    this.targetPersonel = 0,
    this.targetYonetici = 0,
    this.alreadySelectedPersonel = 0,
    this.alreadySelectedYonetici = 0,
    this.busyUserIds = const [],
  });

  @override
  State<StaffPicker> createState() => _StaffPickerState();
}

class _StaffPickerState extends State<StaffPicker> {
  List<SelectedUserConfig> _configs = [];
  bool _selectAll = false;
  final SettingsService _settingsService = SettingsService();
  AppSettings _settings = AppSettings();
  bool _isLoadingSettings = true;

  DateTime? _lastSnackBarTime;
  String? _lastSnackBarMsg;

  void _showLimitSnackBar(String trMsg, String enMsg) {
    final now = DateTime.now();
    final msg = widget.isTr ? trMsg : enMsg;
    
    if (_lastSnackBarTime != null && 
        msg == _lastSnackBarMsg && 
        now.difference(_lastSnackBarTime!).inMilliseconds < 2500) {
      return;
    }

    _lastSnackBarTime = now;
    _lastSnackBarMsg = msg;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await _settingsService.getSettingsOnce();
    _initConfigs();
    if (mounted) {
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant StaffPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users ||
        oldWidget.availableGroups != widget.availableGroups ||
        oldWidget.sayimSehirTipi != widget.sayimSehirTipi ||
        oldWidget.globalMultiplier != widget.globalMultiplier) {
      _initConfigs(preserveSelection: true, oldWidget: oldWidget);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyChanges();
      });
    }
  }

  double _calculateWage(DavetRole role, double multiplier, [SehirTipi? overrideSehirTipi]) {
    double baseWage = 0.0;
    final sehirTipi = overrideSehirTipi ?? widget.sayimSehirTipi;
    if (role == DavetRole.staff) {
      baseWage = sehirTipi == SehirTipi.ici
          ? _settings.staffSehirIciWage
          : _settings.staffSehirDisiWage;
    } else {
      baseWage = sehirTipi == SehirTipi.ici
          ? _settings.managerSehirIciWage
          : _settings.managerSehirDisiWage;
    }
    return baseWage * multiplier;
  }

  void _initConfigs({bool preserveSelection = false, StaffPicker? oldWidget}) {
    final oldConfigs = preserveSelection ? _configs : (widget.initialSelections ?? <SelectedUserConfig>[]);
    _configs = widget.users.map((u) {
      final old = (preserveSelection || widget.initialSelections != null)
          ? oldConfigs.where((c) => c.user.id == u.id).firstOrNull
          : null;
      
      // Default to the first available group if the old group is no longer available
      int defaultGrupId = widget.availableGroups.isNotEmpty
          ? widget.availableGroups.first.grupId
          : 1;
          
      if (old != null) {
        bool groupExists = widget.availableGroups.any((g) => g.grupId == old.grupId);
        
        bool forceRecalculate = false;
        bool wasManuallyEdited = false;
        
        if (oldWidget != null) {
          if (oldWidget.sayimSehirTipi != widget.sayimSehirTipi || oldWidget.globalMultiplier != widget.globalMultiplier) {
            forceRecalculate = true;
          } else {
            // Sadece kullanıcı listesi vb. değiştiyse, eski değeri koru
            wasManuallyEdited = true;
          }
        } else {
          // It's the first load with initial selections, preserve the saved wage
          wasManuallyEdited = true;
        }

        // Recalculate ucret because global settings or sehirTipi might have changed
        double newMultiplier = old.multiplier;
        if (oldWidget != null && oldWidget.globalMultiplier != widget.globalMultiplier && old.multiplier == oldWidget.globalMultiplier) {
          // If the old multiplier was exactly the old global multiplier, update it
          newMultiplier = widget.globalMultiplier;
        } else if (oldWidget != null && oldWidget.globalMultiplier != widget.globalMultiplier) {
          newMultiplier = widget.globalMultiplier; // Force new multiplier
        }
        
        
        bool isBusy = widget.busyUserIds.contains(u.id);
        
        return SelectedUserConfig(
          user: u,
          isSelected: isBusy ? false : (old.isSelected || (widget.initialSelections?.any((c) => c.user.id == u.id) ?? false)),
          grupId: groupExists ? old.grupId : defaultGrupId,
          role: old.role,
          multiplier: newMultiplier,
          ucret: forceRecalculate ? _calculateWage(old.role, newMultiplier) : (wasManuallyEdited ? old.ucret : _calculateWage(old.role, newMultiplier)), 
          isExpanded: old.isExpanded,
        );
      }

      final role = u.isManager || u.isOwner ? DavetRole.manager : DavetRole.staff;
      final multiplier = widget.globalMultiplier;
      final autoWage = _calculateWage(role, multiplier);
      
      bool isBusy = widget.busyUserIds.contains(u.id);

      return SelectedUserConfig(
        user: u,
        isSelected: isBusy ? false : (widget.initialSelections?.any((c) => c.user.id == u.id) ?? false),
        ucret: autoWage > 0 ? autoWage : (u.defaultWage ?? 0.0),
        role: role,
        grupId: defaultGrupId,
        multiplier: multiplier,
        isExpanded: false,
      );
    }).toList();

    _selectAll = _configs.isNotEmpty && _configs.every((c) => c.isSelected);
  }

  void _notifyChanges() {
    widget.onSelectionChanged(_configs.where((c) => c.isSelected).toList());
  }

  void _toggleSelectAll(bool? val) {
    if (val == null) return;
    setState(() {
      _selectAll = val;
      for (var c in _configs) {
        if (!widget.busyUserIds.contains(c.user.id)) {
          c.isSelected = val;
        } else {
          c.isSelected = false;
        }
      }
    });
    _notifyChanges();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppColors.accentLight),
        ),
      );
    }

    if (_configs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            AppStrings.get('no_personnel_available', widget.isTr ? 'tr' : 'en'),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('staff_selection', widget.isTr ? 'tr' : 'en'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.getFormat('staff_selection_count', widget.isTr ? 'tr' : 'en', [_configs.where((c) => c.isSelected && c.role == DavetRole.staff).length + widget.alreadySelectedPersonel, widget.targetPersonel, _configs.where((c) => c.isSelected && c.role == DavetRole.manager).length + widget.alreadySelectedYonetici, widget.targetYonetici]),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentLight,
                  ),
                ),
              ],
            ),
            Builder(builder: (context) {
              int totalP = _configs.where((c) => c.role == DavetRole.staff).length + widget.alreadySelectedPersonel;
              int totalY = _configs.where((c) => c.role == DavetRole.manager).length + widget.alreadySelectedYonetici;
              bool canSelectAll = totalP <= widget.targetPersonel && totalY <= widget.targetYonetici;
              return Row(
                children: [
                  Text(
                    AppStrings.get('select_all', widget.isTr ? 'tr' : 'en'),
                    style: TextStyle(
                      fontSize: 13,
                      color: canSelectAll ? AppColors.textSecondary : AppColors.textHint,
                    ),
                  ),
                  Checkbox(
                    value: _selectAll,
                    onChanged: canSelectAll ? _toggleSelectAll : null,
                    activeColor: AppColors.accentLight,
                  ),
                ],
              );
            }),
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

  void _toggleSelection(SelectedUserConfig config, bool val) {
    if (val == true) {
      int currentP = _configs.where((c) => c.isSelected && c.role == DavetRole.staff).length + widget.alreadySelectedPersonel;
      int currentY = _configs.where((c) => c.isSelected && c.role == DavetRole.manager).length + widget.alreadySelectedYonetici;
      
      if (config.role == DavetRole.staff && currentP >= widget.targetPersonel) {
        _showLimitSnackBar('Personel sınırına ulaştınız!', 'Personnel limit reached!');
        return;
      }
      if (config.role == DavetRole.manager && currentY >= widget.targetYonetici) {
        if (currentP < widget.targetPersonel) {
          config.role = DavetRole.staff;
          config.ucret = _calculateWage(config.role, config.multiplier);
        } else {
          _showLimitSnackBar('Yönetici sınırına ulaştınız!', 'Manager limit reached!');
          return;
        }
      }
    }

    setState(() {
      config.isSelected = val;
      if (config.isSelected == false) {
        config.role = config.user.isManager || config.user.isOwner ? DavetRole.manager : DavetRole.staff;
        config.ucret = _calculateWage(config.role, config.multiplier);
        config.isExpanded = false;
      } else {
        config.isExpanded = true;
      }
      _selectAll = _configs.every((c) => c.isSelected || widget.busyUserIds.contains(c.user.id));
    });
    _notifyChanges();
  }

  Widget _buildUserCard(SelectedUserConfig config) {
    final u = config.user;
    final isMe = u.id == widget.currentUser.id;
    final isBusy = widget.busyUserIds.contains(u.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isBusy ? () {
        _showLimitSnackBar(
          'Bu kişi seçili tarihte başka bir sayımda!',
          'This person is already in another count on the selected date!',
        );
      } : () {
        if (!config.isSelected) {
          _toggleSelection(config, true);
        } else {
          setState(() {
            config.isExpanded = !config.isExpanded;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isBusy ? AppColors.surface : AppColors.card,
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
                AbsorbPointer(
                  absorbing: isBusy,
                  child: Checkbox(
                    value: config.isSelected,
                    onChanged: (val) {
                      _toggleSelection(config, val ?? false);
                    },
                    activeColor: AppColors.accentLight,
                    fillColor: isBusy ? WidgetStateProperty.all(AppColors.textHint.withValues(alpha: 0.5)) : null,
                  ),
                ),
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.fullName + (isMe ? AppStrings.get('me_suffix', widget.isTr ? 'tr' : 'en') : ''),
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
                if (u.isManager || u.isOwner)
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
                        child: Text(AppStrings.get('role_staff', widget.isTr ? 'tr' : 'en')),
                      ),
                      DropdownMenuItem(
                        value: DavetRole.manager,
                        child: Text(AppStrings.get('role_manager', widget.isTr ? 'tr' : 'en')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null && val != config.role) {
                        if (val == DavetRole.staff) {
                           int currentP = _configs.where((c) => c.isSelected && c.role == DavetRole.staff).length + widget.alreadySelectedPersonel;
                           if (currentP >= widget.targetPersonel) {
                             _showLimitSnackBar('Personel sınırına ulaştınız!', 'Personnel limit reached!');
                             return;
                           }
                        } else {
                           int currentY = _configs.where((c) => c.isSelected && c.role == DavetRole.manager).length + widget.alreadySelectedYonetici;
                           if (currentY >= widget.targetYonetici) {
                             _showLimitSnackBar('Yönetici sınırına ulaştınız!', 'Manager limit reached!');
                             return;
                           }
                        }
                        setState(() {
                          config.role = val;
                          config.ucret = _calculateWage(config.role, config.multiplier);
                        });
                        _notifyChanges();
                      }
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      AppStrings.get('role_staff', widget.isTr ? 'tr' : 'en'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
            ],
          ),
          if (config.isSelected && config.isExpanded) ...[
            const Divider(color: AppColors.surface),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: config.grupId,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('select_group', widget.isTr ? 'tr' : 'en'),
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
                          '${AppStrings.get('group', widget.isTr ? 'tr' : 'en')} ${g.grupId} (${g.saat})',
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
                  child: DropdownButtonFormField<double>(
                    initialValue: config.multiplier,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('multiplier', widget.isTr ? 'tr' : 'en'),
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    dropdownColor: AppColors.card,
                    items: [1.0, 1.5, 2.0].map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                          '${m}x',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          config.multiplier = val;
                          config.ucret = _calculateWage(config.role, val);
                        });
                        _notifyChanges();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('wage_${config.user.id}_${widget.sayimSehirTipi}_${config.multiplier}_${config.role}'),
              initialValue: config.ucret > 0 ? config.ucret.toStringAsFixed(0) : '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: AppStrings.get('wage', widget.isTr ? 'tr' : 'en'),
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
    ),
    );
  }
}
