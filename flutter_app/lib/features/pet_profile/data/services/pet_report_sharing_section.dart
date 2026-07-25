import '../../../../core/theme/pdf_report_tokens.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../l10n/app_localizations.dart';
import '../../../sharing/domain/entities/pet_access.dart';

class PetSharingSectionBuilder {
  static List<pw.Widget> build(List<PetAccess> accessList, AppLocalizations l) {
    if (accessList.isEmpty) {
      return [
        _sectionTitle(l.pdfSharingSection),
        _emptyMessage(l.pdfNotShared),
        pw.SizedBox(height: 20),
      ];
    }

    return [
      _sectionTitle(l.pdfSharingSection),
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
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.centerLeft,
        },
        headers: [l.pdfName, l.pdfRole, l.pdfSince],
        data: accessList.map((a) {
          final name =
              a.user?.displayName ?? l.pdfUserNumber(a.userId.toString());
          final role = a.role == PetAccessRole.guardian
              ? l.pdfGuardian
              : l.pdfShared;
          final since = a.createdAt.toLocal().toString().split(' ')[0];
          return [name, role, since];
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
