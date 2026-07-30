import '../../../../core/theme/pdf_report_tokens.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';

class PetWeightSectionBuilder {
  static final DateFormat _chartDateFormat = DateFormat('dd/MMM/yy');

  static List<pw.Widget> build(
    List<WeightEntry> entries,
    DateFormat dateFormat,
    String weightUnit,
    AppLocalizations l,
  ) {
    if (entries.isEmpty) {
      return [
        _sectionTitle(l.pdfWeightTrackingSection),
        _emptyMessage(l.pdfNoWeightData),
        pw.SizedBox(height: 20),
      ];
    }

    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final chartHeight = 100.0;

    return [
      _sectionTitle(l.pdfWeightTrackingSection),
      if (sorted.length >= 2)
        pw.Container(
          height: chartHeight + 30,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfReportTokens.border, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis(
                _chartWeightLabels(sorted, weightUnit),
                format: (v) => v.toStringAsFixed(2),
                textStyle: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfReportTokens.muted,
                ),
              ),
              yAxis: pw.FixedAxis(
                _chartDateLabels(sorted),
                format: (v) => _chartDateFormat.format(
                  DateTime.fromMillisecondsSinceEpoch(v.toInt()),
                ),
                textStyle: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfReportTokens.muted,
                ),
              ),
            ),
            datasets: [
              pw.LineDataSet(
                data: _chartDataPoints(sorted, weightUnit),
                color: PdfReportTokens.primary,
                lineWidth: 2,
                drawPoints: true,
                pointSize: 4,
                pointColor: PdfReportTokens.primary,
              ),
            ],
          ),
        ),
      pw.SizedBox(height: 8),
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
        headers: [l.pdfDate, l.pdfWeight, l.pdfNotes],
        data: sorted.reversed.take(3).map((e) {
          return [
            dateFormat.format(e.date),
            _formatWeight(e.weight, weightUnit),
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

  static List<double> _chartDateLabels(List<WeightEntry> sorted) {
    if (sorted.length <= 1) return [0];
    final first = sorted.first.date.millisecondsSinceEpoch.toDouble();
    final last = sorted.last.date.millisecondsSinceEpoch.toDouble();
    final step = (last - first) / 4;
    return List.generate(5, (i) => first + step * i);
  }

  static List<double> _chartWeightLabels(
    List<WeightEntry> sorted,
    String weightUnit,
  ) {
    final weights = sorted
        .map((e) => _displayWeight(e.weight, weightUnit))
        .toList();
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final paddedMax = maxW == 0
        ? 1.0
        : maxW + (maxW * 0.1).clamp(0.1, double.infinity);
    final step = paddedMax / 4;
    return List.generate(5, (i) => step * i);
  }

  static List<pw.PointChartValue> _chartDataPoints(
    List<WeightEntry> sorted,
    String weightUnit,
  ) {
    return sorted
        .map(
          (e) => pw.PointChartValue(
            _displayWeight(e.weight, weightUnit),
            e.date.millisecondsSinceEpoch.toDouble(),
          ),
        )
        .toList();
  }

  static double _displayWeight(double kg, String unit) {
    if (unit == 'lb') {
      return kg * 2.20462;
    }
    return kg;
  }

  static String _formatWeight(double kg, String unit) {
    final value = _displayWeight(kg, unit);
    if (unit == 'lb') {
      return '${value.toStringAsFixed(1)} lb';
    }
    return '${value.toStringAsFixed(1)} kg';
  }
}
