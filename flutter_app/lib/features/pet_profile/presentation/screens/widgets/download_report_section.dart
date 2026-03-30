import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet.dart';
import '../../controllers/download_report_controller.dart';

class DownloadReportSection extends ConsumerWidget {
  const DownloadReportSection({required this.pet, super.key});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = DownloadReportController(ref);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.icon(
        key: const Key('download_report_button'),
        onPressed: () {
          // Delegate to controller for report logic
          controller.onDownloadReport(context, pet);
        },
        icon: const Icon(Icons.description),
        label: Text(l.downloadPetReport),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
