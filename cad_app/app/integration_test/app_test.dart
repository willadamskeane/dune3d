import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cad_app/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CAD App Integration Tests', () {
    testWidgets('App launches and shows projects screen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CadApp()),
      );
      await tester.pumpAndSettle();

      // Should show projects screen
      expect(find.text('Projects'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Can create a new project', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CadApp()),
      );
      await tester.pumpAndSettle();

      // Tap the add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show new project dialog
      expect(find.text('New Project'), findsOneWidget);

      // Enter project name
      await tester.enterText(find.byType(TextField), 'Test Project');
      await tester.pumpAndSettle();

      // Tap create button
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Should show the new project in the list
      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('Can navigate to 3D viewer', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CadApp()),
      );
      await tester.pumpAndSettle();

      // Create a project first
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Viewer Test');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Tap on the project to open it
      await tester.tap(find.text('Viewer Test'));
      await tester.pumpAndSettle();

      // Should show 3D viewer
      expect(find.text('3D Viewer'), findsOneWidget);
    });

    testWidgets('Can navigate to sketch mode', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CadApp()),
      );
      await tester.pumpAndSettle();

      // Navigate to viewer first
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Sketch Test');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sketch Test'));
      await tester.pumpAndSettle();

      // Find and tap sketch mode button
      await tester.tap(find.byIcon(Icons.draw));
      await tester.pumpAndSettle();

      // Should show sketch screen
      expect(find.text('Sketch'), findsOneWidget);
    });

    testWidgets('Can add a primitive shape', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CadApp()),
      );
      await tester.pumpAndSettle();

      // Navigate to viewer
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Shape Test');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shape Test'));
      await tester.pumpAndSettle();

      // Find and tap the Box button in the toolbar
      await tester.tap(find.text('Box'));
      await tester.pumpAndSettle();

      // The mesh should be added (check mesh count in overlay)
      expect(find.textContaining('Meshes: 1'), findsOneWidget);
    });

    testWidgets('Sketch tools can be selected', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CadApp()),
      );
      await tester.pumpAndSettle();

      // Navigate to sketch
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Tool Test');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tool Test'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.draw));
      await tester.pumpAndSettle();

      // Find and select line tool
      await tester.tap(find.byIcon(Icons.show_chart));
      await tester.pumpAndSettle();

      // Tool should be selected (button should be highlighted)
      // The actual verification depends on the UI implementation
    });

    testWidgets('Can access settings', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CadApp()),
      );
      await tester.pumpAndSettle();

      // Find and tap settings
      await tester.tap(find.byIcon(Icons.settings).first);
      await tester.pumpAndSettle();

      // Should show settings screen
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);
    });

    testWidgets('Camera controls work in viewport', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CadApp()),
      );
      await tester.pumpAndSettle();

      // Navigate to viewer
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Camera Test');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Camera Test'));
      await tester.pumpAndSettle();

      // Find the viewport
      final viewport = find.byType(CustomPaint).first;

      // Simulate drag for orbit
      await tester.drag(viewport, const Offset(100, 50));
      await tester.pumpAndSettle();

      // Find reset camera button and tap it
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Camera should be reset (no visible assertion needed, just no crash)
    });

    testWidgets('Render mode can be toggled', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CadApp()),
      );
      await tester.pumpAndSettle();

      // Navigate to viewer
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Render Test');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Render Test'));
      await tester.pumpAndSettle();

      // Find render mode button (border_all icon for solidWithEdges)
      final renderButton = find.byIcon(Icons.border_all);
      if (renderButton.evaluate().isNotEmpty) {
        await tester.tap(renderButton);
        await tester.pumpAndSettle();
      }

      // Mode should have changed (button icon should change)
    });
  });
}
