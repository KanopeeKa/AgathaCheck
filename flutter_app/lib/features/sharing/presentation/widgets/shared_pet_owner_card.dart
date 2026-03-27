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
    return Card(
      child: ListTile(
        leading: Icon(Icons.person, color: colorScheme.primary),
        title: Text(ownerData['name'] ?? '', style: theme.textTheme.titleMedium),
        subtitle: Text(ownerData['email'] ?? ''),
      ),
    );
  }
}
