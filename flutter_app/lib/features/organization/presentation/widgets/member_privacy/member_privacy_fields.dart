import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/member_privacy_settings.dart';
import '../../../domain/entities/organization_member.dart';
import '../../../domain/services/member_privacy.dart';

class MemberPrivacyFields extends StatelessWidget {
  const MemberPrivacyFields({
    super.key,
    required this.settings,
    required this.role,
    required this.onChanged,
  });

  final MemberPrivacySettings settings;
  final OrgMemberRole? role;
  final ValueChanged<MemberPrivacySettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _enumDropdown<CardVisibility>(
          key: const Key('account_org_card_visibility'),
          label: l.accountOrgCardVisibilityLabel,
          value: settings.cardVisibility,
          items: cardVisibilityOptionsForRole(role),
          itemLabel: (value) => _cardLabel(l, value),
          onChanged: (value) {
            if (value == null) return;
            onChanged(settings.copyWith(cardVisibility: value));
          },
        ),
        const SizedBox(height: 12),
        _enumDropdown<ContactVisibility>(
          key: const Key('account_org_phone_visibility'),
          label: l.accountOrgPhoneVisibilityLabel,
          value: settings.phoneVisibility,
          items: phoneVisibilityOptionsForRole(role),
          itemLabel: (value) => _contactLabel(l, value),
          onChanged: (value) {
            if (value == null) return;
            onChanged(settings.copyWith(phoneVisibility: value));
          },
        ),
        const SizedBox(height: 12),
        _enumDropdown<ContactVisibility>(
          key: const Key('account_org_email_visibility'),
          label: l.accountOrgEmailVisibilityLabel,
          value: settings.emailVisibility,
          items: emailVisibilityOptionsForRole(role),
          itemLabel: (value) => _contactLabel(l, value),
          onChanged: (value) {
            if (value == null) return;
            onChanged(settings.copyWith(emailVisibility: value));
          },
        ),
        const SizedBox(height: 12),
        _enumDropdown<AddressVisibility>(
          key: const Key('account_org_address_visibility'),
          label: l.accountOrgAddressVisibilityLabel,
          value: settings.addressVisibility,
          items: addressVisibilityOptionsForRole(role),
          itemLabel: (value) => _addressLabel(l, value),
          onChanged: (value) {
            if (value == null) return;
            onChanged(settings.copyWith(addressVisibility: value));
          },
        ),
        if (_showNamedPickers(settings)) ...[
          const SizedBox(height: 16),
          Text(
            l.accountOrgNamedGrantsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ..._namedGrantSections(context, l),
        ],
      ],
    );
  }

  bool _showNamedPickers(MemberPrivacySettings value) {
    return value.cardVisibility == CardVisibility.named ||
        value.phoneVisibility == ContactVisibility.named ||
        value.emailVisibility == ContactVisibility.named ||
        value.addressVisibility == AddressVisibility.named;
  }

  List<Widget> _namedGrantSections(BuildContext context, AppLocalizations l) {
    final sections = <Widget>[];
    void addSection({
      required String title,
      required List<String> selected,
      required ValueChanged<List<String>> onUpdate,
      required Key key,
    }) {
      sections.add(
        _NamedGrantPicker(
          key: key,
          title: title,
          members: settings.availableMembers,
          selectedUserIds: selected,
          onChanged: onUpdate,
        ),
      );
      sections.add(const SizedBox(height: 12));
    }

    if (settings.cardVisibility == CardVisibility.named) {
      addSection(
        key: const Key('account_org_named_card'),
        title: l.accountOrgNamedCardLabel,
        selected: settings.grants.card,
        onUpdate: (ids) => onChanged(
          settings.copyWith(grants: settings.grants.copyWith(card: ids)),
        ),
      );
    }
    if (settings.phoneVisibility == ContactVisibility.named) {
      addSection(
        key: const Key('account_org_named_phone'),
        title: l.accountOrgNamedPhoneLabel,
        selected: settings.grants.phone,
        onUpdate: (ids) => onChanged(
          settings.copyWith(grants: settings.grants.copyWith(phone: ids)),
        ),
      );
    }
    if (settings.emailVisibility == ContactVisibility.named) {
      addSection(
        key: const Key('account_org_named_email'),
        title: l.accountOrgNamedEmailLabel,
        selected: settings.grants.email,
        onUpdate: (ids) => onChanged(
          settings.copyWith(grants: settings.grants.copyWith(email: ids)),
        ),
      );
    }
    if (settings.addressVisibility == AddressVisibility.named) {
      addSection(
        key: const Key('account_org_named_address'),
        title: l.accountOrgNamedAddressLabel,
        selected: settings.grants.address,
        onUpdate: (ids) => onChanged(
          settings.copyWith(grants: settings.grants.copyWith(address: ids)),
        ),
      );
    }
    return sections;
  }

  Widget _enumDropdown<T>({
    required Key key,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T value) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      key: key,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) =>
                DropdownMenuItem(value: item, child: Text(itemLabel(item))),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  String _cardLabel(AppLocalizations l, CardVisibility value) {
    return switch (value) {
      CardVisibility.all => l.accountOrgCardVisibilityAll,
      CardVisibility.admins => l.accountOrgCardVisibilityAdmins,
      CardVisibility.named => l.accountOrgCardVisibilityNamed,
    };
  }

  String _contactLabel(AppLocalizations l, ContactVisibility value) {
    return switch (value) {
      ContactVisibility.admins => l.accountOrgContactVisibilityAdmins,
      ContactVisibility.adminsAndFosterManagers =>
        l.accountOrgContactVisibilityAdminsAndFosterManagers,
      ContactVisibility.adminsOrNamed =>
        l.accountOrgContactVisibilityAdminsOrNamed,
      ContactVisibility.named => l.accountOrgContactVisibilityNamed,
    };
  }

  String _addressLabel(AppLocalizations l, AddressVisibility value) {
    return switch (value) {
      AddressVisibility.adminsOrNamed =>
        l.accountOrgAddressVisibilityAdminsOrNamed,
      AddressVisibility.admins => l.accountOrgAddressVisibilityAdmins,
      AddressVisibility.named => l.accountOrgAddressVisibilityNamed,
      AddressVisibility.hidden => l.accountOrgAddressVisibilityHidden,
    };
  }
}

class _NamedGrantPicker extends StatelessWidget {
  const _NamedGrantPicker({
    super.key,
    required this.title,
    required this.members,
    required this.selectedUserIds,
    required this.onChanged,
  });

  final String title;
  final List<MemberPrivacyMemberOption> members;
  final List<String> selectedUserIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Text(title, style: Theme.of(context).textTheme.bodyMedium);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: members.map((member) {
            final selected = selectedUserIds.contains(member.userId);
            return FilterChip(
              label: Text(
                member.displayName.isEmpty ? member.userId : member.displayName,
              ),
              selected: selected,
              onSelected: (next) {
                final ids = List<String>.from(selectedUserIds);
                if (next) {
                  if (!ids.contains(member.userId)) ids.add(member.userId);
                } else {
                  ids.remove(member.userId);
                }
                onChanged(ids);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
