import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../domain/entities/pet_tag.dart';
import '../providers/pet_tag_providers.dart';

class ManagePetTagsScreen extends ConsumerWidget {
  const ManagePetTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final tagsAsync = ref.watch(petTagListProvider);

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: '/account/pet-tags',
      screenTitle: l.petTagsTitle,
      child: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l.errorWithMessage('$error'))),
        data: (tags) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l.petTagsSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (tags.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l.petTagsEmpty,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: tags.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return ListTile(
                      key: Key('manage_pet_tag_${tag.id}'),
                      title: Text(tag.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tag.petIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text('${tag.petIds.length}'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'rename') {
                                await _renameTag(context, ref, tag.id, tag.name);
                              } else if (action == 'delete') {
                                await _deleteTag(context, ref, tag);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'rename',
                                child: Text(l.petTagsRename),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(l.petTagsDelete),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                key: const Key('pet_tags_add_button'),
                onPressed: () => _createTag(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l.petTagsAdd),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTag(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final name = await _promptForName(context, l.petTagsAdd, '');
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(petTagListProvider.notifier).createTag(name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorWithMessage('$e'))),
        );
      }
    }
  }

  Future<void> _renameTag(
    BuildContext context,
    WidgetRef ref,
    String tagId,
    String currentName,
  ) async {
    final l = AppLocalizations.of(context)!;
    final name = await _promptForName(context, l.petTagsRename, currentName);
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(petTagListProvider.notifier).renameTag(tagId, name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorWithMessage('$e'))),
        );
      }
    }
  }

  Future<void> _deleteTag(
    BuildContext context,
    WidgetRef ref,
    PetTag tag,
  ) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.petTagsDelete),
        content: Text(l.petTagsDeleteConfirm(tag.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(petTagListProvider.notifier).deleteTag(tag.id);
  }

  Future<String?> _promptForName(
    BuildContext context,
    String title,
    String initialValue,
  ) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l.petTagsNameHint),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}
