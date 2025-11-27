import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'geometry.dart';
import 'entities.dart';
import 'constraints.dart';

/// A sketch document containing entities and constraints
class SketchDocument extends ChangeNotifier {
  String name;
  final Map<EntityId, SketchEntity> _entities = {};
  final Map<ConstraintId, Constraint> _constraints = {};
  int _entityCounter = 0;
  int _constraintCounter = 0;

  // Selection state
  final Set<EntityId> _selectedEntityIds = {};

  // Undo/Redo
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  static const int _maxUndoSize = 50;

  SketchDocument({this.name = 'Untitled Sketch'});

  // Getters
  Iterable<SketchEntity> get entities => _entities.values;
  Iterable<Constraint> get constraints => _constraints.values;
  int get entityCount => _entities.length;
  int get constraintCount => _constraints.length;

  Set<EntityId> get selectedEntityIds => Set.unmodifiable(_selectedEntityIds);
  List<SketchEntity> get selectedEntities =>
      _selectedEntityIds.map((id) => _entities[id]!).toList();

  bool get hasSelection => _selectedEntityIds.isNotEmpty;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Get entity by ID
  SketchEntity? getEntity(EntityId id) => _entities[id];

  /// Get constraint by ID
  Constraint? getConstraint(ConstraintId id) => _constraints[id];

  /// Generate a unique entity ID
  EntityId _generateEntityId() => 'e${++_entityCounter}';

  /// Generate a unique constraint ID
  ConstraintId _generateConstraintId() => 'c${++_constraintCounter}';

