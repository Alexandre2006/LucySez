import 'dart:ui';

class Stroke {
  List<Point> points = [];
  final Color color;

  Stroke(this.color);

  // Path Conversion
  Path get path {
    final path = Path();

    // Check if not empty
    if (points.isEmpty) {
      return path;
    }

    // Move to first point
    path.moveTo(points[0].x, points[0].y);

    // Add remaining points
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }

    return path;
  }

  // Json Conversion
  factory Stroke.fromJson(Map<String, dynamic> json) {
    final stroke = Stroke(Color(json['color']));
    for (final point in json['points']) {
      stroke.points.add(Point.fromJson(point));
    }
    return stroke;
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color.value,
      'points': points.map((point) => point.toJson()).toList(),
    };
  }
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);

  // Json Conversion
  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(json['x'], json['y']);
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}
