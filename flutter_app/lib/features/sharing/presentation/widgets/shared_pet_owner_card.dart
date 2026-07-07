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
    final last = ownerData['last_name'] as String? ?? '';
    final name =
        (ownerData['name'] as String?)?.trim().isNotEmpty == true
            ? ownerData['name'] as String
            : '$first $last'.trim();

    return Card(
      child: ListTile(
        leading: Icon(Icons.person, color: colorScheme.primary),
        title: Text(
          name,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(ownerData['email'] ?? ''),
      ),
    );
  }
}
