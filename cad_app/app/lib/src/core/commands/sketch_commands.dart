import 'package:vector_math/vector_math_64.dart';

import 'command.dart';
import '../../features/sketch/domain/sketch_entities.dart';
import '../../features/sketch/domain/sketch_constraints.dart';
import '../../features/sketch/state/sketch_providers.dart';

/// Command for adding a point to the sketch.
class AddPointCommand implements Command {
  final SketchStateNotifier _notifier;
  final double x;
  final double y;
  final bool isFixed;

  SketchPoint? _addedPoint;

  AddPointCommand(
    this._notifier, {
    required this.x,
    required this.y,
    this.isFixed = false,
  });

  @override
  String get name => 'Add Point';

  @override
  void execute() {
    _addedPoint = _notifier.addPoint(x, y, isFixed: isFixed);
  }

  @override
  void undo() {
    if (_addedPoint != null) {
      _notifier.deleteEntity(_addedPoint!.id);
    }
  }

  /// Get the point that was added.
  SketchPoint? get addedPoint => _addedPoint;
}

/// Command for adding a segment to the sketch.
class AddSegmentCommand implements Command {
  final SketchStateNotifier _notifier;
  final String startPointId;
  final String endPointId;

  SketchSegment? _addedSegment;

  AddSegmentCommand(
    this._notifier, {
    required this.startPointId,
    required this.endPointId,
  });

  @override
  String get name => 'Add Line';

  @override
  void execute() {
    _addedSegment = _notifier.addSegment(startPointId, endPointId);
  }

  @override
  void undo() {
    if (_addedSegment != null) {
      _notifier.deleteEntity(_addedSegment!.id);
    }
  }

  SketchSegment? get addedSegment => _addedSegment;
}

/// Command for adding a circle to the sketch.
class AddCircleCommand implements Command {
  final SketchStateNotifier _notifier;
  final String centerPointId;
  final String radiusPointId;

  SketchCircle? _addedCircle;

  AddCircleCommand(
    this._notifier, {
    required this.centerPointId,
    required this.radiusPointId,
  });

  @override
  String get name => 'Add Circle';

  @override
  void execute() {
    _addedCircle = _notifier.addCircle(centerPointId, radiusPointId);
  }

  @override
  void undo() {
    if (_addedCircle != null) {
      _notifier.deleteEntity(_addedCircle!.id);
    }
  }

  SketchCircle? get addedCircle => _addedCircle;
}

/// Command for adding a constraint to the sketch.
class AddConstraintCommand implements Command {
  final SketchStateNotifier _notifier;
  final SketchConstraintType type;
  final List<String> entityIds;
  final double? value;
  final bool isReference;

  SketchConstraint? _addedConstraint;

  AddConstraintCommand(
    this._notifier, {
    required this.type,
    required this.entityIds,
    this.value,
    this.isReference = false,
  });

  @override
  String get name => 'Add ${_constraintTypeName(type)}';

  @override
  void execute() {
    _addedConstraint = _notifier.addConstraint(
      type,
      entityIds,
      value: value,
      isReference: isReference,
    );
  }

  @override
  void undo() {
    if (_addedConstraint != null) {
      _notifier.deleteEntity(_addedConstraint!.id);
    }
  }

  SketchConstraint? get addedConstraint => _addedConstraint;

  String _constraintTypeName(SketchConstraintType type) {
    return switch (type) {
      SketchConstraintType.coincident => 'Coincident',
      SketchConstraintType.horizontal => 'Horizontal',
      SketchConstraintType.vertical => 'Vertical',
      SketchConstraintType.perpendicular => 'Perpendicular',
      SketchConstraintType.parallel => 'Parallel',
      SketchConstraintType.equalLength => 'Equal Length',
      SketchConstraintType.distance => 'Distance',
      SketchConstraintType.radius => 'Radius',
      SketchConstraintType.tangent => 'Tangent',
      SketchConstraintType.pointOnCurve => 'Point on Curve',
      SketchConstraintType.angle => 'Angle',
      SketchConstraintType.midpoint => 'Midpoint',
      SketchConstraintType.symmetric => 'Symmetric',
      SketchConstraintType.fixedPoint => 'Fixed Point',
    };
  }
}

/// Command for deleting an entity from the sketch.
class DeleteEntityCommand implements Command {
  final SketchStateNotifier _notifier;
  final String entityId;

