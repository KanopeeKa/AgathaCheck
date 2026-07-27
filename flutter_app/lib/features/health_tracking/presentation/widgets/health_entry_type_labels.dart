import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';

/// Localized labels for [HealthEntryType] values in forms and lists.
String healthEntryTypeLabel(AppLocalizations l, HealthEntryType type) {
  switch (type) {
    case HealthEntryType.medication:
      return l.medication;
    case HealthEntryType.preventive:
      return l.preventive;
    case HealthEntryType.vetVisit:
      return l.vetVisit;
    case HealthEntryType.other:
      return l.other;
  }
}
