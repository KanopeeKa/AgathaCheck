import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/pet.dart';
import '../widgets/pet_card.dart';

class FosteredPetsSection extends StatelessWidget {
  final List<Pet> fosteredActive;
  final String? orgFilter;
  final dynamic l;
  final ThemeData theme;

  const FosteredPetsSection({
    super.key,
    required this.fosteredActive,
    required this.orgFilter,
    required this.l,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (fosteredActive.isEmpty && orgFilter == '_fostered') {
      return _EmptySection(message: l.noFosteredPets);
    }
    if (fosteredActive.isEmpty) return const SizedBox.shrink();
    return Column(
      children: fosteredActive
          .map(
            (pet) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PetCard(
                pet: pet,
                onTap: () => context.go('/pet/${pet.id}'),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
