import 'package:flutter/material.dart';

class SharedPetVetCard extends StatelessWidget {
  final Map<String, dynamic> vetData;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const SharedPetVetCard({
    super.key,
    required this.vetData,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.local_hospital, color: colorScheme.primary),
        title: Text(vetData['name'] ?? '', style: theme.textTheme.titleMedium),
        subtitle: Text(vetData['phone'] ?? ''),
      ),
    );
  }
}
