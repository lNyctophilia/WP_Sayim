import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/sayim.dart';
import '../../../../core/constants/app_strings.dart';

class GrupSelector extends StatefulWidget {
  final List<SayimGrup> initialGruplar;
  final Function(List<SayimGrup>) onChanged;
  final bool isTr;

  const GrupSelector({
    super.key,
    required this.initialGruplar,
    required this.onChanged,
    required this.isTr,
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

  Future<void> _pickTime(int index) async {
    final currentSaat = _gruplar[index].saat;
    final parts = currentSaat.split(':');
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
              colorScheme: const ColorScheme.dark(
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
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _gruplar[index] =
            SayimGrup(grupId: _gruplar[index].grupId, saat: formattedTime);
      });
      widget.onChanged(_gruplar);
    }
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
              style: const TextStyle(
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
                    onTap: () => _pickTime(index),
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
                          const SizedBox(width: 8),
                          Text(
                            '${AppStrings.get('group', widget.isTr ? 'tr' : 'en')} ${index + 1}: ${grup.saat}',
                            style: const TextStyle(
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
                    icon: const Icon(Icons.remove_circle_outline_rounded,
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
