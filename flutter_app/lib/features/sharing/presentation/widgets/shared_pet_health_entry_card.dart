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
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.medical_services_outlined,
          color: colorScheme.primary,
        ),
        title: Text(entry['title'] ?? '', style: theme.textTheme.titleMedium),
        subtitle: Text(entry['date'] ?? ''),
        trailing:
            entry['notes'] != null && (entry['notes'] as String).isNotEmpty
            ? Icon(Icons.notes, color: colorScheme.primary)
            : null,
      ),
    );
  }
}
