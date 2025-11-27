import 'dart:math' as math;

/// 2D Point/Vector representation
class Vec2 {
  final double x;
  final double y;

  const Vec2(this.x, this.y);
  const Vec2.zero() : x = 0, y = 0;

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double scalar) => Vec2(x * scalar, y * scalar);
  Vec2 operator /(double scalar) => Vec2(x / scalar, y / scalar);
  Vec2 operator -() => Vec2(-x, -y);

  double dot(Vec2 other) => x * other.x + y * other.y;
  double cross(Vec2 other) => x * other.y - y * other.x;

  double get length => math.sqrt(x * x + y * y);
  double get lengthSquared => x * x + y * y;

  Vec2 get normalized {
    final len = length;
    if (len == 0) return const Vec2.zero();
    return this / len;
  }

  Vec2 get perpendicular => Vec2(-y, x);

  /// Returns the angle of this vector in radians (from positive x-axis)
  double get angle => math.atan2(y, x);

  double distanceTo(Vec2 other) => (this - other).length;
  double distanceSquaredTo(Vec2 other) => (this - other).lengthSquared;

  Vec2 lerp(Vec2 other, double t) => this + (other - this) * t;

  Vec2 rotate(double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Vec2(x * c - y * s, x * s + y * c);
  }

  double angleTo(Vec2 other) => math.atan2(cross(other), dot(other));

  @override
  String toString() => 'Vec2($x, $y)';

  @override
  bool operator ==(Object other) =>
      other is Vec2 && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory Vec2.fromJson(Map<String, dynamic> json) =>
      Vec2(json['x'] as double, json['y'] as double);
}

/// Axis-aligned bounding box
class BoundingBox {
  final Vec2 min;
  final Vec2 max;

  const BoundingBox(this.min, this.max);

  factory BoundingBox.fromPoints(Iterable<Vec2> points) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }

    return BoundingBox(Vec2(minX, minY), Vec2(maxX, maxY));
  }

  double get width => max.x - min.x;
  double get height => max.y - min.y;
  Vec2 get center => Vec2((min.x + max.x) / 2, (min.y + max.y) / 2);
  Vec2 get size => Vec2(width, height);

  bool contains(Vec2 point) =>
      point.x >= min.x &&
      point.x <= max.x &&
      point.y >= min.y &&
      point.y <= max.y;

  bool intersects(BoundingBox other) =>
      min.x <= other.max.x &&
      max.x >= other.min.x &&
      min.y <= other.max.y &&
      max.y >= other.min.y;

  BoundingBox expand(double amount) =>
      BoundingBox(min - Vec2(amount, amount), max + Vec2(amount, amount));

  BoundingBox union(BoundingBox other) => BoundingBox(
        Vec2(math.min(min.x, other.min.x), math.min(min.y, other.min.y)),
        Vec2(math.max(max.x, other.max.x), math.max(max.y, other.max.y)),
      );
}

/// Geometric utilities
class GeometryUtils {
  /// Distance from point to line segment
  static double pointToSegmentDistance(Vec2 point, Vec2 a, Vec2 b) {
    final ab = b - a;
    final ap = point - a;

    final proj = ap.dot(ab);
    final lenSq = ab.lengthSquared;

    double t = 0;
    if (lenSq != 0) {
      t = proj / lenSq;
    }

    if (t < 0) {
      return point.distanceTo(a);
    } else if (t > 1) {
      return point.distanceTo(b);
    } else {
      return point.distanceTo(a + ab * t);
    }
  }

  /// Closest point on line segment to given point
  static Vec2 closestPointOnSegment(Vec2 point, Vec2 a, Vec2 b) {
    final ab = b - a;
    final ap = point - a;

    final proj = ap.dot(ab);
    final lenSq = ab.lengthSquared;

    if (lenSq == 0) return a;

    double t = proj / lenSq;
    t = t.clamp(0.0, 1.0);

    return a + ab * t;
  }

  /// Distance from point to circle edge
  static double pointToCircleDistance(Vec2 point, Vec2 center, double radius) {
    return (point.distanceTo(center) - radius).abs();
  }

  /// Check if point is inside circle
  static bool pointInCircle(Vec2 point, Vec2 center, double radius) {
    return point.distanceSquaredTo(center) <= radius * radius;
  }

  /// Line-line intersection
  static Vec2? lineLineIntersection(Vec2 p1, Vec2 d1, Vec2 p2, Vec2 d2) {
    final cross = d1.cross(d2);
    if (cross.abs() < 1e-10) return null; // Parallel lines

    final t = (p2 - p1).cross(d2) / cross;
    return p1 + d1 * t;
  }

  /// Line segment intersection
  static Vec2? segmentIntersection(Vec2 a1, Vec2 a2, Vec2 b1, Vec2 b2) {
    final d1 = a2 - a1;
    final d2 = b2 - b1;
    final cross = d1.cross(d2);

    if (cross.abs() < 1e-10) return null;

    final t1 = (b1 - a1).cross(d2) / cross;
    final t2 = (b1 - a1).cross(d1) / cross;

    if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1) {
      return a1 + d1 * t1;
    }
    return null;
  }

  /// Line-circle intersection
  static List<Vec2> lineCircleIntersection(
      Vec2 lineStart, Vec2 lineEnd, Vec2 center, double radius) {
    final d = lineEnd - lineStart;
    final f = lineStart - center;

    final a = d.dot(d);
    final b = 2 * f.dot(d);
    final c = f.dot(f) - radius * radius;

    final discriminant = b * b - 4 * a * c;

    if (discriminant < 0) return [];

    final sqrtDisc = math.sqrt(discriminant);
    final t1 = (-b - sqrtDisc) / (2 * a);
    final t2 = (-b + sqrtDisc) / (2 * a);

    final results = <Vec2>[];

    if (t1 >= 0 && t1 <= 1) {
      results.add(lineStart + d * t1);
    }
    if (t2 >= 0 && t2 <= 1 && (discriminant > 1e-10)) {
      results.add(lineStart + d * t2);
    }

    return results;
  }

  /// Circle-circle intersection
  static List<Vec2> circleCircleIntersection(
      Vec2 c1, double r1, Vec2 c2, double r2) {
    final d = c2.distanceTo(c1);

    if (d > r1 + r2 || d < (r1 - r2).abs() || d == 0) {
      return [];
    }

    final a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);
    final h = math.sqrt(r1 * r1 - a * a);

    final p = c1 + (c2 - c1) * (a / d);
    final offset = (c2 - c1).perpendicular.normalized * h;

    if (h < 1e-10) {
      return [p];
    }

    return [p + offset, p - offset];
  }

  /// Snap angle to increments (e.g., 45 degrees)
  static double snapAngle(double angle, double increment) {
    final snapped = (angle / increment).round() * increment;
    return snapped;
  }

  /// Snap point to grid
  static Vec2 snapToGrid(Vec2 point, double gridSize) {
    return Vec2(
      (point.x / gridSize).round() * gridSize,
      (point.y / gridSize).round() * gridSize,
    );
  }
}
