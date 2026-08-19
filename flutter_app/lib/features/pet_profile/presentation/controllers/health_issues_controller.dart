import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/domain/entities/health_issue.dart';
import '../../../health_tracking/domain/entities/health_issue_document.dart';
import '../../../health_tracking/presentation/controllers/health_entry_form_constants.dart';
import '../../../health_tracking/presentation/utils/health_document_picker.dart';
import '../../../health_tracking/presentation/providers/health_issue_providers.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';

class HealthIssuesController {
  HealthIssuesController(this.ref);

  final WidgetRef ref;

  bool isResolved(HealthIssue issue) => issue.endDate != null;

  String displayDate(HealthIssue issue, DateFormat dateFormat) {
    if (issue.endDate != null) {
      return dateFormat.format(issue.endDate!);
    }
    if (issue.startDate != null) {
      return dateFormat.format(issue.startDate!);
    }
    return '';
  }

  Future<void> showAddIssueDialog(BuildContext context, String petId) async {
    final l = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addHealthIssue),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: l.issueTitle),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.issueTitleRequired
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descController,
                decoration: InputDecoration(labelText: l.issueDescription),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.issueDescriptionRequired
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final issue = HealthIssue(
        id: const Uuid().v4(),
        petId: petId,
        title: titleController.text.trim(),
        description: descController.text.trim(),
        startDate: calendarDateOnly(DateTime.now()),
      );
      await ref.read(healthIssueNotifierProvider(petId).notifier).create(issue);
    }

    titleController.dispose();
    descController.dispose();
  }

  Future<bool> confirmDeleteIssue(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteIssue),
        content: Text(l.deleteIssueConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> deleteIssue(String petId, String issueId) async {
    await ref
        .read(healthIssueNotifierProvider(petId).notifier)
        .deleteIssue(issueId);
  }

  Future<void> saveIssue(String petId, HealthIssue issue) async {
    await ref
        .read(healthIssueNotifierProvider(petId).notifier)
        .updateIssue(issue);
  }

  HealthIssue reopenIssue(HealthIssue issue, AppLocalizations l) {
    final closedDate = issue.endDate;
    final reopenedDate = calendarDateOnly(DateTime.now());
    final closedLabel = closedDate != null
        ? DateFormat.yMMMd().format(closedDate)
        : l.notSet;
    final reopenedLabel = DateFormat.yMMMd().format(reopenedDate);
    final note = l.issueReopenedNote(closedLabel, reopenedLabel);
    final description = issue.description.trim().isEmpty
        ? note
        : '${issue.description.trim()}\n$note';
    return issue.copyWith(description: description, clearEndDate: true);
  }

  String? validateDocumentBytes(String filename, int byteLength) {
    final ext = filename.split('.').last.toLowerCase();
    if (!healthDocumentAllowedExtensions.contains(ext)) {
      return 'unsupported';
    }
    if (byteLength > healthDocumentMaxBytes) {
      return 'tooLarge';
    }
    return null;
  }

  Future<void> pickAndUploadDocument(
    BuildContext context,
    String petId,
    String issueId, {
    required int currentCount,
  }) async {
    final l = AppLocalizations.of(context)!;
    if (currentCount >= healthEntryMaxPhotos) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.maxPhotosReached)));
      return;
    }

    try {
      final file = await pickSingleHealthDocument();
      if (file == null) return;
      if (!context.mounted) return;

      final data = await file.readAsBytes();
      if (data.isEmpty) return;
      final validation = validateDocumentBytes(file.name, data.length);
      if (validation == 'unsupported') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.unsupportedDocumentFormat)));
        return;
      }
      if (validation == 'tooLarge') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.documentTooLarge)));
        return;
      }

      final mimeType = _mimeForFilename(file.name);
      await ref
          .read(healthIssueNotifierProvider(petId).notifier)
          .uploadDocument(issueId, data, file.name, mimeType);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.failedToAddPhoto('$e'))));
      }
    }
  }

  Future<void> deleteDocument(
    BuildContext context,
    String petId,
    String issueId,
    HealthIssueDocument document,
  ) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deletePhotoTitle),
        content: Text(l.deletePhotoConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(healthIssueNotifierProvider(petId).notifier)
          .deleteDocument(issueId, document.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.failedToDeletePhoto('$e'))));
      }
    }
  }

  String documentUrl(String path) {
    final baseUrl = ref.read(apiBaseUrlProvider);
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$normalizedBase/$normalizedPath';
  }

  bool isPdfDocument(String path) =>
      path.toLowerCase().split('?').first.endsWith('.pdf');

  Future<void> showLinkEventPicker(
    BuildContext context,
    String petId,
    HealthIssue issue,
  ) async {
    final l = AppLocalizations.of(context)!;
    final entries = await ref.read(petHealthEntriesProvider(petId).future);
    final linked = issue.eventIds.toSet();
    final available = entries.where((e) => !linked.contains(e.id)).toList();

    if (!context.mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.noLinkedEvents)));
      return;
    }

    final selected = await showModalBottomSheet<HealthEntry>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.linkEvent,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final entry = available[index];
                  return ListTile(
                    title: Text(entry.name),
                    subtitle: Text(entry.type.name),
                    onTap: () => Navigator.of(ctx).pop(entry),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      await ref
          .read(healthIssueNotifierProvider(petId).notifier)
          .linkEvent(issue.id, selected.id);
    }
  }

  String _mimeForFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
