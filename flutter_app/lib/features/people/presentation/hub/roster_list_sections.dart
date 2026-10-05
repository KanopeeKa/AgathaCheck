import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/contact_summary.dart';
import '../../domain/entities/household.dart';
import '../../domain/entities/household_invite.dart';
import '../../domain/entities/roster.dart';
import '../../domain/services/roster_sections.dart';
import '../widgets/person_card.dart';
import 'roster_hub_query.dart';

class RosterSectionBlock extends StatelessWidget {
  const RosterSectionBlock({
    super.key,
    required this.section,
    required this.hubQuery,
    required this.onSelect,
  });

  final RosterSection section;
  final RosterHubQuery hubQuery;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = _sectionTitle(l, section);
    if (section.kind == RosterSectionKind.inactive) {
      return InactiveRosterSection(
        title: title,
        entries: section.entries,
        hubQuery: hubQuery,
        onSelect: onSelect,
      );
    }
    if (section.kind == RosterSectionKind.household &&
        section.household != null) {
      return HouseholdRosterSection(
        household: section.household!,
        contacts: section.entries,
        hubQuery: hubQuery,
        onSelect: onSelect,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RosterSectionHeading(title: title),
        for (final contact in section.entries)
          PersonCard(
            contact: contact,
            highlightQuery: hubQuery.searchQuery,
            onTap: () => onSelect(contact.id),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _sectionTitle(AppLocalizations l, RosterSection section) {
    return switch (section.kind) {
      RosterSectionKind.trustedCarers => l.peopleTrustedCarersSection,
      RosterSectionKind.petProfessionals => l.peopleProfessionalsSection,
      RosterSectionKind.pendingInvites => l.peoplePendingInvitesSection,
      RosterSectionKind.inactive => l.peopleInactiveSection(
        section.entries.length,
      ),
      RosterSectionKind.household => section.titleKey,
    };
  }
}

class HouseholdRosterSection extends StatelessWidget {
  const HouseholdRosterSection({
    super.key,
    required this.household,
    required this.contacts,
    required this.hubQuery,
    required this.onSelect,
  });

  final Household household;
  final List<ContactSummary> contacts;
  final RosterHubQuery hubQuery;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final contactByUser = {
      for (final c in contacts)
        if (c.linkedUserId != null) c.linkedUserId!: c,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RosterSectionHeading(title: household.name.toUpperCase()),
        for (final member in household.members)
          HouseholdMemberRow(
            member: member,
            contact: contactByUser[member.userId],
            hubQuery: hubQuery,
            onSelect: onSelect,
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class HouseholdMemberRow extends StatelessWidget {
  const HouseholdMemberRow({
    super.key,
    required this.member,
    required this.contact,
    required this.hubQuery,
    required this.onSelect,
  });

  final HouseholdMember member;
  final ContactSummary? contact;
  final RosterHubQuery hubQuery;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (contact != null) {
      final tierLine = member.isOrganiser
          ? l.householdOrganiserLabel
          : l.householdCanLogCareLabel;
      return PersonCard(
        contact: contact!,
        highlightQuery: hubQuery.searchQuery,
        roleLine: member.isYou ? '$tierLine · ${l.peopleMemberYou}' : tierLine,
        onTap: () => onSelect(contact!.id),
      );
    }
    return ListTile(
      minVerticalPadding: 12,
      title: Text(member.displayName),
      subtitle: Text(
        member.isOrganiser
            ? l.householdOrganiserLabel
            : l.householdCanLogCareLabel,
      ),
      onTap: () => onSelect(member.userId),
    );
  }
}

class InactiveRosterSection extends StatefulWidget {
  const InactiveRosterSection({
    super.key,
    required this.title,
    required this.entries,
    required this.hubQuery,
    required this.onSelect,
  });

  final String title;
  final List<ContactSummary> entries;
  final RosterHubQuery hubQuery;
  final ValueChanged<String> onSelect;

  @override
  State<InactiveRosterSection> createState() => _InactiveRosterSectionState();
}

class _InactiveRosterSectionState extends State<InactiveRosterSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(_expanded ? Icons.expand_more : Icons.chevron_right),
                const SizedBox(width: 4),
                Expanded(child: Text(widget.title)),
              ],
            ),
          ),
        ),
        if (_expanded)
          for (final contact in widget.entries)
            PersonCard(
              contact: contact,
              highlightQuery: widget.hubQuery.searchQuery,
              onTap: () => widget.onSelect(contact.id),
            ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class PendingInvitesRosterSection extends StatelessWidget {
  const PendingInvitesRosterSection({super.key, required this.invites});

  final List<HouseholdInvite> invites;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RosterSectionHeading(title: l.peoplePendingInvitesSection),
        for (final invite in invites)
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(l.peoplePendingInviteLine(invite.email)),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class RosterSectionHeading extends StatelessWidget {
  const RosterSectionHeading({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
