import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/form/app_form_destructive_button.dart';
import '../../../../core/widgets/form/app_form_section.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/people_api_exception.dart';
import '../../application/people_commands.dart';
import '../../domain/entities/contact_detail.dart';
import 'person_form_controller.dart';
import 'person_form_errors.dart';
import 'usages_dialog.dart';

class PersonEditDangerZone extends ConsumerWidget {
  const PersonEditDangerZone({
    super.key,
    required this.controller,
    required this.onBusyChanged,
  });

  final PersonFormController controller;
  final ValueChanged<bool> onBusyChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final detail = controller.baseline;

    return AppFormSection(
      title: l.peopleDangerZoneTitle,
      children: [
        if (detail.inactiveAt == null)
          OutlinedButton.icon(
            key: const Key('people_edit_mark_inactive'),
            onPressed: () => _markInactive(context, ref, detail),
            icon: const Icon(Icons.pause_circle_outline),
            label: Text(l.peopleMarkInactive),
          )
        else
          OutlinedButton.icon(
            key: const Key('people_edit_reactivate'),
            onPressed: () => _reactivate(context, ref, detail),
            icon: const Icon(Icons.play_circle_outline),
            label: Text(l.peopleReactivate),
          ),
        const SizedBox(height: 8),
        AppFormDestructiveButton(
          buttonKey: const Key('people_edit_remove_contact'),
          label: l.peopleRemoveContactConfirm,
          onPressed: () => _removeContact(context, ref, detail),
        ),
      ],
    );
  }

  Future<void> _markInactive(
    BuildContext context,
    WidgetRef ref,
    ContactDetail detail,
  ) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.peopleMarkInactive),
        content: Text(l.peopleMarkInactiveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.peopleMarkInactive),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    onBusyChanged(true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .patchContact(detail.id, controller.buildMarkInactivePatch());
      if (context.mounted) context.pop(true);
    } catch (e) {
      if (context.mounted) {
        _showError(context, l, e);
      }
    } finally {
      onBusyChanged(false);
    }
  }

  Future<void> _reactivate(
    BuildContext context,
    WidgetRef ref,
    ContactDetail detail,
  ) async {
    final l = AppLocalizations.of(context)!;
    onBusyChanged(true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .patchContact(detail.id, controller.buildReactivatePatch());
      if (context.mounted) context.pop(true);
    } catch (e) {
      if (context.mounted) _showError(context, l, e);
    } finally {
      onBusyChanged(false);
    }
  }

  Future<void> _removeContact(
    BuildContext context,
    WidgetRef ref,
    ContactDetail detail,
  ) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.peopleRemoveContactTitle),
        content: Text(l.peopleRemoveContactBody(detail.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.peopleRemoveContactConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    onBusyChanged(true);
    try {
      await ref.read(peopleCommandsProvider).deleteContact(detail.id);
      if (context.mounted) context.go('/pc/people');
    } on PeopleApiException catch (e) {
      if (e.statusCode == 409 && e.usages.isNotEmpty && context.mounted) {
        await showContactUsagesDialog(
          context,
          usages: e.usages,
          onMarkInactive: () => _markInactive(context, ref, detail),
        );
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(personFormDeleteErrorMessage(l, e))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleRemoveError)));
      }
    } finally {
      onBusyChanged(false);
    }
  }

  void _showError(BuildContext context, AppLocalizations l, Object error) {
    if (error is PeopleApiException) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(personFormSaveErrorMessage(l, error))),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.peopleSaveError)));
  }
}