  // Store deleted data for undo
  SketchPoint? _deletedPoint;
  SketchSegment? _deletedSegment;
  SketchCircle? _deletedCircle;
  SketchArc? _deletedArc;
  List<SketchConstraint> _deletedConstraints = [];

  DeleteEntityCommand(this._notifier, this.entityId);

  @override
  String get name => 'Delete';

  @override
  void execute() {
    // Store the entity before deleting
    _storeEntity();
    _notifier.deleteEntity(entityId);
  }

  @override
  void undo() {
    // Restore the entity
    if (_deletedPoint != null) {
      _notifier.addPoint(
        _deletedPoint!.position.x,
        _deletedPoint!.position.y,
        isFixed: _deletedPoint!.isFixed,
      );
    }
    // Note: Full restoration would require storing more state
    // This is a simplified implementation
  }

  void _storeEntity() {
    // Implementation would store the entity data
    // This is a placeholder
  }
}

/// Command for moving a point.
class MovePointCommand implements Command {
  final SketchStateNotifier _notifier;
  final String pointId;
  final double newX;
  final double newY;
  final double _oldX;
  final double _oldY;

  MovePointCommand(
    this._notifier, {
    required this.pointId,
    required this.newX,
    required this.newY,
    required double oldX,
    required double oldY,
  })  : _oldX = oldX,
        _oldY = oldY;

  @override
  String get name => 'Move Point';

  @override
  void execute() {
    _notifier.updatePointPosition(pointId, newX, newY);
  }

  @override
  void undo() {
    _notifier.updatePointPosition(pointId, _oldX, _oldY);
  }

  @override
  bool canMergeWith(Command other) {
    return other is MovePointCommand && other.pointId == pointId;
  }

  @override
  Command mergeWith(Command other) {
    if (other is MovePointCommand && other.pointId == pointId) {
      return MovePointCommand(
        _notifier,
        pointId: pointId,
        newX: other.newX,
        newY: other.newY,
        oldX: _oldX,
        oldY: _oldY,
      );
    }
    return this;
  }
}

/// Command for creating a line (two points + segment).
class CreateLineCommand implements Command {
  final SketchStateNotifier _notifier;
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  SketchPoint? _startPoint;
  SketchPoint? _endPoint;
  SketchSegment? _segment;

  CreateLineCommand(
    this._notifier, {
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  @override
  String get name => 'Create Line';

  @override
  void execute() {
    _startPoint = _notifier.addPoint(startX, startY);
    _endPoint = _notifier.addPoint(endX, endY);
    _segment = _notifier.addSegment(_startPoint!.id, _endPoint!.id);
  }

  @override
  void undo() {
    if (_segment != null) {
      _notifier.deleteEntity(_segment!.id);
    }
    if (_endPoint != null) {
      _notifier.deleteEntity(_endPoint!.id);
    }
    if (_startPoint != null) {
      _notifier.deleteEntity(_startPoint!.id);
    }
  }

  SketchSegment? get segment => _segment;
  SketchPoint? get startPoint => _startPoint;
  SketchPoint? get endPoint => _endPoint;
}

/// Command for creating a rectangle (four points + four segments).
class CreateRectangleCommand implements Command {
  final SketchStateNotifier _notifier;
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  final List<SketchPoint> _points = [];
  final List<SketchSegment> _segments = [];

  CreateRectangleCommand(
    this._notifier, {
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  @override
  String get name => 'Create Rectangle';

  @override
  void execute() {
    // Create four corner points
    final p1 = _notifier.addPoint(x1, y1);
    final p2 = _notifier.addPoint(x2, y1);
    final p3 = _notifier.addPoint(x2, y2);
    final p4 = _notifier.addPoint(x1, y2);

    _points.addAll([p1, p2, p3, p4]);

    // Create four edges
    _segments.add(_notifier.addSegment(p1.id, p2.id));
    _segments.add(_notifier.addSegment(p2.id, p3.id));
    _segments.add(_notifier.addSegment(p3.id, p4.id));
    _segments.add(_notifier.addSegment(p4.id, p1.id));
  }

  @override
  void undo() {
    for (final segment in _segments.reversed) {
      _notifier.deleteEntity(segment.id);
    }
    for (final point in _points.reversed) {
      _notifier.deleteEntity(point.id);
    }
    _segments.clear();
    _points.clear();
  }

  List<SketchPoint> get points => List.unmodifiable(_points);
  List<SketchSegment> get segments => List.unmodifiable(_segments);
}
