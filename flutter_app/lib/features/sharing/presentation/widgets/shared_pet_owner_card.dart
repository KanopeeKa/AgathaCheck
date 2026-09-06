import 'package:flutter/material.dart';

class SharedPetOwnerCard extends StatelessWidget {
  final Map<String, dynamic> ownerData;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const SharedPetOwnerCard({
    super.key,
    required this.ownerData,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final first = ownerData['first_name'] as String? ?? '';

    return Card(
      child: ListTile(
        leading: Icon(Icons.person, color: colorScheme.primary),
        title: Text(first, style: theme.textTheme.titleMedium),
      ),
    );
  }
}
