import '../../../../core/theme/pdf_report_tokens.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';

class PetHealthSectionBuilder {
  static List<pw.Widget> build(
    List<HealthEntry> allEntries,
    DateFormat dateFormat,
    DateTime? from,
    DateTime? to,
    bool includeFullLog,
    Map<String, List<Map<String, dynamic>>> histories,
    AppLocalizations l,
  ) {
    if (allEntries.isEmpty) {
      return [
        _sectionTitle(l.pdfHealthEventsSection),
        _emptyMessage(l.pdfNoHealthEvents),
        pw.SizedBox(height: 20),
      ];
    }

    final now = DateTime.now();
    final filterFrom = from ?? now.subtract(const Duration(days: 180));
    final filterTo = to ?? now;

    final currentRecurring = allEntries.where((e) {
      if (e.frequency == HealthFrequency.once) {
        return !e.isCompleted;
      }
      return true;
    }).toList();

    final periodEntries = allEntries.where((e) {
      final d = e.startDate;
      return !d.isBefore(filterFrom) && !d.isAfter(filterTo);
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));

    final widgets = <pw.Widget>[_sectionTitle(l.pdfHealthEventsSection)];

    if (currentRecurring.isNotEmpty) {
      widgets.add(_subSectionTitle(l.pdfCurrentRecurring));
      widgets.add(
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfReportTokens.border, width: 0.5),
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfReportTokens.inverse,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfReportTokens.primary,
          ),
          cellStyle: const pw.TextStyle(
            fontSize: 8,
            color: PdfReportTokens.heading,
          ),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 3,
          ),
          headers: [
            l.pdfName,
            l.pdfType,
            l.pdfFrequency,
            l.pdfNextDue,
            l.pdfDosage,
          ],
          data: currentRecurring.map((e) {
            return [
              e.name,
              e.type.label,
              e.frequency.label,
              e.isCompleted || e.nextDueDate == null
                  ? l.pdfCompleted
                  : dateFormat.format(e.nextDueDate!),
              e.dosage,
            ];
          }).toList(),
        ),
      );
      widgets.add(pw.SizedBox(height: 10));
    }

    widgets.add(
      _subSectionTitle(
        l.pdfEventsFromTo(
          dateFormat.format(filterFrom),
          dateFormat.format(filterTo),
        ),
      ),
    );

    if (periodEntries.isEmpty) {
      widgets.add(_emptyMessage(l.pdfNoEventsInPeriod));
    } else {
      for (final entry in periodEntries) {
        widgets.add(
          _buildHealthEntryBlock(
            entry,
            dateFormat,
            includeFullLog,
            histories,
            l,
          ),
        );
      }
    }

    widgets.add(pw.SizedBox(height: 14));
    return widgets;
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfReportTokens.primary, width: 1.5),
        ),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfReportTokens.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  static pw.Widget _subSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfReportTokens.heading,
        ),
      ),
    );
  }

  static pw.Widget _emptyMessage(String msg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfReportTokens.border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        msg,
        style: const pw.TextStyle(fontSize: 9, color: PdfReportTokens.muted),
      ),
    );
  }

  static pw.Widget _buildHealthEntryBlock(
    HealthEntry entry,
    DateFormat dateFormat,
    bool includeFullLog,
    Map<String, List<Map<String, dynamic>>> histories,
    AppLocalizations l,
  ) {
    final history = histories[entry.id] ?? [];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfReportTokens.border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  entry.name,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfReportTokens.heading,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfReportTokens.primaryLight,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  entry.type.label.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfReportTokens.primary,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              _miniDetail(l.pdfStart, dateFormat.format(entry.startDate)),
              pw.SizedBox(width: 16),
              _miniDetail(
                l.pdfDue,
                entry.isCompleted
                    ? l.pdfCompleted
                    : entry.nextDueDate != null
                    ? dateFormat.format(entry.nextDueDate!)
                    : l.notSet,
              ),
              if (entry.completedOn != null) ...[
                pw.SizedBox(width: 16),
                _miniDetail(
                  l.completedOn,
                  dateFormat.format(entry.completedOn!),
                ),
              ],
              if (entry.dosage.isNotEmpty) ...[
                pw.SizedBox(width: 16),
                _miniDetail(l.pdfDosage, entry.dosage),
              ],
              pw.SizedBox(width: 16),
              _miniDetail(l.pdfFrequency, entry.frequency.label),
            ],
          ),
          if (entry.notes.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              '${l.pdfNotes}: ${entry.notes}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfReportTokens.muted,
              ),
            ),
          ],
          if (includeFullLog && history.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfReportTokens.neutralBg,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    l.pdfAdminLog,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfReportTokens.primary,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  ...history.map((h) {
                    final due = h['due_date'] as String?;
                    final completed = h['completed_on'] as String?;
                    final markedRaw =
                        h['marked_at'] ?? h['changed_at'] ?? h['taken_at'];
                    final markedBy = h['marked_by_name'] as String? ?? '';
                    String fmt(String? raw) {
                      if (raw == null || raw.isEmpty) return l.notSet;
                      try {
                        return dateFormat.format(
                          DateTime.parse(
                            raw.contains('T') ? raw : '${raw}T00:00:00',
                          ),
                        );
                      } catch (_) {
                        return raw;
                      }
                    }

                    String markedFmt = l.notSet;
                    if (markedRaw != null) {
                      try {
                        markedFmt = DateFormat.yMMMd().add_jm().format(
                          DateTime.parse(markedRaw.toString()),
                        );
                      } catch (_) {
                        markedFmt = markedRaw.toString();
                      }
                    }
                    final line = l.eventHistoryLine(
                      fmt(due),
                      fmt(completed),
                      markedFmt,
                      markedBy.isNotEmpty ? markedBy : l.unknownUser,
                    );
                    final notes = h['notes'] as String? ?? '';
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        '- $line${notes.isNotEmpty ? ' — $notes' : ''}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfReportTokens.heading,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _miniDetail(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfReportTokens.muted,
          ),
        ),
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfReportTokens.heading,
          ),
        ),
      ],
    );
  }
}
