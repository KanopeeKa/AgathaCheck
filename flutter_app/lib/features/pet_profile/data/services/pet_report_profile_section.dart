import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet.dart';
import '../../../vet/domain/entities/vet.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';

class PetProfileSectionBuilder {
  static const _borderColor = PdfColor.fromInt(0xFFCAC4D0);
  static const _textDark = PdfColor.fromInt(0xFF1C1B1F);
  static const _textMuted = PdfColor.fromInt(0xFF49454F);

  static List<pw.Widget> build(
    Pet pet,
    Vet? vet,
    List<WeightEntry> weightEntries,
    String weightUnit,
    AppLocalizations l,
  ) {
    final latestWeight = currentWeightFromEntries(weightEntries, pet.weight);

    return [
      _sectionTitle(l.pdfPetProfileSection),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _borderColor, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            _detailRow(l.pdfName, pet.name),
            _detailRow(l.pdfSpecies, pet.species),
            if (pet.breed.isNotEmpty) _detailRow(l.pdfBreed, pet.breed),
            if (pet.gender != null && pet.gender!.isNotEmpty)
              _detailRow(l.pdfGender, pet.gender!),
            if (pet.ageDisplay != null) _detailRow(l.pdfAge, pet.ageDisplay!),
            if (pet.dateOfBirth != null)
              _detailRow(
                l.pdfDateOfBirth,
                '${pet.dateOfBirth!.day}/${pet.dateOfBirth!.month}/${pet.dateOfBirth!.year}',
              ),
            if (latestWeight != null)
              _detailRow(
                l.pdfCurrentWeight,
                _formatWeight(latestWeight, weightUnit),
                highlight: true,
              ),
            if (pet.bio.isNotEmpty) _detailRow(l.pdfBio, pet.bio),
            if (pet.neuteredDate != null)
              _detailRow(
                l.pdfNeuteredSpayed,
                DateFormat.yMMMd().format(pet.neuteredDate!),
              ),
            if (pet.chipId.isNotEmpty) _detailRow(l.pdfIdMicrochip, pet.chipId),
            if (pet.insurance.isNotEmpty)
              _detailRow(l.pdfInsurance, pet.insurance),
            if (vet != null)
              _detailRow(
                l.pdfVet,
                [
                  vet.name,
                  if (vet.phone.isNotEmpty) vet.phone,
                  if (vet.email.isNotEmpty) vet.email,
                  if (vet.address.isNotEmpty) vet.address,
                ].join(' - '),
              ),
          ],
        ),
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
          bottom: pw.BorderSide(
            color: PdfColor.fromInt(0xFF6750A4),
            width: 1.5,
          ),
        ),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF6750A4),
          letterSpacing: 1,
        ),
      ),
    );
  }

  static pw.Widget _detailRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _textMuted,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                color: _textDark,
                fontWeight: highlight
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Resolves the current weight from tracked entries (most recent by date),
  /// falling back to the pet profile weight when no entries exist.
  static double? currentWeightFromEntries(
    List<WeightEntry> entries,
    double? fallback,
  ) {
    if (entries.isEmpty) return fallback;
    return entries.reduce((a, b) => a.date.isAfter(b.date) ? a : b).weight;
  }

  static String _formatWeight(double kg, String unit) {
    if (unit == 'lb') {
      return '${(kg * 2.20462).toStringAsFixed(1)} lb';
    }
    return '${kg.toStringAsFixed(1)} kg';
  }
}
