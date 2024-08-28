import 'package:flutter/material.dart';
import 'package:lucy_sez/widgets/whiteboard/scale.dart';
import 'package:lucy_sez/widgets/whiteboard/stroke.dart';

class WhiteboardPainter extends CustomPainter {
  final List<Stroke> strokes;

  WhiteboardPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    // Find scale
    final scale = calculateScale(strokes, size);

    // Draw cliprect on canvas
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw strokes
    final strokePaint = Paint()
      ..strokeWidth = 1
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.srcOver;
    for (final stroke in strokes) {
      // Scale path
      final scaledPath = stroke.path.transform(
        (Matrix4.identity()..scale(scale, scale)).storage,
      );

      // Draw path
      canvas.drawPath(scaledPath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Always repaint (for now)
    return true;
  }
}
