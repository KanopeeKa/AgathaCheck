import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../care_taxonomy/domain/care_planning_mode.dart';
import '../../../../care_taxonomy/domain/care_setting.dart';
import '../../../domain/entities/health_entry.dart';
import '../../../domain/entities/health_issue.dart';
import '../../providers/health_issue_providers.dart';
import '../../providers/health_providers.dart';
import 'health_issue_linkage_prompt.dart';
import 'health_issue_prompt_eligibility.dart';

/// Orchestrates vet health-issue prompts and linkage after save/completion.
class HealthIssueLinkageFlow {
  const HealthIssueLinkageFlow._();

  static Future<void> maybePromptAfterUnplannedVetSave(
    BuildContext context,
    WidgetRef ref, {
    required String petId,
    required String entryId,
    required CareSetting careSetting,
    required CarePlanningMode carePlanning,
    String? healthIssueId,
  }) async {
    if (!shouldPromptUnplannedVetSave(
      careSetting: careSetting,
      carePlanning: carePlanning,
      healthIssueId: healthIssueId,
    )) {
      return;
    }

    await _runPrompt(
      context,
      ref,
      petId: petId,
      entryId: entryId,
      prompt: showUnplannedVetHealthIssuePrompt,
    );
  }

  static Future<void> maybePromptAfterPlannedVetCompletion(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    if (!shouldPromptPlannedVetCompletion(
      careSetting: entry.careSetting ?? CareSetting.other,
      carePlanning: entry.carePlanning ?? CarePlanningMode.planned,
      healthIssueId: entry.healthIssueId,
    )) {
      return;
    }

    await _runPrompt(
      context,
      ref,
      petId: entry.petId,
      entryId: entry.id,
      prompt: showPlannedVetCompletionHealthIssuePrompt,
      onPlanNextVisit: () {
        if (!context.mounted) return;
        context.push('/pet/${entry.petId}/health/add');
      },
    );
  }

  static Future<void> _runPrompt(
    BuildContext context,
    WidgetRef ref, {
    required String petId,
    required String entryId,
    required Future<VetHealthIssuePromptChoice?> Function(BuildContext) prompt,
    VoidCallback? onPlanNextVisit,
  }) async {
    final choice = await prompt(context);
    if (!context.mounted || choice == null) return;

    switch (choice) {
      case VetHealthIssuePromptChoice.dismiss:
        return;
      case VetHealthIssuePromptChoice.planNextVisit:
        onPlanNextVisit?.call();
        return;
      case VetHealthIssuePromptChoice.linkExisting:
        await _linkExistingIssue(context, ref, petId: petId, entryId: entryId);
      case VetHealthIssuePromptChoice.addNew:
        await _addNewIssue(context, ref, petId: petId, entryId: entryId);
    }
  }

  static Future<void> _linkExistingIssue(
    BuildContext context,
    WidgetRef ref, {
    required String petId,
    required String entryId,
  }) async {
    final l = AppLocalizations.of(context)!;
    final issues = await ref.read(petHealthIssuesProvider(petId).future);
    if (!context.mounted) return;

    if (issues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.createHealthIssuesHint)),
      );
      return;
    }

    final picked = await showHealthIssuePickerSheet(context, issues);
    if (!context.mounted || picked == null) return;

    try {
      await ref
          .read(healthIssueNotifierProvider(petId).notifier)
          .linkEvent(picked.id, entryId);
      ref.invalidate(petHealthEntriesProvider(petId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.healthIssueLinked)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.healthIssueLinkFailed)),
      );
    }
  }

  static Future<void> _addNewIssue(
    BuildContext context,
    WidgetRef ref, {
    required String petId,
    required String entryId,
  }) async {
    final l = AppLocalizations.of(context)!;
    final draft = await showAddHealthIssueFromVetPrompt(context);
    if (!context.mounted || draft == null) return;

    try {
      final issue = HealthIssue(
        id: const Uuid().v4(),
        petId: petId,
        title: draft.title,
        description: draft.description,
        startDate: calendarDateOnly(DateTime.now()),
      );
      await ref.read(healthIssueNotifierProvider(petId).notifier).create(issue);
      await ref
          .read(healthIssueNotifierProvider(petId).notifier)
          .linkEvent(issue.id, entryId);
      ref.invalidate(petHealthEntriesProvider(petId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.healthIssueLinked)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.healthIssueLinkFailed)),
      );
    }
  }
}
