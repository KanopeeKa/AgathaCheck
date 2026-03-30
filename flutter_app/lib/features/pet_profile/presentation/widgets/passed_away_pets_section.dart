import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/pet.dart';
import '../widgets/pet_card.dart';

class PassedAwayPetsSection extends StatelessWidget {
  final List<Pet> allPassedAway;
  final dynamic theme;

  const PassedAwayPetsSection({
    super.key,
    required this.allPassedAway,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (allPassedAway.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          key: const Key('passed_away_section'),
          leading: Icon(
            Icons.favorite,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          title: Text(
            'Rainbow Bridge',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${allPassedAway.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: allPassedAway.map((pet) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PetCard(
                    pet: pet,
                    onTap: () => context.go('/pet/${pet.id}'),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
