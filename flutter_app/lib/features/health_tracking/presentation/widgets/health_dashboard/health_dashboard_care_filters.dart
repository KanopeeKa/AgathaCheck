import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_family_definition.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/care_family_write.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_family_labels.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_filter_group_labels.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Family and filter-group chips for the health dashboard care list.
class HealthDashboardCareFilters extends StatelessWidget {
  const HealthDashboardCareFilters({
    super.key,
    required this.selectedFilterGroup,
    required this.selectedFamily,
    required this.onFilterGroupChanged,
    required this.onFamilyChanged,
  });

  final CareFilterGroup? selectedFilterGroup;
  final CareFamily? selectedFamily;
  final ValueChanged<CareFilterGroup?> onFilterGroupChanged;
  final ValueChanged<CareFamily?> onFamilyChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterChipRow(
            children: [
              _groupChip(
                context,
                l,
                value: null,
                label: l.all,
                keySuffix: 'all',
              ),
              for (final group in CareFilterGroup.values)
                _groupChip(
                  context,
                  l,
                  value: group,
                  label: careFilterGroupLabel(l, group),
                  keySuffix: group.name,
                ),
            ],
          ),
          const SizedBox(height: 8),
          _FilterChipRow(
            children: [
              _familyChip(
                context,
                l,
                value: null,
                label: l.all,
                keySuffix: 'all',
              ),
              for (final family in kRecurringCareFamilyPickerOptions)
                _familyChip(
                  context,
                  l,
                  value: family,
                  label: careFamilyLabel(l, family),
                  keySuffix: family.name,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupChip(
    BuildContext context,
    AppLocalizations l, {
    required CareFilterGroup? value,
    required String label,
    required String keySuffix,
  }) {
    final selected = selectedFilterGroup == value;
    return FilterChip(
      key: Key('health_filter_group_$keySuffix'),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onFilterGroupChanged(value),
    );
  }

  Widget _familyChip(
    BuildContext context,
    AppLocalizations l, {
    required CareFamily? value,
    required String label,
    required String keySuffix,
  }) {
    final selected = selectedFamily == value;
    return FilterChip(
      key: Key('health_filter_family_$keySuffix'),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onFamilyChanged(value),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}
