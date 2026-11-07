import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

/// Care-item documents on the detail view — own module above History (D-CIE-041).
class CareItemDocumentsSection extends ConsumerWidget {
  const CareItemDocumentsSection({
    super.key,
    required this.entryId,
    required this.muted,
  });

  final String entryId;
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(healthEntryPhotosProvider(entryId));

    return photosAsync.when(
      loading: () => _DocumentsModule(entryId: entryId, muted: muted),
      error: (_, __) => _DocumentsModule(entryId: entryId, muted: muted),
      data: (photos) {
        if (photos.isEmpty) {
          return const SizedBox.shrink();
        }
        return _DocumentsModule(entryId: entryId, muted: muted);
      },
    );
  }
}

class _DocumentsModule extends StatelessWidget {
  const _DocumentsModule({required this.entryId, required this.muted});

  final String entryId;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return CareItemModule(
      key: const Key('care_item_documents_module'),
      semanticLabel: l.careItemDocumentsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CareItemSectionHeader(
            title: l.careItemDocumentsTitle,
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 12),
          PetEventDocumentsStrip(
            entryId: entryId,
            muted: muted,
            showHeading: false,
          ),
        ],
      ),
    );
  }
}
