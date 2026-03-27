import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../organization/domain/entities/family_event.dart';

class PetFamilyEventsSectionBuilder {
  static const _borderColor = PdfColor.fromInt(0xFFCAC4D0);
  static const _brandPurple = PdfColor.fromInt(0xFF6750A4);
  static const _white = PdfColors.white;
  static const _textDark = PdfColor.fromInt(0xFF1C1B1F);
  static const _textMuted = PdfColor.fromInt(0xFF49454F);

  static List<pw.Widget> build(
    List<FamilyEvent> events,
    DateFormat dateFormat,
    AppLocalizations l,
  ) {
    if (events.isEmpty) {
      return [
        _sectionTitle(l.pdfFamilyEventsSection),
        _emptyMessage(l.pdfNoFamilyEvents),
        pw.SizedBox(height: 20),
      ];
    }

    final sorted = List<FamilyEvent>.from(events)
      ..sort((a, b) => b.fromDate.compareTo(a.fromDate));

    return [
      _sectionTitle(l.pdfFamilyEventsSection),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: _borderColor, width: 0.5),
        headerStyle: pw.TextStyle(
            fontSize: 8, fontWeight: pw.FontWeight.bold, color: _white),
        headerDecoration: const pw.BoxDecoration(color: _brandPurple),
        cellStyle: const pw.TextStyle(fontSize: 8, color: _textDark),
        cellPadding:
            const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.centerLeft,
        },
        headers: [
          l.pdfAssignedTo,
          l.pdfFromDate,
          l.pdfToDate,
          l.pdfNotes,
        ],
        data: sorted.map((e) {
          return [
            e.assignedDisplay,
            dateFormat.format(e.fromDate),
            e.toDate != null ? dateFormat.format(e.toDate!) : l.pdfOngoing,
            e.notes,
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 14),
    ];
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
}
