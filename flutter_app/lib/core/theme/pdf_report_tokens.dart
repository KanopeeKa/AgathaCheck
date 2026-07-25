import 'package:pdf/pdf.dart';

/// PDF-report color constants, kept in sync with [AppColorTokens]
/// (`app_color_tokens.dart`).
///
/// The `pdf` package's [PdfColor] is a distinct type from Flutter's
/// `Color`, so values are declared here as their own `const`s rather than
/// converted at runtime. When the app palette changes, update the matching
/// hex here too — `test/core/theme/pdf_report_tokens_test.dart` asserts the
/// two stay in sync.
abstract final class PdfReportTokens {
  /// Mirrors `AppColorTokens.guardianPrimary`.
  static const PdfColor primary = PdfColor.fromInt(0xFF755B68);

  /// Mirrors `AppColorTokens.guardianLight`.
  static const PdfColor primaryLight = PdfColor.fromInt(0xFFF4EEF2);

  /// Mirrors `AppColorTokens.guardianSoft` — de-emphasized text/labels on
  /// top of [primary] banners.
  static const PdfColor primarySoft = PdfColor.fromInt(0xFFE7DCE2);

  /// Mirrors `AppColorTokens.inverse`.
  static const PdfColor inverse = PdfColors.white;

  /// Mirrors `AppColorTokens.border`.
  static const PdfColor border = PdfColor.fromInt(0xFFE5DDD6);

  /// Mirrors `AppColorTokens.heading`.
  static const PdfColor heading = PdfColor.fromInt(0xFF2D3338);

  /// Mirrors `AppColorTokens.muted`.
  static const PdfColor muted = PdfColor.fromInt(0xFF68737A);

  /// Mirrors `AppColorTokens.surfaceAlt`.
  static const PdfColor neutralBg = PdfColor.fromInt(0xFFF3EDE7);
}
