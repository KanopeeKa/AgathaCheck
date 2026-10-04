import 'care_item_schedule.dart';
import 'care_occurrence.dart';
import 'completion_requirements.dart';
import 'leading_occurrence.dart';
import 'occurrence_status.dart';
import 'stack_rule.dart';

/// What Done does (D-CIE-030, §18.6.1). One rule for every surface: a row's
/// tick, the Care Item view, an occurrence line and the occurrence screen.
sealed class DoneDecision {
  const DoneDecision();
}

/// DN-1 / DN-1c / DN-8: open the Care Item view; nothing is saved.
class DoneOpensCareItem extends DoneDecision {
  const DoneOpensCareItem();
}

/// DN-2: open the occurrence screen with the required field focused.
class DoneOpensOccurrence extends DoneDecision {
  const DoneOpensOccurrence(this.occurrence, this.requirement);

  final OpenOccurrence occurrence;
  final CompletionRequirement requirement;
}

/// DN-3: After it's done, overdue — ask "When was this done?" (Today first).
class DoneAsksDate extends DoneDecision {
  const DoneAsksDate(this.occurrence);

  final OpenOccurrence occurrence;
}

/// DN-4: more than half an interval early — confirm first.
class DoneConfirmsEarly extends DoneDecision {
  const DoneConfirmsEarly(this.occurrence);

  final OpenOccurrence occurrence;
}

/// DN-5: complete today with one request.
class DoneCompletesToday extends DoneDecision {
  const DoneCompletesToday(this.occurrence, {this.offerChangeDate = false});

  final OpenOccurrence occurrence;

  /// DN-7: a Fixed-schedule overdue / not recorded completion offers Change
  /// date in the confirmation.
  final bool offerChangeDate;
}

/// Decide what Done does for [schedule]'s [occurrence] (the leading one when
/// null). [onOccurrenceScreen] skips DN-2 and DN-3 (the screen shows the
/// field and the date inline).
DoneDecision decideDone(
  CareItemSchedule schedule, {
  OpenOccurrence? occurrence,
  CareAsOf? asOf,
  bool onOccurrenceScreen = false,
}) {
  final now = asOf ?? schedule.asOf;
  if (!schedule.isActive) return const DoneOpensCareItem();
  final target = occurrence ?? leadingOccurrence(schedule, asOf: now);
  if (target == null) return const DoneOpensCareItem();
  if (occurrence == null && isStack(schedule, asOf: now)) {
    return const DoneOpensCareItem();
  }
  if (hasEarlierOpenDate(schedule, target)) return const DoneOpensCareItem();

  final requirements = completionRequirementsFor(schedule.careFamily);
  if (requirements.isNotEmpty && !onOccurrenceScreen) {
    return DoneOpensOccurrence(target, requirements.first);
  }

  final status = liveStatus(target, now);
  if (!schedule.isFixedSchedule && isPastDue(status) && !onOccurrenceScreen) {
    return DoneAsksDate(target);
  }

  final interval = schedule.intervalDays;
  if (status == CareOccurrenceStatus.comingUp && interval != null) {
    final daysEarly = target.date.difference(now.date).inDays;
    if (daysEarly * 2 > interval) return DoneConfirmsEarly(target);
  }

  return DoneCompletesToday(
    target,
    offerChangeDate: schedule.isFixedSchedule && isPastDue(status),
  );
}
