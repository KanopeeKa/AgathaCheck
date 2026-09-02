import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet.dart';
import '../widgets/pet_card.dart';

class FosteredPetsSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (fosteredActive.isEmpty && orgFilter == '_fostered') {
      return _EmptySection(message: l.noFosteredPets);
    }
    if (fosteredActive.isEmpty) return const SizedBox.shrink();

    final sorted = [...fosteredActive];
    sortPetsByCreatedAt(sorted);

    return PetTileStrip(
      useWrap: true,
      pets: sorted,
      onPetTap: (pet) => context.go('/pet/${pet.id}'),
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
