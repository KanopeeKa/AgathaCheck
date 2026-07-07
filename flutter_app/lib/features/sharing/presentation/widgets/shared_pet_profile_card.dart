import 'package:flutter/material.dart';

class SharedPetProfileCard extends StatelessWidget {
  final String name;
  final String species;
  final String breed;
  final String? ageDisplay;
  final double? weight;
  final String? vetName;
  final String bio;
  final String? photoPath;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final Widget Function(String? photoPath, ColorScheme colorScheme) buildPhoto;
  final Widget Function(IconData icon, String label, ColorScheme colorScheme)
  buildChip;

  const SharedPetProfileCard({
    super.key,
    required this.name,
    required this.species,
    required this.breed,
    required this.ageDisplay,
    required this.weight,
    required this.vetName,
    required this.bio,
    required this.photoPath,
    required this.colorScheme,
    required this.theme,
    required this.buildPhoto,
    required this.buildChip,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 140, child: buildPhoto(photoPath, colorScheme)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          buildChip(Icons.category, species, colorScheme),
                          if (breed.isNotEmpty)
                            buildChip(Icons.pets, breed, colorScheme),
                          if (ageDisplay != null)
                            buildChip(Icons.cake, ageDisplay!, colorScheme),
                          if (weight != null)
                            buildChip(
                              Icons.monitor_weight,
                              '${weight!.toStringAsFixed(1)} kg',
                              colorScheme,
                            ),
                        ],
                      ),
                      if (vetName != null && vetName!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              vetName!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          bio,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
