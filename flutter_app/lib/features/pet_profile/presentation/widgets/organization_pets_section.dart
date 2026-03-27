import 'package:flutter/material.dart';
import '../../domain/entities/pet.dart';
import '../widgets/pet_card.dart';

class OrganizationPetsSection extends StatelessWidget {
  final Map<String, List<Pet>> orgGroups;
  final dynamic l;
  final dynamic theme;
  final dynamic ref;
  final dynamic context;

  const OrganizationPetsSection({
    super.key,
    required this.orgGroups,
    required this.l,
    required this.theme,
    required this.ref,
    required this.context,
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
                                context: this.context,
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
                                if (this.context.mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(content: Text(l.petHidden(pet.name))),
                                  );
                                }
                              }
                              return false;
                            },
                            child: PetCard(
                              pet: pet,
                              onTap: () => this.context.go('/pet/${pet.id}'),
                            ),
                          )
                        : PetCard(
                            pet: pet,
                            onTap: () => this.context.go('/pet/${pet.id}'),
                          ),
                  )),
            ],
          ),
      ],
    );
  }
}
