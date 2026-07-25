import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/pdf_report_tokens.dart';

/// Guards against [PdfReportTokens] drifting from [AppColorTokens]: PDF
/// reports use a separate `PdfColor` type, so the hex values are declared
/// twice by necessity. If the app palette changes without updating this
/// file, these assertions fail and point back here.
void main() {
  group('PdfReportTokens', () {
    void expectSameHex(Color appColor, int pdfArgb, String label) {
      expect(
        pdfArgb,
        appColor.toARGB32(),
        reason: '$label should mirror AppColorTokens',
      );
    }

    test('primary tokens mirror AppColorTokens', () {
      expectSameHex(
        AppColorTokens.guardianPrimary,
        PdfReportTokens.primary.toInt(),
        'PdfReportTokens.primary',
      );
      expectSameHex(
        AppColorTokens.guardianLight,
        PdfReportTokens.primaryLight.toInt(),
        'PdfReportTokens.primaryLight',
      );
      expectSameHex(
        AppColorTokens.guardianSoft,
        PdfReportTokens.primarySoft.toInt(),
        'PdfReportTokens.primarySoft',
      );
    });

    test('neutral tokens mirror AppColorTokens', () {
      expectSameHex(
        AppColorTokens.border,
        PdfReportTokens.border.toInt(),
        'PdfReportTokens.border',
      );
      expectSameHex(
        AppColorTokens.heading,
        PdfReportTokens.heading.toInt(),
        'PdfReportTokens.heading',
      );
      expectSameHex(
        AppColorTokens.muted,
        PdfReportTokens.muted.toInt(),
        'PdfReportTokens.muted',
      );
      expectSameHex(
        AppColorTokens.surfaceAlt,
        PdfReportTokens.neutralBg.toInt(),
        'PdfReportTokens.neutralBg',
      );
      expectSameHex(
        AppColorTokens.inverse,
        PdfReportTokens.inverse.toInt(),
        'PdfReportTokens.inverse',
      );
    });
  });
}
