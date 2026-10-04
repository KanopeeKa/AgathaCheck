import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/roster.dart';
import '../../domain/enums/contact_group.dart';
import '../../domain/enums/contact_kind.dart';
import '../../domain/services/people_query.dart';
import '../labels/people_labels.dart';
import '../widgets/person_avatar.dart';
import '../widgets/person_status_chip.dart';
import 'people_picker_result.dart';
import 'quick_add_person_sheet.dart';

Future<PeoplePickerResult?> showPeoplePickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PeopleQuery query,
  required String purpose,
  ContactGroup quickAddGroup = ContactGroup.carer,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 600) {
    return showDialog<PeoplePickerResult>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: PeoplePickerSheet(
            query: query,
            purpose: purpose,
            quickAddGroup: quickAddGroup,
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<PeoplePickerResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.92,
      child: PeoplePickerSheet(
        query: query,
        purpose: purpose,
        quickAddGroup: quickAddGroup,
      ),
    ),
  );
}

class PeoplePickerSheet extends ConsumerStatefulWidget {
  const PeoplePickerSheet({
    super.key,
    required this.query,
    required this.purpose,
    this.quickAddGroup = ContactGroup.carer,
  });

  final PeopleQuery query;
  final String purpose;
  final ContactGroup quickAddGroup;

  @override
  ConsumerState<PeoplePickerSheet> createState() => _PeoplePickerSheetState();
}

class _PeoplePickerSheetState extends ConsumerState<PeoplePickerSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final roster =
        ref.watch(rosterProvider).valueOrNull ??
        const Roster(households: [], contacts: [], pendingInvites: []);
    final data = buildPeoplePickerData(roster, widget.query);
    final search = _searchController.text;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l.peoplePickerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.peoplePickerSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                if (widget.query.allowNone)
                  _OptionTile(
                    key: const Key('people_picker_option_none'),
                    semanticsId: 'people_picker_option_none',
                    title: l.peoplePickerNone,
                    onTap: () => _pop(const PeoplePickerNoneResult()),
                  ),
                if (data.pinned != null) _buildPinned(context, l, data.pinned!),
                for (final section in data.sections) ...[
                  _SectionHeader(title: _sectionTitle(l, section.titleKey)),
                  for (final option in filterPickerOptions(
                    section.options,
                    search,
                  ))
                    _buildOption(context, l, option),
                ],
                if (search.trim().isNotEmpty) ...[
                  _OptionTile(
                    key: const Key('people_picker_add'),
                    semanticsId: 'people_picker_add',
                    title: l.peoplePickerAddQuery(search.trim()),
                    leading: const Icon(Icons.person_add_outlined),
                    onTap: () => _quickAdd(search.trim()),
                  ),
                  if (widget.query.allowTypedName)
                    _OptionTile(
                      key: Key('people_picker_typed_${search.trim()}'),
                      semanticsId: 'people_picker_typed_name',
                      title: l.peoplePickerUseWithoutSaving(search.trim()),
                      leading: const Icon(Icons.short_text),
                      onTap: () =>
                          _pop(PeoplePickerTypedNameResult(search.trim())),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinned(
    BuildContext context,
    AppLocalizations l,
    PeoplePickerOption option,
  ) {
    final inactive = option is ContactPickerOption && option.contact.isInactive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l.peoplePickerCurrentSelection),
        _buildOption(context, l, option, pinned: true),
        if (inactive)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: const PersonStatusChip(kind: PersonStatusChipKind.inactive),
          ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context,
    AppLocalizations l,
    PeoplePickerOption option, {
    bool pinned = false,
  }) {
    if (option is ContactPickerOption) {
      final contact = option.contact;
      return _OptionTile(
        key: Key('people_picker_option_${contact.id}'),
        semanticsId: 'people_picker_option_${contact.id}',
        title: contact.name,
        subtitle: contactRolesLine(l, contact.roles),
        leading: personAvatarFromSummary(contact),
        onTap: () => _pop(PeoplePickerContactResult(contact)),
      );
    }
    final member = option as HouseholdMemberPickerOption;
    return _OptionTile(
      key: Key('people_picker_option_${member.optionId}'),
      semanticsId: 'people_picker_option_${member.optionId}',
      title: member.displayName,
      subtitle: member.member.tier,
      leading: PersonAvatar(
        name: member.displayName,
        stableId: member.optionId,
        kind: ContactKind.person,
      ),
      onTap: pinned
          ? null
          : () {
              // Household members are not directory contacts in c2 — no-op pick.
            },
    );
  }

  String _sectionTitle(AppLocalizations l, String key) {
    switch (key) {
      case 'peopleGroupCarers':
        return l.peopleGroupCarers;
      case 'peopleGroupProfessionals':
        return l.peopleGroupProfessionals;
      case 'peoplePickerHouseholdMembersSection':
        return l.peoplePickerHouseholdMembersSection;
      case 'peoplePickerContactsSection':
        return l.peoplePickerContactsSection;
      default:
        return key;
    }
  }

  Future<void> _quickAdd(String query) async {
    final created = await showQuickAddPersonSheet(
      context: context,
      ref: ref,
      initialName: query,
      presetGroup: widget.quickAddGroup,
    );
    if (created != null) {
      _pop(PeoplePickerContactResult(created));
    }
  }

  void _pop(PeoplePickerResult result) {
    Navigator.of(context).pop(result);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.semanticsId,
    required this.title,
    this.subtitle,
    this.leading,
    required this.onTap,
  });

  final String semanticsId;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticsId,
      button: onTap != null,
      label: title,
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle == null || subtitle!.isEmpty
            ? null
            : Text(subtitle!),
        onTap: onTap,
        minVerticalPadding: 12,
      ),
    );
  }
}
