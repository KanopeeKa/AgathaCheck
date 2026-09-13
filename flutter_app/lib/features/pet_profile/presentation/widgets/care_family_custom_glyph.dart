import 'package:flutter/material.dart';

/// Minimal vector glyphs not available in Material Icons (24dp canvas).
class CareFamilyCustomGlyph extends StatelessWidget {
  const CareFamilyCustomGlyph({
    super.key,
    required this.family,
    required this.size,
    required this.color,
  });

  final CareFamilyGlyph family;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CareFamilyGlyphPainter(family: family, color: color),
    );
  }
}

enum CareFamilyGlyph { stethoscope, tooth }

class _CareFamilyGlyphPainter extends CustomPainter {
  _CareFamilyGlyphPainter({required this.family, required this.color});

  final CareFamilyGlyph family;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (family) {
      case CareFamilyGlyph.stethoscope:
        _paintStethoscope(canvas, size, paint);
      case CareFamilyGlyph.tooth:
        _paintTooth(canvas, size, paint);
    }
  }

  void _paintStethoscope(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 0.22, h * 0.72), w * 0.12, paint);
    canvas.drawLine(
      Offset(w * 0.34, h * 0.68),
      Offset(w * 0.5, h * 0.42),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.5, h * 0.42),
      Offset(w * 0.62, h * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.5, h * 0.42),
      Offset(w * 0.38, h * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.24),
      Offset(w * 0.78, h * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.38, h * 0.24),
      Offset(w * 0.24, h * 0.24),
      paint,
    );
  }

  void _paintTooth(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.28, h * 0.22)
      ..quadraticBezierTo(w * 0.36, h * 0.12, w * 0.5, h * 0.16)
      ..quadraticBezierTo(w * 0.64, h * 0.12, w * 0.72, h * 0.22)
      ..lineTo(w * 0.68, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 0.88, w * 0.32, h * 0.78)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(w * 0.42, h * 0.28),
      Offset(w * 0.4, h * 0.62),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.28),
      Offset(w * 0.6, h * 0.62),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CareFamilyGlyphPainter oldDelegate) =>
      oldDelegate.family != family || oldDelegate.color != color;
}