  /// Save state for undo
  void _saveState() {
    _undoStack.add(toJson());
    if (_undoStack.length > _maxUndoSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Undo the last operation
  void undo() {
    if (_undoStack.isEmpty) return;

    _redoStack.add(toJson());
    final state = _undoStack.removeLast();
    _loadState(state);
    notifyListeners();
  }

  /// Redo the last undone operation
  void redo() {
    if (_redoStack.isEmpty) return;

    _undoStack.add(toJson());
    final state = _redoStack.removeLast();
    _loadState(state);
    notifyListeners();
  }

  void _loadState(String jsonStr) {
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    _entities.clear();
    _constraints.clear();
    _selectedEntityIds.clear();

    name = json['name'] as String? ?? 'Untitled';
    _entityCounter = json['entityCounter'] as int? ?? 0;
    _constraintCounter = json['constraintCounter'] as int? ?? 0;

    final entitiesJson = json['entities'] as List? ?? [];
    for (final e in entitiesJson) {
      final entity = EntityFactory.fromJson(e as Map<String, dynamic>);
      _entities[entity.id] = entity;
    }

    final constraintsJson = json['constraints'] as List? ?? [];
    for (final c in constraintsJson) {
      final constraint = ConstraintFactory.fromJson(c as Map<String, dynamic>);
      _constraints[constraint.id] = constraint;
    }
  }

  // Entity operations

  /// Add a point entity
  PointEntity addPoint(Vec2 position) {
    _saveState();
    final entity = PointEntity(id: _generateEntityId(), position: position);
    _entities[entity.id] = entity;
    notifyListeners();
    return entity;
  }

  /// Add a line entity
  LineEntity addLine(Vec2 start, Vec2 end) {
    _saveState();
    final entity = LineEntity(id: _generateEntityId(), start: start, end: end);
    _entities[entity.id] = entity;
    notifyListeners();
    return entity;
  }

  /// Add a circle entity
  CircleEntity addCircle(Vec2 center, double radius) {
    _saveState();
    final entity =
        CircleEntity(id: _generateEntityId(), center: center, radius: radius);
    _entities[entity.id] = entity;
    notifyListeners();
    return entity;
  }

  /// Add an arc entity
  ArcEntity addArc(
      Vec2 center, double radius, double startAngle, double sweepAngle) {
    _saveState();
    final entity = ArcEntity(
      id: _generateEntityId(),
      center: center,
      radius: radius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );
    _entities[entity.id] = entity;
    notifyListeners();
    return entity;
  }

  /// Add a rectangle entity
  RectangleEntity addRectangle(Vec2 corner1, Vec2 corner2) {
    _saveState();
    final entity =
        RectangleEntity(id: _generateEntityId(), corner1: corner1, corner2: corner2);
    _entities[entity.id] = entity;
    notifyListeners();
    return entity;
  }

  /// Remove an entity
  void removeEntity(EntityId id) {
    if (!_entities.containsKey(id)) return;

    _saveState();
    _entities.remove(id);
    _selectedEntityIds.remove(id);

    // Remove constraints referencing this entity
    _constraints.removeWhere((_, c) => c.entityIds.contains(id));

    notifyListeners();
  }

  /// Remove selected entities
  void removeSelectedEntities() {
    if (_selectedEntityIds.isEmpty) return;

    _saveState();
    for (final id in _selectedEntityIds.toList()) {
      _entities.remove(id);
      _constraints.removeWhere((_, c) => c.entityIds.contains(id));
    }
    _selectedEntityIds.clear();
    notifyListeners();
  }

  /// Move an entity
  void moveEntity(EntityId id, Vec2 delta) {
    final entity = _entities[id];
    if (entity == null) return;

    entity.translate(delta);
    notifyListeners();
  }

  /// Move selected entities
  void moveSelectedEntities(Vec2 delta) {
    for (final id in _selectedEntityIds) {
      _entities[id]?.translate(delta);
    }
    notifyListeners();
  }

  /// Save state before starting a drag operation
  void beginDrag() {
    _saveState();
  }

  // Selection operations

  /// Select an entity
  void selectEntity(EntityId id, {bool addToSelection = false}) {
    if (!addToSelection) {
      for (final e in _entities.values) {
        e.isSelected = false;
      }
      _selectedEntityIds.clear();
    }

    final entity = _entities[id];
    if (entity != null) {
      entity.isSelected = true;
      _selectedEntityIds.add(id);
    }
    notifyListeners();
  }

  /// Deselect an entity
  void deselectEntity(EntityId id) {
    final entity = _entities[id];
    if (entity != null) {
      entity.isSelected = false;
      _selectedEntityIds.remove(id);
    }
    notifyListeners();
  }

  /// Toggle entity selection
  void toggleEntitySelection(EntityId id) {
    final entity = _entities[id];
    if (entity != null) {
      entity.isSelected = !entity.isSelected;
      if (entity.isSelected) {
        _selectedEntityIds.add(id);
      } else {
        _selectedEntityIds.remove(id);
      }
    }
    notifyListeners();
  }

  /// Clear all selections
  void clearSelection() {
    for (final e in _entities.values) {
      e.isSelected = false;
    }
    _selectedEntityIds.clear();
    notifyListeners();
  }

  /// Select entities within a bounding box
  void selectInBox(BoundingBox box) {
    for (final entity in _entities.values) {
      if (box.intersects(entity.boundingBox)) {
        entity.isSelected = true;
        _selectedEntityIds.add(entity.id);
      }
    }
    notifyListeners();
  }

  /// Select all entities
  void selectAll() {
    for (final entity in _entities.values) {
      entity.isSelected = true;
      _selectedEntityIds.add(entity.id);
    }
    notifyListeners();
  }

  /// Find entity at a point (for hit testing)
  SketchEntity? findEntityAt(Vec2 point, double tolerance) {
    SketchEntity? closest;
    double minDist = tolerance;

    for (final entity in _entities.values) {
      final dist = entity.distanceToPoint(point);
      if (dist < minDist) {
        minDist = dist;
        closest = entity;
      }
    }

    return closest;
  }

  // Constraint operations

  /// Add a horizontal constraint
  HorizontalConstraint addHorizontalConstraint(EntityId lineId) {
    _saveState();
    final constraint =
        HorizontalConstraint(id: _generateConstraintId(), lineId: lineId);
    _constraints[constraint.id] = constraint;
    notifyListeners();
    return constraint;
  }

  /// Add a vertical constraint
  VerticalConstraint addVerticalConstraint(EntityId lineId) {
    _saveState();
    final constraint =
        VerticalConstraint(id: _generateConstraintId(), lineId: lineId);
    _constraints[constraint.id] = constraint;
    notifyListeners();
    return constraint;
  }

  /// Add a distance constraint
  DistanceConstraint addDistanceConstraint(
      List<EntityId> entityIds, double distance) {
    _saveState();
    final constraint = DistanceConstraint(
      id: _generateConstraintId(),
      entityIds: entityIds,
      distance: distance,
    );
    _constraints[constraint.id] = constraint;
    notifyListeners();
    return constraint;
  }

  /// Add a radius constraint
  RadiusConstraint addRadiusConstraint(EntityId circleId, double radius) {
    _saveState();
    final constraint = RadiusConstraint(
      id: _generateConstraintId(),
      circleId: circleId,
      radius: radius,
    );
    _constraints[constraint.id] = constraint;
    notifyListeners();
    return constraint;
  }

  /// Add an angle constraint
  AngleConstraint addAngleConstraint(
      List<EntityId> entityIds, double angleDegrees) {
    _saveState();
    final constraint = AngleConstraint(
      id: _generateConstraintId(),
      entityIds: entityIds,
      angleDegrees: angleDegrees,
    );
    _constraints[constraint.id] = constraint;
    notifyListeners();
    return constraint;
  }

  /// Add a coincident constraint
  CoincidentConstraint addCoincidentConstraint(
    EntityId entity1Id,
    EntityId entity2Id, {
    int point1Index = 0,
    int point2Index = 0,
  }) {
    _saveState();
    final constraint = CoincidentConstraint(
      id: _generateConstraintId(),
      entity1Id: entity1Id,
      entity2Id: entity2Id,
      point1Index: point1Index,
      point2Index: point2Index,
    );
    _constraints[constraint.id] = constraint;
    notifyListeners();
    return constraint;
  }

  /// Add a parallel constraint
  ParallelConstraint addParallelConstraint(EntityId line1Id, EntityId line2Id) {
    _saveState();
    final constraint = ParallelConstraint(
      id: _generateConstraintId(),
      line1Id: line1Id,
      line2Id: line2Id,
    );
    _constraints[constraint.id] = constraint;
    notifyListeners();
    return constraint;
  }

  /// Add a perpendicular constraint
  PerpendicularConstraint addPerpendicularConstraint(
      EntityId line1Id, EntityId line2Id) {
    _saveState();
    final constraint = PerpendicularConstraint(
      id: _generateConstraintId(),
      line1Id: line1Id,
      line2Id: line2Id,
    );
    _constraints[constraint.id] = constraint;
    notifyListeners();
    return constraint;
  }

  /// Add an equal constraint
  EqualConstraint addEqualConstraint(EntityId entity1Id, EntityId entity2Id) {
    _saveState();
    final constraint = EqualConstraint(
      id: _generateConstraintId(),
      entity1Id: entity1Id,
      entity2Id: entity2Id,
    );
    _constraints[constraint.id] = constraint;
    notifyListeners();
    return constraint;
  }

  /// Remove a constraint
  void removeConstraint(ConstraintId id) {
    if (!_constraints.containsKey(id)) return;

    _saveState();
    _constraints.remove(id);
    notifyListeners();
  }

  /// Check all constraints and update their satisfied status
  void validateConstraints() {
    for (final constraint in _constraints.values) {
      constraint.isSatisfied = constraint.check(_entities);
    }
    notifyListeners();
  }

  // Serialization

  /// Serialize to JSON string
  String toJson() {
    final json = {
      'name': name,
      'entityCounter': _entityCounter,
      'constraintCounter': _constraintCounter,
      'entities': _entities.values.map((e) => e.toJson()).toList(),
      'constraints': _constraints.values.map((c) => c.toJson()).toList(),
    };
    return jsonEncode(json);
  }

  /// Load from JSON string
  factory SketchDocument.fromJson(String jsonStr) {
    final doc = SketchDocument();
    doc._loadState(jsonStr);
    return doc;
  }

  /// Clear the document
  void clear() {
    _saveState();
    _entities.clear();
    _constraints.clear();
    _selectedEntityIds.clear();
    _entityCounter = 0;
    _constraintCounter = 0;
    notifyListeners();
  }
}
