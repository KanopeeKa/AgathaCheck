import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/presentation/providers/health_issue_providers.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../../core/branding/logo_assets.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../organization/domain/entities/family_event.dart';
import '../../../organization/domain/entities/foster_placement.dart';
import '../../../organization/presentation/providers/foster_placements_providers.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../data/services/pdf_saver.dart' as pdf_saver;
import '../../data/services/pet_report_service.dart';
import '../../domain/entities/pet.dart';

class DownloadReportController {
  final WidgetRef ref;
  DownloadReportController(this.ref);

  Future<void> onDownloadReport(BuildContext context, Pet pet) async {
    final l = AppLocalizations.of(context)!;

    var sections = const ReportSections();
    final result = await showDialog<ReportSections>(
      context: context,
      builder: (ctx) => _ReportSectionsDialog(
        sections: sections,
        l: l,
        showFosterHistory: pet.organizationId != null,
      ),
    );

    if (result == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final vets = ref.read(vetListProvider).valueOrNull ?? [];
      final assignedVet = (pet.vetId != null && pet.vetId!.isNotEmpty)
          ? vets.where((v) => v.id == pet.vetId).firstOrNull
          : null;

      final weightEntries = await ref.read(
        weightEntriesProvider(pet.id).future,
      );
      final healthEntries = await ref.read(
        petHealthEntriesProvider(pet.id).future,
      );
      final healthIssues = await ref.read(
        healthIssueNotifierProvider(pet.id).future,
      );
      final notifications = ref.read(notificationsProvider).valueOrNull ?? [];
      final petNotifications = notifications
          .where((n) => n.petId == pet.id)
          .toList();
      final accessList = await ref.read(petAccessProvider(pet.id).future);
      final unit = ref.read(weightUnitProvider(pet.id));

      List<FamilyEvent> familyEventsList = [];
      List<FosterPlacement> fosterPlacements = const [];
      if (pet.organizationId != null) {
        try {
          familyEventsList = await ref.read(
            familyEventsProvider(pet.id).future,
          );
        } catch (_) {}
        if (result.fosterHistory) {
          try {
            fosterPlacements = await ref.read(
              petFosterHistoryProvider((pet.organizationId!, pet.id)).future,
            );
          } catch (_) {}
        }
      }

      final Map<String, List<Map<String, dynamic>>> healthHistories = {};
      if (result.includeFullLog) {
        for (final entry in healthEntries) {
          try {
            final history = await ref.read(
              entryHistoryProvider(entry.id).future,
            );
            healthHistories[entry.id] = history
                .map(
                  (h) => {
                    'taken_at': h.takenAt.toIso8601String(),
                    'notes': h.notes,
                  },
                )
                .toList();
          } catch (_) {}
        }
      }

      Uint8List? logoBytes;
      try {
        final experience = AppExperience.guardian;
        final data = await rootBundle.load(LogoAssets.pngFor(experience));
        logoBytes = data.buffer.asUint8List();
      } catch (_) {}

      final service = PetReportService();
      final pdfBytes = await service.generateReport(
        pet: pet,
        sections: result,
        l: l,
        vet: assignedVet,
        weightEntries: weightEntries,
        healthEntries: healthEntries,
        healthIssues: healthIssues,
        familyEvents: familyEventsList,
        fosterPlacements: fosterPlacements,
        petNotifications: petNotifications,
        accessList: accessList,
        healthHistories: healthHistories,
        weightUnit: weightUnitLabel(unit),
        logoBytes: logoBytes,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final filename =
          '${pet.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_report.pdf';
      await pdf_saver.savePdf(pdfBytes, filename);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.reportGenerated)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.reportFailed(e.toString()))));
      }
    }
  }
}

class _ReportSectionsDialog extends StatefulWidget {
  const _ReportSectionsDialog({
    required this.sections,
    required this.l,
    this.showFosterHistory = false,
  });

  final ReportSections sections;
  final AppLocalizations l;
  final bool showFosterHistory;

  @override
  State<_ReportSectionsDialog> createState() => _ReportSectionsDialogState();
}

class _ReportSectionsDialogState extends State<_ReportSectionsDialog> {
  late bool petProfile;
  late bool weightTracking;
  late bool healthEvents;
  late bool healthIssues;
  late bool familyEvents;
  late bool fosterHistory;
  late bool notifications;
  late bool sharing;
  late bool includeFullLog;

  @override
  void initState() {
    super.initState();
    petProfile = widget.sections.petProfile;
    weightTracking = widget.sections.weightTracking;
    healthEvents = widget.sections.healthEvents;
    healthIssues = widget.sections.healthIssues;
    familyEvents = widget.sections.familyEvents;
    fosterHistory = widget.sections.fosterHistory;
    notifications = widget.sections.notifications;
    sharing = widget.sections.sharing;
    includeFullLog = widget.sections.includeFullLog;
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return AlertDialog(
      title: Text(l.downloadPetReport),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: Text(l.petProfile),
              value: petProfile,
              onChanged: (v) => setState(() => petProfile = v ?? true),
            ),
            CheckboxListTile(
              title: Text(l.weightTracking),
              value: weightTracking,
              onChanged: (v) => setState(() => weightTracking = v ?? false),
            ),
            CheckboxListTile(
              title: Text(l.healthEvents),
              value: healthEvents,
              onChanged: (v) => setState(() => healthEvents = v ?? false),
            ),
            if (healthEvents)
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: CheckboxListTile(
                  title: Text(l.includeFullLog),
                  value: includeFullLog,
                  onChanged: (v) => setState(() => includeFullLog = v ?? false),
                ),
              ),
            CheckboxListTile(
              title: Text(l.healthIssues),
              value: healthIssues,
              onChanged: (v) => setState(() => healthIssues = v ?? false),
            ),
            CheckboxListTile(
              title: Text(l.familyEvents),
              value: familyEvents,
              onChanged: (v) => setState(() => familyEvents = v ?? false),
            ),
            if (widget.showFosterHistory)
              CheckboxListTile(
                title: Text(l.fosterHistory),
                value: fosterHistory,
                onChanged: (v) => setState(() => fosterHistory = v ?? false),
              ),
            CheckboxListTile(
              title: Text(l.notifications),
              value: notifications,
              onChanged: (v) => setState(() => notifications = v ?? false),
            ),
            CheckboxListTile(
              title: Text(l.sharing),
              value: sharing,
              onChanged: (v) => setState(() => sharing = v ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              ReportSections(
                petProfile: petProfile,
                weightTracking: weightTracking,
                healthEvents: healthEvents,
                healthIssues: healthIssues,
                familyEvents: familyEvents,
                fosterHistory: fosterHistory,
                notifications: notifications,
                sharing: sharing,
                includeFullLog: includeFullLog,
              ),
            );
          },
          child: Text(l.downloadPetReport),
        ),
      ],
    );
  }
}
