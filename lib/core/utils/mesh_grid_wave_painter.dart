import 'package:flutter/material.dart';

// PAINTER: Custom Painted mesh wave lines
class MeshGridWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double step = 22.0;

    for (double i = 0; i < size.width; i += step) {
      path.moveTo(i, size.height);
      path.quadraticBezierTo(
        i + step * 2,
        size.height - 80 * (1 - (i / size.width)),
        i,
        size.height - 120 * (i / size.width),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
