import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../../core/theme/pdf_report_tokens.dart';
import '../../../../../l10n/app_localizations.dart';

class AwayPlanHandoverPetSection {
  const AwayPlanHandoverPetSection({
    required this.petName,
    required this.carerLabel,
    required this.plannedCareLines,
    this.petNote,
  });

  final String petName;
  final String carerLabel;
  final List<String> plannedCareLines;

  /// About caring for this pet — independent of carer kind (D-AWAY-014a).
  final String? petNote;
}

class AwayPlanHandoverDocument {
  const AwayPlanHandoverDocument({
    required this.title,
    required this.dateRangeLabel,
    required this.petNamesLabel,
    required this.carerCoverageSummary,
    required this.careCoverageSummary,
    required this.handoverNote,
    required this.petSections,
    this.handoverNoteSectionTitle,
  });

  final String title;
  final String dateRangeLabel;
  final String petNamesLabel;
  final String carerCoverageSummary;
  final String careCoverageSummary;
  final String? handoverNote;
  final List<AwayPlanHandoverPetSection> petSections;

  /// Overrides the section heading for [handoverNote]. The per-pet document
  /// uses a trip-wide title here so it isn't confused with the pet-specific
  /// note section (D-AWAY-014a); the full document falls back to the
  /// generic "Notes" label when this is null.
  final String? handoverNoteSectionTitle;
}

class AwayPlanHandoverService {
  /// D-AWAY-008: handover note is rendered verbatim — never parsed or normalized.
  @visibleForTesting
  static String handoverNoteForPdf(String? note) => note ?? '';

  /// D-AWAY-008 boundary, extended to `pet_note`: rendered verbatim — never
  /// parsed or normalized.
  @visibleForTesting
  static String petNoteForPdf(String? note) => note ?? '';

  Future<Uint8List> generateHandoverPdf({
    required AwayPlanHandoverDocument document,
    required AppLocalizations l,
  }) async {
    final pdf = pw.Document(title: document.title, author: 'AgathaTrack');
    final dateFormat = DateFormat('MMM d, yyyy');
    final generatedAt = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => context.pageNumber == 1
            ? _buildHeader(document, l)
            : pw.SizedBox.shrink(),
        footer: (context) => _buildFooter(context, generatedAt, dateFormat, l),
        build: (context) => _buildBody(document, l),
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _buildBody(
    AwayPlanHandoverDocument document,
    AppLocalizations l,
  ) {
    final widgets = <pw.Widget>[
      _sectionTitle(l.careContextAwayPlanCarerCoverageTitle),
      pw.Text(document.carerCoverageSummary),
      pw.SizedBox(height: 12),
      _sectionTitle(l.careContextAwayPlanCareCoverageTitle),
      pw.Text(document.careCoverageSummary),
      pw.SizedBox(height: 16),
      _sectionTitle(l.careContextAwayPlanDetailsTitle),
      _detailRow(l.careContextAwayPlanDatesLabel, document.dateRangeLabel),
      _detailRow(l.careContextAwayPlanPetsLabel, document.petNamesLabel),
      pw.SizedBox(height: 16),
      _sectionTitle(l.careContextAwayPlanWhoIsCaringTitle),
    ];

    for (final section in document.petSections) {
      widgets.addAll([
        pw.SizedBox(height: 8),
        pw.Text(
          section.petName,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.Text(section.carerLabel),
      ]);
    }

    widgets.addAll([
      pw.SizedBox(height: 16),
      _sectionTitle(l.careContextAwayPlanCareDuringTitle),
    ]);

    for (final section in document.petSections) {
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(
        pw.Text(
          section.petName,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
      );
      widgets.addAll(
        _petCareLines(
          l.awayPlanningScheduleDatedTitle,
          section.plannedCareLines,
        ),
      );
      widgets.addAll(
        _petNoteLines(
          l.awayPlanningCarerEditPetNoteLabel(section.petName),
          section.petNote,
        ),
      );
    }

    if (document.handoverNote != null && document.handoverNote!.isNotEmpty) {
      widgets.addAll([
        pw.SizedBox(height: 16),
        _sectionTitle(document.handoverNoteSectionTitle ?? l.pdfNotesLabel),
        pw.Text(handoverNoteForPdf(document.handoverNote)),
      ]);
    }

    return widgets;
  }

  List<pw.Widget> _petNoteLines(String heading, String? note) {
    final text = petNoteForPdf(note);
    if (text.isEmpty) return const [];
    return [
      pw.SizedBox(height: 8),
      pw.Text(
        heading,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfReportTokens.muted,
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 8, top: 2),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      ),
    ];
  }

  List<pw.Widget> _petCareLines(String heading, List<String> lines) {
    if (lines.isEmpty) return const [];
    return [
      pw.SizedBox(height: 4),
      pw.Text(
        heading,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfReportTokens.muted,
        ),
      ),
      ...lines.map(
        (line) => pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8, top: 2),
          child: pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
        ),
      ),
    ];
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfReportTokens.heading,
        ),
      ),
    );
  }

  pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildHeader(
    AwayPlanHandoverDocument document,
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
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            document.title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfReportTokens.inverse,
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
              pw.Text(
                document.dateRangeLabel,
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
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfReportTokens.border, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            l.pdfGeneratedBy(dateFormat.format(generatedAt)),
            style: pw.TextStyle(fontSize: 8, color: PdfReportTokens.muted),
          ),
          pw.Text(
            l.pdfPageOf(context.pageNumber, context.pagesCount),
            style: pw.TextStyle(fontSize: 8, color: PdfReportTokens.muted),
          ),
        ],
      ),
    );
  }
}
