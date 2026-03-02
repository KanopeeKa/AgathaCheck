import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../domain/entities/pet.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../vet/domain/entities/vet.dart';

class ReportSections {
  final bool petProfile;
  final bool weightTracking;
  final bool healthEvents;
  final DateTime? healthFrom;
  final DateTime? healthTo;
  final bool includeFullLog;

  const ReportSections({
    this.petProfile = true,
    this.weightTracking = false,
    this.healthEvents = false,
    this.healthFrom,
    this.healthTo,
    this.includeFullLog = false,
  });
}

class PetReportService {
  static const _brandPurple = PdfColor.fromInt(0xFF6750A4);
  static const _brandPurpleLight = PdfColor.fromInt(0xFFEADDFF);
  static const _textDark = PdfColor.fromInt(0xFF1C1B1F);
  static const _textMuted = PdfColor.fromInt(0xFF49454F);
  static const _borderColor = PdfColor.fromInt(0xFFCAC4D0);
  static const _white = PdfColors.white;

  Future<Uint8List> generateReport({
    required Pet pet,
    required ReportSections sections,
    Vet? vet,
    List<WeightEntry> weightEntries = const [],
    List<HealthEntry> healthEntries = const [],
    Map<String, List<Map<String, dynamic>>> healthHistories = const {},
    String weightUnit = 'kg',
  }) async {
    final pdf = pw.Document(
      title: '${pet.name} - Pet Report',
      author: 'Agatha Check',
    );

    final dateFormat = DateFormat('MMM d, yyyy');
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(pet, dateFormat),
        footer: (context) => _buildFooter(context, now, dateFormat),
        build: (context) {
          final widgets = <pw.Widget>[];

          if (sections.petProfile) {
            widgets.addAll(_buildProfileSection(pet, vet, weightEntries, weightUnit));
          }

          if (sections.weightTracking) {
            widgets.addAll(
                _buildWeightSection(weightEntries, dateFormat, weightUnit));
          }

          if (sections.healthEvents) {
            widgets.addAll(_buildHealthSection(
              healthEntries,
              dateFormat,
              sections.healthFrom,
              sections.healthTo,
              sections.includeFullLog,
              healthHistories,
            ));
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Pet pet, DateFormat dateFormat) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _brandPurple,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          if (pet.photoPath != null && pet.photoPath!.isNotEmpty)
            pw.Container(
              width: 60,
              height: 60,
              margin: const pw.EdgeInsets.only(right: 16),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(30),
                border: pw.Border.all(color: _white, width: 2),
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
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  [
                    pet.species,
                    if (pet.breed.isNotEmpty) pet.breed,
                    if (pet.age != null) '${pet.age!.toStringAsFixed(1)} years',
                  ].join(' • '),
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromInt(0xFFE8DEF8),
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'AGATHA CHECK',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFFE8DEF8),
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Pet Health Report',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFFD0BCFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(
      pw.Context context, DateTime generatedAt, DateFormat dateFormat) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated ${dateFormat.format(generatedAt)} by Agatha Check',
            style: const pw.TextStyle(fontSize: 8, color: _textMuted),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _textMuted),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildProfileSection(
      Pet pet, Vet? vet, List<WeightEntry> weightEntries, String weightUnit) {
    final latestWeight = weightEntries.isNotEmpty
        ? weightEntries.last.weight
        : pet.weight;

    return [
      _sectionTitle('Pet Profile'),
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _borderColor, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            _detailRow('Name', pet.name),
            _detailRow('Species', pet.species),
            if (pet.breed.isNotEmpty) _detailRow('Breed', pet.breed),
            if (pet.gender != null && pet.gender!.isNotEmpty)
              _detailRow('Gender', pet.gender!),
            if (pet.age != null)
              _detailRow('Age', '${pet.age!.toStringAsFixed(1)} years'),
            if (latestWeight != null)
              _detailRow('Current Weight', _formatWeight(latestWeight, weightUnit),
                  highlight: true),
            if (pet.bio.isNotEmpty) _detailRow('Bio', pet.bio),
            if (vet != null) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: _brandPurpleLight,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Veterinarian',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _brandPurple)),
                    pw.SizedBox(height: 4),
                    pw.Text(vet.name,
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    if (vet.phone.isNotEmpty)
                      pw.Text(vet.phone,
                          style:
                              const pw.TextStyle(fontSize: 9, color: _textMuted)),
                    if (vet.email.isNotEmpty)
                      pw.Text(vet.email,
                          style:
                              const pw.TextStyle(fontSize: 9, color: _textMuted)),
                    if (vet.address.isNotEmpty)
                      pw.Text(vet.address,
                          style:
                              const pw.TextStyle(fontSize: 9, color: _textMuted)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      pw.SizedBox(height: 20),
    ];
  }

  List<pw.Widget> _buildWeightSection(
      List<WeightEntry> entries, DateFormat dateFormat, String weightUnit) {
    if (entries.isEmpty) {
      return [
        _sectionTitle('Weight Tracking'),
        _emptyMessage('No weight data recorded yet.'),
        pw.SizedBox(height: 20),
      ];
    }

    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final chartHeight = 120.0;

    return [
      _sectionTitle('Weight Tracking'),
      if (sorted.length >= 2)
        pw.Container(
          height: chartHeight + 40,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _borderColor, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis(
                _chartDateLabels(sorted),
                textStyle: const pw.TextStyle(fontSize: 7, color: _textMuted),
              ),
              yAxis: pw.FixedAxis(
                _chartWeightLabels(sorted, weightUnit),
                textStyle: const pw.TextStyle(fontSize: 7, color: _textMuted),
              ),
            ),
            datasets: [
              pw.LineDataSet(
                data: _chartDataPoints(sorted),
                color: _brandPurple,
                lineWidth: 2,
                drawPoints: true,
                pointSize: 4,
                pointColor: _brandPurple,
              ),
            ],
          ),
        ),
      pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: _borderColor, width: 0.5),
        headerStyle: pw.TextStyle(
            fontSize: 9, fontWeight: pw.FontWeight.bold, color: _white),
        headerDecoration: const pw.BoxDecoration(color: _brandPurple),
        cellStyle: const pw.TextStyle(fontSize: 9, color: _textDark),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.centerLeft,
        },
        headers: ['Date', 'Weight', 'Notes'],
        data: sorted.reversed.map((e) {
          return [
            dateFormat.format(e.date),
            _formatWeight(e.weight, weightUnit),
            e.notes,
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 20),
    ];
  }

