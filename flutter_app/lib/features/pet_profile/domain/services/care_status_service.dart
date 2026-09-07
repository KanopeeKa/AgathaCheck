import '../../../health_tracking/domain/entities/health_entry.dart';
import '../entities/care_status.dart';

/// Deterministic pet-level Care Status from tracked health entries.
class CareStatusService {
  const CareStatusService();

  CareStatusSummary evaluate({
    required String petId,
    required List<HealthEntry> entries,
    required DateTime now,
  }) {
    final petEntries = entries.where((e) => e.petId == petId).toList();
    final today = DateTime(now.year, now.month, now.day);

    String? primaryId;
    final contributing = <String>[];
    var worst = CareStatus.allSet;

    for (final entry in petEntries) {
      if (!_affectsStatus(entry)) continue;
      final dueDay = DateTime(
        entry.nextDueDate!.year,
        entry.nextDueDate!.month,
        entry.nextDueDate!.day,
      );
      if (dueDay.isBefore(today)) {
        worst = CareStatus.timeToFollowUp;
        contributing.add(entry.id);
        primaryId ??= entry.id;
        continue;
      }
      if (dueDay == today ||
          dueDay.difference(today).inDays <= entry.remindDaysBefore) {
        if (worst == CareStatus.allSet) {
          worst = CareStatus.worthACheck;
        }
        if (worst != CareStatus.timeToFollowUp) {
          contributing.add(entry.id);
          primaryId ??= entry.id;
        }
      }
    }

    return CareStatusSummary(
      status: worst,
      primaryCareEntryId: primaryId,
      contributingEntryIds: contributing,
      evaluatedAt: now,
    );
  }

  bool _affectsStatus(HealthEntry entry) {
    if (entry.status == 'completed') return false;
    if (entry.isCompleted) return false;
    if (entry.nextDueDate == null) return false;
    return true;
  }
}

/// Maps legacy four-bucket urgency to three-state Care Status.
CareStatus careStatusFromLegacyUrgency({
  required bool hasOverdue,
  required bool hasDueToday,
  required bool hasUpcoming,
}) {
  if (hasOverdue) return CareStatus.timeToFollowUp;
  if (hasDueToday || hasUpcoming) return CareStatus.worthACheck;
  return CareStatus.allSet;
}
