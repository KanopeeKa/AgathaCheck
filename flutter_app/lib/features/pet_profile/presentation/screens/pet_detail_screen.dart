import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../health_tracking/presentation/widgets/health_entry_card.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../data/models/pet_model.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';

/// Detail screen for a single pet showing profile info and health entries.
///
/// Displays the pet's profile at the top and their linked health entries
/// below, organized by type tabs.
class PetDetailScreen extends ConsumerStatefulWidget {
  /// Creates the [PetDetailScreen] for the pet with [petId].
  const PetDetailScreen({super.key, required this.petId});

  /// The ID of the pet to display.
  final String petId;

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    null,
    HealthEntryType.medication,
    HealthEntryType.preventive,
    HealthEntryType.vaccine,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _sharePet(BuildContext context, Pet pet) async {
    final baseUrl = kIsWeb ? '' : 'http://localhost:5000';
    final petJson = PetModel.fromEntity(pet).toJson();
    petJson.remove('photoPath');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/share'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pet': petJson, 'pet_id': pet.id}),
      );

      if (!context.mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final code = data['share_code'] as String;
        final uri = Uri.base;
        final shareUrl = '${uri.scheme}://${uri.host}'
            '${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}'
            '/shared/$code';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Share Link'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Share this link so others can view ${pet.name}\'s profile:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(shareUrl,
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create share link')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(petListProvider);
    final theme = Theme.of(context);

    return petListAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Pet Details')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (pets) {
        final pet = pets.where((p) => p.id == widget.petId).firstOrNull;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pet Details')),
            body: const Center(child: Text('Pet not found')),
          );
        }

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                title: Text(pet.name),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share Pet',
                    onPressed: () => _sharePet(context, pet),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Pet',
                    onPressed: () => context.go('/edit/${pet.id}'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: _PetProfileCard(pet: pet),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.medical_services,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Health Tracking',
                          style: theme.textTheme.titleLarge),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Medications'),
                      Tab(text: 'Preventives'),
                      Tab(text: 'Vaccines'),
                    ],
                  ),
                  theme.colorScheme.surface,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((type) => _PetEntryList(
                        petId: widget.petId,
                        type: type,
                      ))
                  .toList(),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go('/pet/${widget.petId}/health/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add Entry'),
          ),
        );
      },
    );
  }
}

class _PetProfileCard extends ConsumerWidget {
  const _PetProfileCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final vetsAsync = ref.watch(vetListProvider);
    final vets = vetsAsync.valueOrNull ?? [];
    final assignedVet = (pet.vetId != null && pet.vetId!.isNotEmpty)
        ? vets.where((v) => v.id == pet.vetId).firstOrNull
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 140,
                child: _PetPhoto(pet: pet),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.name, style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(icon: Icons.category, label: pet.species),
                          if (pet.breed.isNotEmpty)
                            _InfoChip(icon: Icons.pets, label: pet.breed),
                          if (pet.age != null)
                            _InfoChip(
                                icon: Icons.cake,
                                label: '${pet.age!.toStringAsFixed(1)} yrs'),
                          if (pet.weight != null)
                            _InfoChip(
                                icon: Icons.monitor_weight,
                                label:
                                    '${pet.weight!.toStringAsFixed(1)} kg'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildVetRow(context, ref, assignedVet, vets,
                          theme, colorScheme),
                      if (pet.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(pet.bio,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
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

  Widget _buildVetRow(BuildContext context, WidgetRef ref, dynamic assignedVet,
      List vets, ThemeData theme, ColorScheme colorScheme) {
    if (vets.isEmpty) {
      return GestureDetector(
        onTap: () => GoRouter.of(context).go('/vets/add'),
        child: Row(
          children: [
            Icon(Icons.local_hospital, size: 16,
                color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('No vet assigned',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant)),
            const SizedBox(width: 4),
            Text('— Add one',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Row(
      children: [
        Icon(Icons.local_hospital, size: 16,
            color: assignedVet != null
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: PopupMenuButton<String?>(
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  assignedVet != null ? assignedVet.name : 'No vet assigned',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: assignedVet != null
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: assignedVet != null
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 20,
                    color: colorScheme.onSurfaceVariant),
              ],
            ),
            onSelected: (vetId) async {
              final updated = vetId == null
                  ? pet.copyWith(clearVetId: true)
                  : pet.copyWith(vetId: vetId);
              await ref.read(petListProvider.notifier).updatePet(updated);
            },
            itemBuilder: (context) => [
              if (assignedVet != null)
                const PopupMenuItem<String?>(
                  value: null,
                  child: Text('Remove vet'),
                ),
              ...vets.map((vet) => PopupMenuItem<String?>(
                    value: vet.id,
                    enabled: assignedVet?.id != vet.id,
                    child: Text(vet.name),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _PetPhoto extends StatelessWidget {
  const _PetPhoto({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (pet.photoPath != null && pet.photoPath!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet.photoPath!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }

    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.pets,
          size: 56,
          color: colorScheme.onPrimaryContainer.withAlpha(100),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PetEntryList extends ConsumerWidget {
  const _PetEntryList({required this.petId, this.type});

  final String petId;
  final HealthEntryType? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync =
        ref.watch(petHealthEntriesProvider(petId));

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(petHealthEntriesProvider(petId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (allEntries) {
        final entries = type == null
            ? allEntries
            : allEntries.where((e) => e.type == type).toList();

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.medical_services_outlined,
                    size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  type == null
                      ? 'No health entries yet'
                      : 'No ${type!.label.toLowerCase()}s yet',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HealthEntryCard(
                entry: entry,
                onTap: () =>
                    context.go('/pet/$petId/health/edit/${entry.id}'),
                onMarkTaken: () {
                  ref
                      .read(healthEntriesNotifierProvider.notifier)
                      .markTaken(entry.id);
                  ref.invalidate(petHealthEntriesProvider(petId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${entry.name} marked as taken')),
                  );
                },
                onDelete: () async {
                  await ref
                      .read(healthEntriesNotifierProvider.notifier)
                      .delete(entry.id);
                  ref.invalidate(petHealthEntriesProvider(petId));
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar, this.backgroundColor);

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
