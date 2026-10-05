import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/contact_group.dart';
import '../../domain/enums/contact_role.dart';
import '../labels/people_labels.dart';

enum RoleChipsMode { display, groupedSelect }

/// Role chips for display or grouped multi-select in forms.
class RoleChips extends StatelessWidget {
  const RoleChips({
    super.key,
    required this.roles,
    this.mode = RoleChipsMode.display,
    this.selected = const {},
    this.onToggle,
  });

  final List<ContactRole> roles;
  final RoleChipsMode mode;
  final Set<ContactRole> selected;
  final ValueChanged<ContactRole>? onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (mode == RoleChipsMode.display) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: roles
            .map(
              (role) => Chip(
                label: Text(role.label(l)),
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in ContactGroup.values)
          if (_rolesForGroup(group).isNotEmpty) ...[
            Text(group.label(l), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _rolesForGroup(group)
                  .map(
                    (role) => FilterChip(
                      label: Text(role.label(l)),
                      selected: selected.contains(role),
                      onSelected: onToggle == null
                          ? null
                          : (_) => onToggle!(role),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  List<ContactRole> _rolesForGroup(ContactGroup group) {
    return ContactRole.values.where((r) => r.group == group).toList();
  }
}
