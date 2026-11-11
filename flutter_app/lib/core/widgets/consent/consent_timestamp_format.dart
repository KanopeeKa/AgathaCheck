import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale-aware local-time label for a stored consent ISO-8601 timestamp.
String formatConsentTimestamp(BuildContext context, String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).add_Hm().format(dt);
  } catch (_) {
    return iso;
  }
}
