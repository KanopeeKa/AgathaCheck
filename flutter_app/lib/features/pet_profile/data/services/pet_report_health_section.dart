import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';

class PetHealthSectionBuilder {
  static const _borderColor = PdfColor.fromInt(0xFFCAC4D0);
  static const _brandPurple = PdfColor.fromInt(0xFF6750A4);
  static const _brandPurpleLight = PdfColor.fromInt(0xFFEADDFF);
  static const _white = PdfColors.white;
  static const _textDark = PdfColor.fromInt(0xFF1C1B1F);
  static const _textMuted = PdfColor.fromInt(0xFF49454F);

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
        return e.nextDueDate.year < 9999;
      }
      return true;
    }).toList();

    final periodEntries = allEntries.where((e) {
      final d = e.startDate;
      return !d.isBefore(filterFrom) && !d.isAfter(filterTo);
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final widgets = <pw.Widget>[
      _sectionTitle(l.pdfHealthEventsSection),
    ];

    if (currentRecurring.isNotEmpty) {
      widgets.add(_subSectionTitle(l.pdfCurrentRecurring));
      widgets.add(
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: _borderColor, width: 0.5),
          headerStyle: pw.TextStyle(
              fontSize: 8, fontWeight: pw.FontWeight.bold, color: _white),
          headerDecoration: const pw.BoxDecoration(color: _brandPurple),
          cellStyle: const pw.TextStyle(fontSize: 8, color: _textDark),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          headers: [l.pdfName, l.pdfType, l.pdfFrequency, l.pdfNextDue, l.pdfDosage],
          data: currentRecurring.map((e) {
            return [
              e.name,
              e.type.label,
              e.frequency.label,
              e.nextDueDate.year >= 9999
                  ? l.pdfCompleted
                  : dateFormat.format(e.nextDueDate),
              e.dosage,
            ];
          }).toList(),
        ),
      );
      widgets.add(pw.SizedBox(height: 10));
    }

    widgets.add(_subSectionTitle(
        l.pdfEventsFromTo(dateFormat.format(filterFrom), dateFormat.format(filterTo))));

    if (periodEntries.isEmpty) {
      widgets.add(_emptyMessage(l.pdfNoEventsInPeriod));
    } else {
      for (final entry in periodEntries) {
        widgets.add(_buildHealthEntryBlock(
            entry, dateFormat, includeFullLog, histories, l));
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
        border:
            pw.Border(bottom: pw.BorderSide(color: _brandPurple, width: 1.5)),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: _brandPurple,
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
          color: _textDark,
        ),
      ),
    );
  }

  static pw.Widget _emptyMessage(String msg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(msg,
          style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
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
        border: pw.Border.all(color: _borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(entry.name,
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _textDark)),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: _brandPurpleLight,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(entry.type.label.toUpperCase(),
                    style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: _brandPurple)),
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
                  entry.nextDueDate.year >= 9999
                      ? l.pdfCompleted
                      : dateFormat.format(entry.nextDueDate)),
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
            pw.Text('${l.pdfNotes}: ${entry.notes}',
                style:
                    const pw.TextStyle(fontSize: 8, color: _textMuted)),
          ],
          if (includeFullLog && history.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF5F5F5),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(l.pdfAdminLog,
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _brandPurple)),
                  pw.SizedBox(height: 3),
                  ...history.map((h) {
                    final takenAt = h['taken_at'] as String? ?? '';
                    final notes = h['notes'] as String? ?? '';
                    DateTime? dt;
                    try {
                      dt = DateTime.parse(takenAt);
                    } catch (_) {}
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        '- ${dt != null ? dateFormat.format(dt) : takenAt}'
                        '${notes.isNotEmpty ? ' - $notes' : ''}',
                        style: const pw.TextStyle(
                            fontSize: 8, color: _textDark),
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
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: _textMuted)),
        pw.Text(value,
            style: const pw.TextStyle(fontSize: 9, color: _textDark)),
      ],
    );
  }
}
