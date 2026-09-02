import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/health_entry.dart';
import '../../../domain/entities/recurrence_anchor.dart';
import '../../providers/health_providers.dart';

/// Load, submit, and delete actions for [OtherEventFormScreen].
class OtherEventFormActions {
  OtherEventFormActions({
    required this.ref,
    required this.context,
    required this.petId,
    required this.entryId,
    required this.isMounted,
    required this.uploadPendingPhotos,
  });

  final WidgetRef ref;
  final BuildContext context;
  final String petId;
  final String? entryId;
  final bool Function() isMounted;
  final Future<void> Function(String entryId) uploadPendingPhotos;

  Future<void> loadEntry({
    required HealthEntryType type,
    required void Function({
      required String name,
      required String notes,
      required HealthEntryType type,
      required HealthFrequency frequency,
      required int frequencyInterval,
      required DateTime startDate,
      required DateTime? dueDate,
      required DateTime? completedOn,
      required RecurrenceAnchor recurrenceAnchor,
      required DateTime? repeatEndDate,
      required int remindDaysBefore,
    })
    applyLoaded,
    required void Function(bool) setLoading,
    required List<HealthEntryType> allowedTypes,
  }) async {
    if (entryId == null) return;
    setLoading(true);
    try {
      final entry = await ref.read(healthRepositoryProvider).getEntry(entryId!);
      if (entry != null && isMounted()) {
        if (!allowedTypes.contains(entry.type)) {
          throw StateError('Entry is not an other event type');
        }
        applyLoaded(
          name: entry.name,
          notes: entry.notes,
          type: entry.type,
          frequency: entry.frequency == HealthFrequency.custom
              ? HealthFrequency.daily
              : entry.frequency,
          frequencyInterval: entry.frequency == HealthFrequency.custom
              ? (entry.frequencyDays ?? 1)
              : entry.frequencyInterval,
          startDate: entry.startDate,
          dueDate: entry.nextDueDate,
          completedOn: entry.completedOn,
          recurrenceAnchor: entry.recurrenceAnchor,
          repeatEndDate: entry.repeatEndDate,
          remindDaysBefore: entry.remindDaysBefore,
        );
      }
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToLoadEntry('$e'),
            ),
          ),
        );
      }
    } finally {
      if (isMounted()) setLoading(false);
    }
  }

  Future<void> submit({
    required bool isEdit,
    required GlobalKey<FormState> formKey,
    required DateTime? dueDate,
    required DateTime? completedOn,
    required HealthFrequency frequency,
    required int frequencyInterval,
    required DateTime startDate,
    required DateTime? repeatEndDate,
    required RecurrenceAnchor recurrenceAnchor,
    required int remindDaysBefore,
    required HealthEntryType type,
    required String name,
    required String notes,
    required List<XFile> pendingPhotos,
    required void Function(bool) setLoading,
    required void Function(DateTime?) setCompletedOn,
  }) async {
    if (dueDate == null && completedOn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.dueOrCompletedRequired),
        ),
      );
      return;
    }
    if (!formKey.currentState!.validate()) return;

    var markCompleted = false;
    final today = DateTime.now();
    final dueOnly = dueDate != null ? calendarDateOnly(dueDate) : null;
    final todayOnly = calendarDateOnly(today);
    var effectiveCompleted = completedOn;

    if (!isEdit &&
        frequency == HealthFrequency.once &&
        completedOn == null &&
        dueOnly != null &&
        !dueOnly.isAfter(todayOnly)) {
      final l = AppLocalizations.of(context)!;
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.markAsCompletedTitle),
          content: Text(
            dueOnly.isBefore(todayOnly)
                ? l.markCompletedPast
                : l.markCompletedToday,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.keepActive),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.markCompletedAction),
            ),
          ],
        ),
      );
      if (result == null) return;
      markCompleted = result;
      if (markCompleted) {
        effectiveCompleted = dueOnly;
        setCompletedOn(dueOnly);
      }
    }

    setLoading(true);
    try {
      final notifier = ref.read(healthEntriesNotifierProvider.notifier);
      final effectiveRepeatEndDate = frequency == HealthFrequency.once
          ? null
          : repeatEndDate;
      final effectiveStart = dueDate ?? effectiveCompleted ?? startDate;
      final effectiveDue =
          frequency == HealthFrequency.once && effectiveCompleted != null
          ? null
          : dueDate;

      if (isEdit) {
        final entry = HealthEntry(
          id: entryId ?? '',
          petId: petId,
          name: name.trim(),
          type: type,
          frequency: frequency,
          frequencyInterval: frequency == HealthFrequency.once
              ? 1
              : frequencyInterval,
          repeatEndDate: effectiveRepeatEndDate,
          startDate: effectiveStart,
          nextDueDate: effectiveDue,
          completedOn: effectiveCompleted,
          recurrenceAnchor: recurrenceAnchor,
          notes: notes.trim(),
          remindDaysBefore: remindDaysBefore,
        );
        await notifier.updateEntry(entry);
      } else {
        final createUseCase = ref.read(createHealthEntryProvider);
        final entry = HealthEntry(
          id: '',
          petId: petId,
          name: name.trim(),
          type: type,
          frequency: frequency,
          frequencyInterval: frequency == HealthFrequency.once
              ? 1
              : frequencyInterval,
          repeatEndDate: effectiveRepeatEndDate,
          startDate: effectiveStart,
          nextDueDate: markCompleted ? null : (dueDate ?? effectiveStart),
          completedOn: markCompleted
              ? (effectiveCompleted ?? effectiveStart)
              : effectiveCompleted,
          recurrenceAnchor: recurrenceAnchor,
          notes: notes.trim(),
          remindDaysBefore: remindDaysBefore,
        );
        final created = await createUseCase.call(entry);
        if (pendingPhotos.isNotEmpty) {
          await uploadPendingPhotos(created.id);
        }
        await notifier.refresh();
      }

      if (isMounted()) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? l.entryUpdated : l.entryCreated)),
        );
        goToPetDetail(context, petId);
      }
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorWithMessage('$e')),
          ),
        );
      }
    } finally {
      if (isMounted()) setLoading(false);
    }
  }

  Future<void> confirmDelete({
    required String entryName,
    required void Function() onDeleted,
  }) async {
    if (entryId == null) return;
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteEntry),
        content: Text(l.deleteEntryNamedConfirm(entryName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(healthEntriesNotifierProvider.notifier).delete(entryId!);
      if (isMounted()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.entryDeleted)));
        onDeleted();
      }
    } catch (e) {
      if (isMounted()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.failedToDelete('$e'))));
      }
    }
  }
}
