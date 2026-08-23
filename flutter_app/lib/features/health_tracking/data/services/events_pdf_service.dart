import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import '../../../../core/theme/pdf_report_tokens.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/health_entry.dart';

class EventsPdfService {
  static const _checkboxSize = 14.0;

  Future<Uint8List> generate({
    required List<MapEntry<String?, List<HealthEntry>>> groups,
    required Map<String, Pet> petMap,
    required String filterLabel,
    required String groupLabel,
    required AppLocalizations l,
  }) async {
    final pdf = pw.Document(
      title: '${l.events} - $filterLabel',
      author: 'AgathaTrack',
    );

    final dateFormat = DateFormat('MMM d, yyyy');
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) =>
            _buildHeader(filterLabel, groupLabel, now, dateFormat, l),
        footer: (context) => _buildFooter(context, now, dateFormat, l),
        build: (context) {
          final widgets = <pw.Widget>[];

          for (final group in groups) {
            if (group.key != null) {
              widgets.add(_buildGroupHeader(group.key!));
            }
            for (final entry in group.value) {
              widgets.add(
                _buildEntryRow(entry, petMap[entry.petId], dateFormat, l),
              );
            }
          }

          if (widgets.isEmpty) {
            widgets.add(
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Text(
                    l.pdfNoEventsToDisplay,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfReportTokens.muted,
                    ),
                  ),
                ),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    String filterLabel,
    String groupLabel,
    DateTime now,
    DateFormat dateFormat,
    AppLocalizations l,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfReportTokens.primary,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  l.pdfEventsChecklist,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfReportTokens.inverse,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  l.pdfGroupedBy(filterLabel, groupLabel),
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfReportTokens.primarySoft,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                l.pdfAgathaCheck,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfReportTokens.primarySoft,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                dateFormat.format(now),
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfReportTokens.primarySoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(
    pw.Context context,
    DateTime generatedAt,
    DateFormat dateFormat,
    AppLocalizations l,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfReportTokens.border, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            l.pdfGeneratedBy(dateFormat.format(generatedAt)),
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfReportTokens.muted,
            ),
          ),
          pw.Text(
            l.pdfPageOf(context.pageNumber, context.pagesCount),
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfReportTokens.muted,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGroupHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfReportTokens.primaryLight,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 3,
            height: 14,
            decoration: pw.BoxDecoration(
              color: PdfReportTokens.primary,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfReportTokens.primary,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEntryRow(
    HealthEntry entry,
    Pet? pet,
    DateFormat dateFormat,
    AppLocalizations l,
  ) {
    final dueText = entry.isCompleted
        ? l.pdfDone
        : entry.nextDueDate != null
        ? dateFormat.format(entry.nextDueDate!)
        : l.notSet;
    final completedText = entry.completedOn != null
        ? dateFormat.format(entry.completedOn!)
        : null;
    final freqText = _frequencyLabel(
      entry.frequency,
      entry.frequencyInterval,
      l,
    );

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfReportTokens.border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: _checkboxSize,
            height: _checkboxSize,
            margin: const pw.EdgeInsets.only(right: 8, top: 1),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfReportTokens.primary, width: 1.2),
              borderRadius: pw.BorderRadius.circular(3),
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        entry.dosage.isNotEmpty
                            ? '${entry.name}  -  ${entry.dosage}'
                            : entry.name,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfReportTokens.heading,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfReportTokens.primaryLight,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        _localizedType(entry.type, l),
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfReportTokens.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    if (pet != null) ...[
                      _miniDetail(l.pdfPetLabel, pet.name),
                      pw.SizedBox(width: 12),
                    ],
                    _miniDetail(l.pdfDueLabel, dueText),
                    if (completedText != null) ...[
                      pw.SizedBox(width: 12),
                      _miniDetail(l.completedOn, completedText),
                    ],
                    pw.SizedBox(width: 12),
                    _miniDetail(l.pdfFreqLabel, freqText),
                    if (entry.notes.isNotEmpty) ...[
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Text(
                          '${l.pdfNotesLabel}: ${entry.notes}',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfReportTokens.muted,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.healthIssueName != null &&
                    entry.healthIssueName!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${l.pdfIssueLabel}: ${entry.healthIssueName}',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfReportTokens.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _miniDetail(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfReportTokens.muted,
            ),
          ),
          pw.TextSpan(
            text: value,
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfReportTokens.heading,
            ),
          ),
        ],
      ),
    );
  }

  String _localizedType(HealthEntryType type, AppLocalizations l) {
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

  String _frequencyLabel(
    HealthFrequency freq,
    int interval,
    AppLocalizations l,
  ) {
    if (freq == HealthFrequency.once) return l.pdfOnce;
    if (freq == HealthFrequency.custom) return l.pdfCustom;
    final period = _localizedPeriod(freq, l);
    if (interval == 1) return l.pdfEvery(period);
    return l.pdfEveryN(interval, '${period}s');
  }

  String _localizedPeriod(HealthFrequency freq, AppLocalizations l) {
    switch (freq) {
      case HealthFrequency.daily:
        return l.daily;
      case HealthFrequency.weekly:
        return l.weekly;
      case HealthFrequency.monthly:
        return l.monthly;
      case HealthFrequency.yearly:
        return l.yearly;
      default:
        return freq.label;
    }
  }
}
