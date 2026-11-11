import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import 'package:pet_profile_app/core/widgets/async_state/async_error_state.dart';
import 'package:pet_profile_app/core/widgets/async_state/labelled_progress.dart';
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
        loading: () => Center(child: LabelledProgress(label: l.loadingLabel)),
        error: (error, _) => AsyncErrorState(
          title: l.petTagsLoadError,
          onRetry: () => ref.read(petTagListProvider.notifier).refresh(),
        ),
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
                    child: Text(l.petTagsEmpty, textAlign: TextAlign.center),
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
                              child: Semantics(
                                label: l.petTagUsageCount(tag.petIds.length),
                                child: Chip(
                                  label: Text(
                                    l.petTagUsageCount(tag.petIds.length),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'rename') {
                                await _renameTag(
                                  context,
                                  ref,
                                  tag.id,
                                  tag.name,
                                );
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
    if (name == null) return;
    try {
      await ref.read(petTagListProvider.notifier).createTag(name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorWithMessage('$e'))));
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
    if (name == null) return;
    try {
      await ref.read(petTagListProvider.notifier).renameTag(tagId, name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorWithMessage('$e'))));
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
    try {
      await ref.read(petTagListProvider.notifier).deleteTag(tag.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.petTagDeleteFailed)));
      }
    }
  }

  Future<String?> _promptForName(
    BuildContext context,
    String title,
    String initialValue,
  ) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: l.petTagsNameHint),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l.petTagNameRequired;
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
              child: Text(l.save),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}
