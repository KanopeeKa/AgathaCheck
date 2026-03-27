import 'package:flutter/material.dart';

class HealthDashboardActions extends StatelessWidget {
  final void Function() onExportPdf;
  final void Function() onExportCsv;
  final void Function(_GroupMode) onGroupModeChanged;
  final _GroupMode groupMode;
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
        PopupMenuButton<_GroupMode>(
          icon: const Icon(Icons.sort),
          tooltip: lGroupBy,
          onSelected: onGroupModeChanged,
          itemBuilder: (_) => [
            PopupMenuItem(
              value: _GroupMode.dueDate,
              child: ListTile(
                leading: Icon(Icons.schedule,
                    color: groupMode == _GroupMode.dueDate
                        ? colorScheme.primary
                        : null),
                title: Text(lByDueDate),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _GroupMode.pet,
              child: ListTile(
                leading: Icon(Icons.pets,
                    color: groupMode == _GroupMode.pet
                        ? colorScheme.primary
                        : null),
                title: Text(lByPet),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _GroupMode.petType,
              child: ListTile(
                leading: Icon(Icons.category,
                    color: groupMode == _GroupMode.petType
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

enum _GroupMode { dueDate, pet, petType }
