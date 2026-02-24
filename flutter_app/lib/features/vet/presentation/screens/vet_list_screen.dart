import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/vet_providers.dart';

class VetListScreen extends ConsumerWidget {
  const VetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vetListAsync = ref.watch(vetListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinarians'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: vetListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load vets: $error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () =>
                    ref.read(vetListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (vets) {
          if (vets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_hospital_outlined,
                      size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No veterinarians yet',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a vet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(vetListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vets.length,
              itemBuilder: (context, index) {
                final vet = vets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.local_hospital,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text(vet.name,
                        style: theme.textTheme.titleMedium),
                    subtitle: _buildSubtitle(vet),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.go('/vets/edit/${vet.id}');
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref, vet);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => context.go('/vets/edit/${vet.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/vets/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Vet'),
      ),
    );
  }

  Widget? _buildSubtitle(vet) {
    final parts = <String>[];
    if (vet.phone.isNotEmpty) parts.add(vet.phone);
    if (vet.email.isNotEmpty) parts.add(vet.email);
    if (parts.isEmpty) return null;
    return Text(parts.join(' • '));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, vet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vet'),
        content: Text('Are you sure you want to delete ${vet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(vetListProvider.notifier).deleteVet(vet.id);
    }
  }
}
