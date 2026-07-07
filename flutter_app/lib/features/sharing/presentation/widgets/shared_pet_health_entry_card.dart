import 'package:flutter/material.dart';

class SharedPetHealthEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const SharedPetHealthEntryCard({
    super.key,
    required this.entry,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        (entry['name'] ?? entry['title'] ?? '').toString();
    final date =
        (entry['next_due_date'] ?? entry['date'] ?? '').toString();
    final notes = entry['notes']?.toString() ?? '';

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.medical_services_outlined,
          color: colorScheme.primary,
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(date),
        trailing: notes.isNotEmpty
            ? Icon(Icons.notes, color: colorScheme.primary)
            : null,
      ),
    );
  }
}
