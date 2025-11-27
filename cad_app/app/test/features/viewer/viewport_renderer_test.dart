import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cad_app/src/features/viewer/presentation/viewport_renderer.dart';
import 'package:cad_app/src/features/viewer/domain/mesh_model.dart';
import 'package:cad_app/src/features/viewer/domain/camera_model.dart';

void main() {
  group('RenderMode', () {
    test('has expected values', () {
      expect(RenderMode.values, contains(RenderMode.wireframe));
      expect(RenderMode.values, contains(RenderMode.solid));
      expect(RenderMode.values, contains(RenderMode.solidWithEdges));
    });
  });

  group('ViewportRenderer', () {
    late CameraModel camera;

    setUp(() {
      camera = CameraModel.defaultCamera();
    });

    testWidgets('render does not throw with empty mesh list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: _TestPainter(
                onPaint: (canvas, size) {
                  // Should not throw
                  expect(
                    () => ViewportRenderer.render(
                      canvas: canvas,
                      size: size,
                      meshes: const [],
                      camera: camera,
                      mode: RenderMode.solid,
                    ),
                    returnsNormally,
                  );
                },
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('render does not throw with cube mesh',
        (WidgetTester tester) async {
      final mesh = Mesh.cube('test_cube', size: 2.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: _TestPainter(
                onPaint: (canvas, size) {
                  expect(
                    () => ViewportRenderer.render(
                      canvas: canvas,
                      size: size,
                      meshes: [mesh],
                      camera: camera,
                      mode: RenderMode.solidWithEdges,
                    ),
                    returnsNormally,
                  );
                },
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('drawGroundGrid does not throw', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: _TestPainter(
                onPaint: (canvas, size) {
                  final vpMatrix = camera.projectionMatrix(size.width / size.height) *
                      camera.viewMatrix;

                  expect(
                    () => ViewportRenderer.drawGroundGrid(
                      canvas,
                      size,
                      vpMatrix,
                    ),
                    returnsNormally,
                  );
                },
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('renders with all render modes', (WidgetTester tester) async {
      final mesh = Mesh.cube('test', size: 1.0);

      for (final mode in RenderMode.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: _TestPainter(
                  onPaint: (canvas, size) {
                    expect(
                      () => ViewportRenderer.render(
                        canvas: canvas,
                        size: size,
                        meshes: [mesh],
                        camera: camera,
                        mode: mode,
                      ),
                      returnsNormally,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }
    });

    testWidgets('renders with selected mesh', (WidgetTester tester) async {
      final mesh = Mesh.cube('selected_mesh', size: 1.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: _TestPainter(
                onPaint: (canvas, size) {
                  expect(
                    () => ViewportRenderer.render(
                      canvas: canvas,
                      size: size,
                      meshes: [mesh],
                      camera: camera,
                      mode: RenderMode.solid,
                      selectedId: 'selected_mesh',
                    ),
                    returnsNormally,
                  );
                },
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('renders with hovered mesh', (WidgetTester tester) async {
      final mesh = Mesh.cube('hovered_mesh', size: 1.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: _TestPainter(
                onPaint: (canvas, size) {
                  expect(
                    () => ViewportRenderer.render(
                      canvas: canvas,
                      size: size,
                      meshes: [mesh],
                      camera: camera,
                      mode: RenderMode.solid,
                      hoveredId: 'hovered_mesh',
                    ),
                    returnsNormally,
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  });
}

class _TestPainter extends CustomPainter {
  final void Function(Canvas, Size) onPaint;

  _TestPainter({required this.onPaint});

  @override
  void paint(Canvas canvas, Size size) {
    onPaint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
