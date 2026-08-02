import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import 'pet_timeline_labels.dart';

/// Legacy inline timeline section — navigation to [PetTimelineScreen] preferred.
class PetTimelineSection extends ConsumerWidget {
  const PetTimelineSection({
    super.key,
    required this.petId,
    required this.petName,
  });

  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      key: const Key('pet_timeline_section'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.petTimelineTitle),
        subtitle: Text(petTimelineJoinedLabel(l)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/pet/$petId/timeline'),
      ),
    );
  }
}
