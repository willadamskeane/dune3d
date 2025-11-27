import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cad_app/src/app.dart';

void main() {
  group('CadApp', () {
    testWidgets('app starts without error', (WidgetTester tester) async {
      await tester.pumpWidget(const CadApp());
      await tester.pumpAndSettle();

      // App should render without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('shows project selector on start', (WidgetTester tester) async {
      await tester.pumpWidget(const CadApp());
      await tester.pumpAndSettle();

      // Should show Projects title
      expect(find.text('Projects'), findsOneWidget);
    });

    testWidgets('has settings button', (WidgetTester tester) async {
      await tester.pumpWidget(const CadApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('has new project FAB', (WidgetTester tester) async {
      await tester.pumpWidget(const CadApp());
      await tester.pumpAndSettle();

      expect(find.text('New Project'), findsOneWidget);
    });
  });
}
