import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/pet_profile.dart';
import '../../application/people_commands.dart';

Future<String?> showCreateHouseholdFlow(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => const _CreateHouseholdDialog(),
  );
}

class _CreateHouseholdDialog extends ConsumerStatefulWidget {
  const _CreateHouseholdDialog();

  @override
  ConsumerState<_CreateHouseholdDialog> createState() =>
      _CreateHouseholdDialogState();
}

class _CreateHouseholdDialogState
    extends ConsumerState<_CreateHouseholdDialog> {
  final _nameController = TextEditingController();
  final Set<String> _selectedPetIds = {};
  bool _busy = false;
  int _step = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Pet> pets) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      final household = await ref
          .read(peopleCommandsProvider)
          .createHousehold(name, petIds: _selectedPetIds.toList());
      if (mounted) Navigator.pop(context, household.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.peopleSaveError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(petListProvider);
    final pets = petsAsync.valueOrNull ?? const <Pet>[];

    return AlertDialog(
      title: Text(
        _step == 0 ? l.householdCreate : l.peopleHouseholdPetReviewTitle,
      ),
      content: SizedBox(
        width: 420,
        child: _step == 0
            ? TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l.householdNameLabel),
                autofocus: true,
                enabled: !_busy,
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.peopleHouseholdPetReviewBody),
                    const SizedBox(height: 12),
                    for (final pet in pets)
                      CheckboxListTile(
                        value: _selectedPetIds.contains(pet.id),
                        onChanged: _busy
                            ? null
                            : (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedPetIds.add(pet.id);
                                  } else {
                                    _selectedPetIds.remove(pet.id);
                                  }
                                });
                              },
                        title: Text(pet.name),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        if (_step == 0)
          FilledButton(
            onPressed: _busy
                ? null
                : () {
                    if (_nameController.text.trim().isEmpty) return;
                    setState(() => _step = 1);
                  },
            child: Text(l.continueButton),
          )
        else
          FilledButton(
            onPressed: _busy ? null : () => _submit(pets),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.householdCreate),
          ),
      ],
    );
  }
}
