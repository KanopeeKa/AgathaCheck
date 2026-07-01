import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../domain/entities/pet.dart';
import '../widgets/pet_card.dart';

class OrganizationPetsSection extends StatelessWidget {
  final Map<String, List<Pet>> orgGroups;
  final dynamic l;
  final ThemeData theme;
  final WidgetRef ref;
  final BuildContext parentContext;

  const OrganizationPetsSection({
    super.key,
    required this.orgGroups,
    required this.l,
    required this.theme,
    required this.ref,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    if (orgGroups.isEmpty) return const SizedBox.shrink();
    final sortedOrgNames = orgGroups.keys.toList()..sort();
    return Column(
      children: [
        for (final orgName in sortedOrgNames)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.business,
                title: orgName,
                count: (orgGroups[orgName]?.length ?? 0),
              ),
              ...orgGroups[orgName]!.map((pet) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: pet.isShared
                        ? Dismissible(
                            key: Key('hide_${pet.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(l.hideSharedPet, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                  const SizedBox(width: 8),
                                  Icon(Icons.visibility_off, color: theme.colorScheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                            confirmDismiss: (_) async {
                              final confirmed = await showDialog<bool>(
                                context: parentContext,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l.hideSharedPet),
                                  content: Text(l.hideSharedPetConfirm(pet.name)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.hide)),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ref.read(hiddenSharedPetsProvider.notifier).hideSharedPet(pet.id);
                                if (parentContext.mounted) {
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    SnackBar(content: Text(l.petHidden(pet.name))),
                                  );
                                }
                              }
                              return false;
                            },
                            child: PetCard(
                              pet: pet,
                              onTap: () => context.go('/pet/${pet.id}'),
                            ),
                          )
                        : PetCard(
                            pet: pet,
                            onTap: () => context.go('/pet/${pet.id}'),
                          ),
                  )),
            ],
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });
  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
