import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/contact_detail.dart';
import '../../../domain/entities/contact_summary.dart';
import '../../../domain/enums/contact_kind.dart';
import '../../labels/people_labels.dart';
import '../widgets/person_detail_contact_rows.dart';

class PersonDetailOverviewTab extends StatelessWidget {
  const PersonDetailOverviewTab({
    super.key,
    required this.detail,
    this.summary,
  });

  final ContactDetail detail;
  final ContactSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final absence = summary?.nextAbsence;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PersonDetailContactRows(
          phone: detail.phone,
          email: detail.email,
          address: detail.address,
          website: detail.website,
        ),
        if (absence != null) ...[
          const SizedBox(height: 20),
          Text(
            l.peopleDetailNextUpTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l.peopleCardLookingAfter(absence.startsOn, absence.endsOn),
              ),
            ),
          ),
        ],
        if (detail.kind == ContactKind.organisation && detail.staff.isNotEmpty)
          ...[
            const SizedBox(height: 20),
            Text(
              l.peopleDetailStaffAt(detail.name),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final member in detail.staff)
              ListTile(
                title: Text(member.name),
                subtitle: Text(contactRolesLine(l, member.roles)),
              ),
          ],
        if (_hasNotesPreview) ...[
          const SizedBox(height: 20),
          Text(
            l.peopleDetailNotesPreviewTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (detail.privateNote.trim().isNotEmpty) ...[
            Text(l.peoplePrivateNoteLabel, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              detail.privateNote,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if ((detail.householdNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l.peopleDetailHouseholdNoteLabel,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              detail.householdNote!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ],
    );
  }

  bool get _hasNotesPreview {
    return detail.privateNote.trim().isNotEmpty ||
        (detail.householdNote ?? '').trim().isNotEmpty;
  }
}
