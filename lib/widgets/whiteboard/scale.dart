import 'dart:ui';

import 'package:lucy_sez/widgets/whiteboard/stroke.dart';

double calculateScale(List<Stroke> strokes, Size size) {
  // Find extremes of strokes (position, for scaling)
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;

  for (final stroke in strokes) {
    // Get bounds of path
    final bounds = stroke.path.getBounds();

    // Update min/max values
    minX = bounds.left < minX ? bounds.left : minX;
    minY = bounds.top < minY ? bounds.top : minY;
    maxX = bounds.right > maxX ? bounds.right : maxX;
    maxY = bounds.bottom > maxY ? bounds.bottom : maxY;
  }

  // Calculate scale
  // The scale can never be less than greater than 1 (to prevent tiny drawings from being scaled up)
  late final double scaleX;
  late final double scaleY;

  try {
    scaleX = (size.width / (maxX - minX)).clamp(0, 1).toDouble();
    scaleY = (size.height / (maxY - minY)).clamp(0, 1).toDouble();
  } catch (e) {
    // If there are no strokes, set scale to 1.
    scaleX = 1;
    scaleY = 1;
  }

  if (scaleX == 0 || scaleY == 0) {
    return 1;
  }

  final scale = scaleX < scaleY ? scaleX : scaleY;

  return scale;
}

Point unscalePoint(Point point, double scale) {
  return Point(point.x / scale, point.y / scale);
}
