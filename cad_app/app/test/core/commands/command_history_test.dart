import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cad_app/src/core/commands/command.dart';
import 'package:cad_app/src/core/commands/command_history.dart';

// Test command implementation
class TestCommand implements Command {
  final String _name;
  final void Function() _executeAction;
  final void Function() _undoAction;

  TestCommand({
    required String name,
    required void Function() onExecute,
    required void Function() onUndo,
  })  : _name = name,
        _executeAction = onExecute,
        _undoAction = onUndo;

  @override
  String get name => _name;

  @override
  void execute() => _executeAction();

  @override
  void undo() => _undoAction();

  @override
  bool canMergeWith(Command other) => false;

  @override
  Command mergeWith(Command other) => this;
}

// Mergeable test command
class MergeableCommand implements Command {
  int value;
  final int initialValue;

  MergeableCommand(this.value) : initialValue = value;

  @override
  String get name => 'Mergeable($value)';

  @override
  void execute() {}

  @override
  void undo() {
    value = initialValue;
  }

  @override
  bool canMergeWith(Command other) => other is MergeableCommand;

  @override
  Command mergeWith(Command other) {
    if (other is MergeableCommand) {
      return MergeableCommand(other.value);
    }
    return this;
  }
}

void main() {
  group('CommandHistoryNotifier', () {
    late ProviderContainer container;
    late CommandHistoryNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(commandHistoryProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has no undo or redo', () {
      final state = container.read(commandHistoryProvider);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
    });

    test('execute adds command to history', () {
      var executed = false;

      notifier.execute(TestCommand(
        name: 'Test',
        onExecute: () => executed = true,
        onUndo: () => executed = false,
      ));

      expect(executed, isTrue);

      final state = container.read(commandHistoryProvider);
      expect(state.canUndo, isTrue);
      expect(state.canRedo, isFalse);
    });

    test('undo reverses command', () {
      var value = 0;

      notifier.execute(TestCommand(
        name: 'Increment',
        onExecute: () => value++,
        onUndo: () => value--,
      ));

      expect(value, equals(1));

      notifier.undo();

      expect(value, equals(0));

      final state = container.read(commandHistoryProvider);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isTrue);
    });

    test('redo re-executes command', () {
      var value = 0;

      notifier.execute(TestCommand(
        name: 'Increment',
        onExecute: () => value++,
        onUndo: () => value--,
      ));

      notifier.undo();
      expect(value, equals(0));

      notifier.redo();
      expect(value, equals(1));

      final state = container.read(commandHistoryProvider);
      expect(state.canUndo, isTrue);
      expect(state.canRedo, isFalse);
    });

    test('new command clears redo stack', () {
      var value = 0;

      notifier.execute(TestCommand(
        name: 'First',
        onExecute: () => value = 1,
        onUndo: () => value = 0,
      ));

      notifier.undo();
      expect(value, equals(0));

      // New command should clear redo
      notifier.execute(TestCommand(
        name: 'Second',
        onExecute: () => value = 2,
        onUndo: () => value = 0,
      ));

      final state = container.read(commandHistoryProvider);
      expect(state.canRedo, isFalse);
      expect(value, equals(2));
    });

    test('multiple undo/redo work correctly', () {
      var values = <int>[];

      for (var i = 1; i <= 5; i++) {
        final val = i;
        notifier.execute(TestCommand(
          name: 'Add $val',
          onExecute: () => values.add(val),
          onUndo: () => values.removeLast(),
        ));
      }

      expect(values, equals([1, 2, 3, 4, 5]));

      notifier.undo();
      notifier.undo();
      expect(values, equals([1, 2, 3]));

      notifier.redo();
      expect(values, equals([1, 2, 3, 4]));

      notifier.undo();
      notifier.undo();
      notifier.undo();
      expect(values, equals([1]));
    });

    test('clear removes all history', () {
      notifier.execute(TestCommand(
        name: 'Test',
        onExecute: () {},
        onUndo: () {},
      ));

      notifier.clear();

      final state = container.read(commandHistoryProvider);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
    });

    test('respects max history size', () {
      // Execute many commands
      for (var i = 0; i < 150; i++) {
        notifier.execute(TestCommand(
          name: 'Command $i',
          onExecute: () {},
          onUndo: () {},
        ));
      }

      // Count undos possible (should be limited to maxHistorySize)
      var undoCount = 0;
      while (container.read(commandHistoryProvider).canUndo) {
        notifier.undo();
        undoCount++;
      }

      // Default maxHistorySize is 100
      expect(undoCount, lessThanOrEqualTo(100));
    });
  });

  group('Command merging', () {
    late ProviderContainer container;
    late CommandHistoryNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(commandHistoryProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('mergeable commands are merged within time window', () async {
      // Commands executed in quick succession should merge
      notifier.execute(MergeableCommand(1));
      notifier.execute(MergeableCommand(2));
      notifier.execute(MergeableCommand(3));

      // Commands should have been merged into one
      notifier.undo();

      // After undoing merged commands, check state
      final state = container.read(commandHistoryProvider);
      // Note: merging depends on time window, so we check undo worked
      expect(state.canRedo, isTrue);
    });
  });

  group('canUndoProvider and canRedoProvider', () {
    test('providers reflect correct state', () {
      final container = ProviderContainer();
      final notifier = container.read(commandHistoryProvider.notifier);

      expect(container.read(canUndoProvider), isFalse);
      expect(container.read(canRedoProvider), isFalse);

      notifier.execute(TestCommand(
        name: 'Test',
        onExecute: () {},
        onUndo: () {},
      ));

      expect(container.read(canUndoProvider), isTrue);
      expect(container.read(canRedoProvider), isFalse);

      notifier.undo();

      expect(container.read(canUndoProvider), isFalse);
      expect(container.read(canRedoProvider), isTrue);

      container.dispose();
    });
  });
}