  List<double> _chartDateLabels(List<WeightEntry> sorted) {
    if (sorted.length <= 1) return [0];
    final first = sorted.first.date.millisecondsSinceEpoch.toDouble();
    final last = sorted.last.date.millisecondsSinceEpoch.toDouble();
    final step = (last - first) / 4;
    return List.generate(5, (i) => first + step * i);
  }

  List<double> _chartWeightLabels(List<WeightEntry> sorted, String weightUnit) {
    final weights = sorted.map((e) => e.weight).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = maxW == minW ? 1.0 : maxW - minW;
    final paddedMin = minW - range * 0.1;
    final paddedMax = maxW + range * 0.1;
    final step = (paddedMax - paddedMin) / 4;
    return List.generate(5, (i) => paddedMin + step * i);
  }

  List<pw.PointChartValue> _chartDataPoints(List<WeightEntry> sorted) {
    return sorted
        .map((e) => pw.PointChartValue(
              e.date.millisecondsSinceEpoch.toDouble(),
              e.weight,
            ))
        .toList();
  }

  List<pw.Widget> _buildHealthSection(
    List<HealthEntry> allEntries,
    DateFormat dateFormat,
    DateTime? from,
    DateTime? to,
    bool includeFullLog,
    Map<String, List<Map<String, dynamic>>> histories,
  ) {
    if (allEntries.isEmpty) {
      return [
        _sectionTitle('Health Events'),
        _emptyMessage('No health events recorded yet.'),
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
      _sectionTitle('Health Events'),
    ];

    if (currentRecurring.isNotEmpty) {
      widgets.add(_subSectionTitle('Current & Recurring Events'));
      widgets.add(
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: _borderColor, width: 0.5),
          headerStyle: pw.TextStyle(
              fontSize: 9, fontWeight: pw.FontWeight.bold, color: _white),
          headerDecoration: const pw.BoxDecoration(color: _brandPurple),
          cellStyle: const pw.TextStyle(fontSize: 9, color: _textDark),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          headers: ['Name', 'Type', 'Frequency', 'Next Due', 'Dosage'],
          data: currentRecurring.map((e) {
            return [
              e.name,
              e.type.name,
              e.frequency.name,
              e.nextDueDate.year >= 9999
                  ? 'Completed'
                  : dateFormat.format(e.nextDueDate),
              e.dosage,
            ];
          }).toList(),
        ),
      );
      widgets.add(pw.SizedBox(height: 16));
    }

    widgets.add(_subSectionTitle(
        'Events from ${dateFormat.format(filterFrom)} to ${dateFormat.format(filterTo)}'));

    if (periodEntries.isEmpty) {
      widgets.add(_emptyMessage('No events in this period.'));
    } else {
      for (final entry in periodEntries) {
        widgets.add(_buildHealthEntryBlock(
            entry, dateFormat, includeFullLog, histories));
      }
    }

    widgets.add(pw.SizedBox(height: 20));
    return widgets;
  }

  pw.Widget _buildHealthEntryBlock(
    HealthEntry entry,
    DateFormat dateFormat,
    bool includeFullLog,
    Map<String, List<Map<String, dynamic>>> histories,
  ) {
    final history = histories[entry.id] ?? [];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
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
                child: pw.Text(entry.type.name.toUpperCase(),
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
              _miniDetail('Start', dateFormat.format(entry.startDate)),
              pw.SizedBox(width: 16),
              _miniDetail(
                  'Due',
                  entry.nextDueDate.year >= 9999
                      ? 'Completed'
                      : dateFormat.format(entry.nextDueDate)),
              if (entry.dosage.isNotEmpty) ...[
                pw.SizedBox(width: 16),
                _miniDetail('Dosage', entry.dosage),
              ],
              pw.SizedBox(width: 16),
              _miniDetail('Frequency', entry.frequency.name),
            ],
          ),
          if (entry.notes.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Notes: ${entry.notes}',
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
                  pw.Text('Administration Log',
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
                        '• ${dt != null ? dateFormat.format(dt) : takenAt}'
                        '${notes.isNotEmpty ? ' — $notes' : ''}',
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

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: _brandPurple, width: 1.5)),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: _brandPurple,
          letterSpacing: 1,
        ),
      ),
    );
  }

  pw.Widget _subSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _textDark,
        ),
      ),
    );
  }

  pw.Widget _emptyMessage(String msg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(msg,
          style: const pw.TextStyle(fontSize: 10, color: _textMuted)),
    );
  }

  pw.Widget _detailRow(String label, String value, {bool highlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textMuted)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: _textDark,
                  fontWeight:
                      highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
                )),
          ),
        ],
      ),
    );
  }

  pw.Widget _miniDetail(String label, String value) {
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

  String _formatWeight(double kg, String unit) {
    if (unit == 'lb') {
      return '${(kg * 2.20462).toStringAsFixed(1)} lb';
    }
    return '${kg.toStringAsFixed(1)} kg';
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
