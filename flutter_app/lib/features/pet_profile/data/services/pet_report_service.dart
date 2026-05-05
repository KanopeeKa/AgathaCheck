import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/domain/entities/health_issue.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../organization/domain/entities/family_event.dart';
import '../../../sharing/domain/entities/pet_access.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../vet/domain/entities/vet.dart';
import 'pet_report_profile_section.dart';
import 'pet_report_weight_section.dart';
import 'pet_report_health_section.dart';
import 'pet_report_health_issues_section.dart';
import 'pet_report_family_events_section.dart';
import 'pet_report_notifications_section.dart';
import 'pet_report_sharing_section.dart';

/// Controls which sections are included in the generated PDF report.
///
/// [petProfile] is always included by default. All other sections are
/// opt-in. When [healthEvents] is enabled, [healthFrom] / [healthTo]
/// control the date range, and [includeFullLog] adds the detailed
/// administration history for each entry.
class ReportSections {
  final bool petProfile;
  final bool weightTracking;
  final bool healthEvents;
  final bool healthIssues;
  final bool familyEvents;
  final bool notifications;
  final bool sharing;
  final DateTime? healthFrom;
  final DateTime? healthTo;
  final bool includeFullLog;

  const ReportSections({
    this.petProfile = true,
    this.weightTracking = false,
    this.healthEvents = false,
    this.healthIssues = false,
    this.familyEvents = false,
    this.notifications = false,
    this.sharing = false,
    this.healthFrom,
    this.healthTo,
    this.includeFullLog = false,
  });
}

class PetReportService {
  static const _brandPurple = PdfColor.fromInt(0xFF6750A4);
  static const _brandPurpleLight = PdfColor.fromInt(0xFFEADDFF);
  static const _textMuted = PdfColor.fromInt(0xFF49454F);
  static const _borderColor = PdfColor.fromInt(0xFFCAC4D0);
  static const _white = PdfColors.white;

  /// Generates a comprehensive PDF report for a single pet.
  ///
  /// The [sections] parameter controls which parts of the report are included.
  /// Data for each section is passed via the corresponding parameter lists.
  /// Returns the raw PDF bytes ready for saving or sharing.
  Future<Uint8List> generateReport({
    required Pet pet,
    required ReportSections sections,
    required AppLocalizations l,
    Vet? vet,
    List<WeightEntry> weightEntries = const [],
    List<HealthEntry> healthEntries = const [],
    List<HealthIssue> healthIssues = const [],
    List<FamilyEvent> familyEvents = const [],
    List<AppNotification> petNotifications = const [],
    List<PetAccess> accessList = const [],
    Map<String, List<Map<String, dynamic>>> healthHistories = const {},
    String weightUnit = 'kg',
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document(
      title: '${pet.name} - ${l.pdfReportTitle}',
      author: 'Agatha Track',
    );

    final dateFormat = DateFormat('MMM d, yyyy');
    final now = DateTime.now();

    pw.ImageProvider? logoImage;
    if (logoBytes != null) {
      try {
        logoImage = pw.MemoryImage(logoBytes);
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => context.pageNumber == 1
            ? _buildHeader(pet, dateFormat, logoImage, l)
            : pw.SizedBox.shrink(),
        footer: (context) => _buildFooter(context, now, dateFormat, l),
        build: (context) {
          final widgets = <pw.Widget>[];

          if (sections.petProfile) {
            widgets.addAll(PetProfileSectionBuilder.build(
              pet, vet, weightEntries, weightUnit, l));
          }

          if (sections.weightTracking) {
            widgets.addAll(PetWeightSectionBuilder.build(
              weightEntries, dateFormat, weightUnit, l));
          }

          if (sections.healthEvents) {
            widgets.addAll(PetHealthSectionBuilder.build(
              healthEntries,
              dateFormat,
              sections.healthFrom,
              sections.healthTo,
              sections.includeFullLog,
              healthHistories,
              l,
            ));
          }

          if (sections.healthIssues) {
            widgets.addAll(
                PetHealthIssuesSectionBuilder.build(healthIssues, healthEntries, dateFormat, l));
          }

          if (sections.familyEvents) {
            widgets.addAll(
                PetFamilyEventsSectionBuilder.build(familyEvents, dateFormat, l));
          }

          if (sections.notifications) {
            widgets.addAll(
                PetNotificationsSectionBuilder.build(petNotifications, dateFormat, l));
          }

          if (sections.sharing) {
            widgets.addAll(PetSharingSectionBuilder.build(accessList, l));
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
      Pet pet, DateFormat dateFormat, pw.ImageProvider? logoImage, AppLocalizations l) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _brandPurple,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          if (pet.photoPath != null && pet.photoPath!.isNotEmpty)
            pw.Container(
              width: 48,
              height: 48,
              margin: const pw.EdgeInsets.only(right: 12),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(24),
                border: pw.Border.all(color: _white, width: 1.5),
              ),
              child: pw.ClipOval(
                child: _buildPetImage(pet.photoPath!),
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  pet.name,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _white,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  [
                    pet.species,
                    if (pet.breed.isNotEmpty) pet.breed,
                    if (pet.ageDisplay != null) pet.ageDisplay!,
                  ].join(' | '),
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromInt(0xFFE8DEF8),
                  ),
                ),
              ],
            ),
          ),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 20,
                  height: 20,
                  margin: const pw.EdgeInsets.only(right: 5),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    l.pdfAgathaCheck,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFFE8DEF8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    l.pdfReportTitle,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromInt(0xFFD0BCFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(
      pw.Context context, DateTime generatedAt, DateFormat dateFormat, AppLocalizations l) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            l.pdfGeneratedBy(dateFormat.format(generatedAt)),
            style: const pw.TextStyle(fontSize: 8, color: _textMuted),
          ),
          pw.Text(
            l.pdfPageOf(context.pageNumber, context.pagesCount),
            style: const pw.TextStyle(fontSize: 8, color: _textMuted),
          ),
        ],
      ),
    );
  }


  pw.Widget _buildPetImage(String base64Data) {
    try {
      String data = base64Data;
      if (data.contains(',')) {
        data = data.split(',').last;
      }
      final bytes = base64Decode(data);
      return pw.Image(
        pw.MemoryImage(bytes),
        fit: pw.BoxFit.cover,
        width: 56,
        height: 56,
      );
    } catch (_) {
      return pw.Container(
        width: 56,
        height: 56,
        color: _brandPurpleLight,
        child: pw.Center(
          child: pw.Text('?',
              style: pw.TextStyle(fontSize: 20, color: _brandPurple)),
        ),
      );
    }
  }
}
