import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_commands.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/contact_summary.dart';
import '../../domain/enums/contact_group.dart';
import '../../domain/enums/contact_kind.dart';
import '../../domain/enums/contact_role.dart';

Future<ContactSummary?> showQuickAddPersonSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String initialName,
  ContactGroup presetGroup = ContactGroup.carer,
  List<ContactRole> presetRoles = const [ContactRole.sitter],
}) {
  return showModalBottomSheet<ContactSummary>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _QuickAddPersonSheet(
      initialName: initialName,
      presetGroup: presetGroup,
      presetRoles: presetRoles,
    ),
  );
}

class _QuickAddPersonSheet extends ConsumerStatefulWidget {
  const _QuickAddPersonSheet({
    required this.initialName,
    required this.presetGroup,
    required this.presetRoles,
  });

  final String initialName;
  final ContactGroup presetGroup;
  final List<ContactRole> presetRoles;

  @override
  ConsumerState<_QuickAddPersonSheet> createState() =>
      _QuickAddPersonSheetState();
}

class _QuickAddPersonSheetState extends ConsumerState<_QuickAddPersonSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.peoplePickerQuickAddTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l.peopleNameLabel),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: l.peoplePhoneLabel),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l.peoplePickerQuickAddSave),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(peopleRepositoryProvider);
      final detail = await repo.createContact({
        'kind': ContactKind.person.wireValue,
        'name': name,
        if (widget.presetRoles.isNotEmpty)
          'roles': widget.presetRoles.map((r) => r.wireValue).toList(),
        if (_phoneController.text.trim().isNotEmpty)
          'phone': _phoneController.text.trim(),
      });
      await ref.read(peopleCommandsProvider).afterContactMutation(detail.id);
      if (context.mounted) {
        Navigator.of(context).pop(detail.toSummary());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
