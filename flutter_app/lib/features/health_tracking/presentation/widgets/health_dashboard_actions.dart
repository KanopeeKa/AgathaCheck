import 'package:flutter/material.dart';

class HealthDashboardActions extends StatelessWidget {
  final void Function() onExportPdf;
  final void Function() onExportCsv;
  final void Function(GroupMode) onGroupModeChanged;
  final GroupMode groupMode;
  final String lGroupBy;
  final String lByDueDate;
  final String lByPet;
  final String lBySpecies;
  final String lExportPdf;
  final String lExportCsv;

  const HealthDashboardActions({
    super.key,
    required this.onExportPdf,
    required this.onExportCsv,
    required this.onGroupModeChanged,
    required this.groupMode,
    required this.lGroupBy,
    required this.lByDueDate,
    required this.lByPet,
    required this.lBySpecies,
    required this.lExportPdf,
    required this.lExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        PopupMenuButton<GroupMode>(
          icon: const Icon(Icons.sort),
          tooltip: lGroupBy,
          onSelected: onGroupModeChanged,
          itemBuilder: (_) => [
            PopupMenuItem(
              value: GroupMode.dueDate,
              child: ListTile(
                leading: Icon(Icons.schedule,
                    color: groupMode == GroupMode.dueDate
                        ? colorScheme.primary
                        : null),
                title: Text(lByDueDate),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: GroupMode.pet,
              child: ListTile(
                leading: Icon(Icons.pets,
                    color: groupMode == GroupMode.pet
                        ? colorScheme.primary
                        : null),
                title: Text(lByPet),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: GroupMode.petType,
              child: ListTile(
                leading: Icon(Icons.category,
                    color: groupMode == GroupMode.petType
                        ? colorScheme.primary
                        : null),
                title: Text(lBySpecies),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: lExportPdf,
          onPressed: onExportPdf,
        ),
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: lExportCsv,
          onPressed: onExportCsv,
        ),
      ],
    );
  }
}

enum GroupMode { dueDate, pet, petType }
