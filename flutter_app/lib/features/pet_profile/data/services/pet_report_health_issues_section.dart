import '../../../../core/theme/pdf_report_tokens.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_issue.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';

class PetHealthIssuesSectionBuilder {
  static List<pw.Widget> build(
    List<HealthIssue> issues,
    List<HealthEntry> allEntries,
    DateFormat dateFormat,
    AppLocalizations l,
  ) {
    if (issues.isEmpty) {
      return [
        _sectionTitle(l.pdfHealthIssuesSection),
        _emptyMessage(l.pdfNoHealthIssues),
        pw.SizedBox(height: 20),
      ];
    }

    final widgets = <pw.Widget>[_sectionTitle(l.pdfHealthIssuesSection)];

    for (final issue in issues) {
      final linked = allEntries
          .where((e) => issue.eventIds.contains(e.id))
          .toList();

      widgets.add(
        pw.Container(
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
                      issue.title,
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
                      issue.eventIds.length == 1
                          ? l.pdfNEvent(issue.eventIds.length)
                          : l.pdfNEvents(issue.eventIds.length),
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfReportTokens.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (issue.description.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  issue.description,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfReportTokens.muted,
                  ),
                ),
              ],
              if (issue.startDate != null || issue.endDate != null) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  _formatIssueDateRange(
                    issue.startDate,
                    issue.endDate,
                    dateFormat,
                    l,
                  ),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfReportTokens.muted,
                  ),
                ),
              ],
              if (linked.isNotEmpty) ...[
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
                        l.pdfLinkedEvents,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfReportTokens.primary,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      ...linked.map(
                        (e) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Text(
                            '- ${e.name} (${e.type.label})',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfReportTokens.heading,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
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

  static String _formatIssueDateRange(
    DateTime? start,
    DateTime? end,
    DateFormat fmt,
    AppLocalizations l,
  ) {
    if (start != null && end != null) {
      return '${fmt.format(start)} – ${fmt.format(end)}';
    }
    if (start != null) return l.pdfFrom(fmt.format(start));
    return l.pdfUntil(fmt.format(end!));
  }
}
