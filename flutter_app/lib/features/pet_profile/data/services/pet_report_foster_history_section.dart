import '../../../../core/theme/pdf_report_tokens.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../organization/domain/entities/foster_placement.dart';

class PetFosterHistorySectionBuilder {
  static List<pw.Widget> build(
    List<FosterPlacement> placements,
    DateFormat dateFormat,
    AppLocalizations l,
  ) {
    if (placements.isEmpty) {
      return [
        _sectionTitle(l.pdfFosterHistorySection),
        _emptyMessage(l.pdfNoFosterHistory),
        pw.SizedBox(height: 20),
      ];
    }

    return [
      _sectionTitle(l.pdfFosterHistorySection),
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
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        headers: [
          l.pdfFosterParent,
          l.pdfPlacementStatus,
          l.dueDate,
          l.completedOn,
          l.pdfNotes,
        ],
        data: placements.map((placement) {
          final fosterLabel = placement.fosterName.isNotEmpty
              ? placement.fosterName
              : placement.fosterEmail;
          return [
            fosterLabel,
            _statusLabel(l, placement),
            placement.startDate != null
                ? dateFormat.format(placement.startDate!)
                : '—',
            placement.endDate != null
                ? dateFormat.format(placement.endDate!)
                : l.pdfOngoing,
            [
              if (placement.adoptionConditions.isNotEmpty)
                placement.adoptionConditions,
              if (placement.notes.isNotEmpty) placement.notes,
            ].where((s) => s.isNotEmpty).join('\n'),
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 14),
    ];
  }

  static String _statusLabel(AppLocalizations l, FosterPlacement placement) {
    if (placement.isPending) return l.fosterPlacementPending;
    if (placement.isInProgress) return l.fosterPlacementInProgress;
    if (placement.isPendingConditions) return l.pendingAdoptionConditions;
    if (placement.isWaitingAdoption) return l.waitingAdoptionConfirmation;
    if (placement.isAdopted) return l.pdfPlacementAdopted;
    return l.fosterPlacementNotInFoster;
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
}
