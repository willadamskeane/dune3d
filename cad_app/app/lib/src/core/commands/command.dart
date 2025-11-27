/// Base interface for undoable commands.
///
/// All operations that should be undoable must implement this interface.
abstract class Command {
  /// Human-readable name for this command (shown in UI).
  String get name;

  /// Execute the command.
  void execute();

  /// Undo the command, restoring previous state.
  void undo();

  /// Whether this command can be merged with another of the same type.
  ///
  /// Used for operations like dragging where multiple updates can be combined.
  bool canMergeWith(Command other) => false;

  /// Merge this command with another, returning the combined command.
  ///
  /// Only called if [canMergeWith] returns true.
  Command mergeWith(Command other) => this;
}

/// A command that groups multiple commands together.
class CompositeCommand implements Command {
  final List<Command> _commands;
  final String _name;

  CompositeCommand(this._commands, {String? name})
      : _name = name ?? 'Multiple Operations';

  @override
  String get name => _name;

  @override
  void execute() {
    for (final command in _commands) {
      command.execute();
    }
  }

  @override
  void undo() {
    // Undo in reverse order
    for (final command in _commands.reversed) {
      command.undo();
    }
  }

  @override
  bool canMergeWith(Command other) => false;

  @override
  Command mergeWith(Command other) => this;
}

/// A command that does nothing (useful as a placeholder).
class NoOpCommand implements Command {
  @override
  String get name => 'No Operation';

  @override
  void execute() {}

  @override
  void undo() {}

  @override
  bool canMergeWith(Command other) => other is NoOpCommand;

  @override
  Command mergeWith(Command other) => this;
}
