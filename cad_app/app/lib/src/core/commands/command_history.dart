import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'command.dart';

/// Manages undo/redo history for the application.
class CommandHistory {
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  final int _maxHistorySize;
  final Duration _mergeWindow;

  DateTime? _lastCommandTime;

  /// Creates a command history with optional size limit and merge window.
  ///
  /// [maxHistorySize] limits memory usage by capping history length.
  /// [mergeWindow] defines how long commands can be merged together.
  CommandHistory({
    int maxHistorySize = 100,
    Duration mergeWindow = const Duration(milliseconds: 500),
  })  : _maxHistorySize = maxHistorySize,
        _mergeWindow = mergeWindow;

  /// Whether there are commands that can be undone.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether there are commands that can be redone.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Number of commands in undo history.
  int get undoCount => _undoStack.length;

  /// Number of commands in redo history.
  int get redoCount => _redoStack.length;

  /// Name of the next command to undo, or null if none.
  String? get undoName => _undoStack.isNotEmpty ? _undoStack.last.name : null;

  /// Name of the next command to redo, or null if none.
  String? get redoName => _redoStack.isNotEmpty ? _redoStack.last.name : null;

  /// Execute a command and add it to history.
  void execute(Command command) {
    command.execute();
    _addToHistory(command);
  }

  /// Add an already-executed command to history.
  ///
  /// Use this when the command was executed outside of [execute].
  void recordCommand(Command command) {
    _addToHistory(command);
  }

  void _addToHistory(Command command) {
    final now = DateTime.now();

    // Try to merge with the last command if within merge window
    if (_undoStack.isNotEmpty &&
        _lastCommandTime != null &&
        now.difference(_lastCommandTime!) < _mergeWindow &&
        _undoStack.last.canMergeWith(command)) {
      _undoStack[_undoStack.length - 1] =
          _undoStack.last.mergeWith(command);
    } else {
      _undoStack.add(command);
    }

    _lastCommandTime = now;

    // Clear redo stack when new command is added
    _redoStack.clear();

    // Trim history if needed
    while (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }

  /// Undo the last command.
  ///
  /// Returns the command that was undone, or null if nothing to undo.
  Command? undo() {
    if (!canUndo) return null;

    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
    _lastCommandTime = null; // Reset merge window

    return command;
  }

  /// Redo the last undone command.
  ///
  /// Returns the command that was redone, or null if nothing to redo.
  Command? redo() {
    if (!canRedo) return null;

    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);
    _lastCommandTime = null; // Reset merge window

    return command;
  }

  /// Clear all history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _lastCommandTime = null;
  }

  /// Get a list of recent command names for display.
  List<String> getUndoHistory({int limit = 10}) {
    return _undoStack
        .reversed
        .take(limit)
        .map((c) => c.name)
        .toList();
  }

  /// Get a list of redo command names for display.
  List<String> getRedoHistory({int limit = 10}) {
    return _redoStack
        .reversed
        .take(limit)
        .map((c) => c.name)
        .toList();
  }
}

/// State for command history that can be watched.
class CommandHistoryState {
  final bool canUndo;
  final bool canRedo;
  final String? undoName;
  final String? redoName;
  final int undoCount;
  final int redoCount;

  const CommandHistoryState({
    required this.canUndo,
    required this.canRedo,
    this.undoName,
    this.redoName,
    required this.undoCount,
    required this.redoCount,
  });

  factory CommandHistoryState.from(CommandHistory history) {
    return CommandHistoryState(
      canUndo: history.canUndo,
      canRedo: history.canRedo,
      undoName: history.undoName,
      redoName: history.redoName,
      undoCount: history.undoCount,
      redoCount: history.redoCount,
    );
  }

  static const empty = CommandHistoryState(
    canUndo: false,
    canRedo: false,
    undoCount: 0,
    redoCount: 0,
  );
}

/// Notifier for command history state.
class CommandHistoryNotifier extends StateNotifier<CommandHistoryState> {
  final CommandHistory _history;

  CommandHistoryNotifier({CommandHistory? history})
      : _history = history ?? CommandHistory(),
        super(CommandHistoryState.empty);

  CommandHistory get history => _history;

  /// Execute a command and update state.
  void execute(Command command) {
    _history.execute(command);
    _updateState();
  }

  /// Record a command without executing it.
  void record(Command command) {
    _history.recordCommand(command);
    _updateState();
  }

  /// Undo the last command.
  bool undo() {
    final result = _history.undo();
    _updateState();
    return result != null;
  }

  /// Redo the last undone command.
  bool redo() {
    final result = _history.redo();
    _updateState();
    return result != null;
  }

  /// Clear all history.
  void clear() {
    _history.clear();
    _updateState();
  }

  void _updateState() {
    state = CommandHistoryState.from(_history);
  }
}

/// Provider for command history.
final commandHistoryProvider =
    StateNotifierProvider<CommandHistoryNotifier, CommandHistoryState>((ref) {
  return CommandHistoryNotifier();
});
