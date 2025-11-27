# CAD App - Flutter Foundation

High-performance CAD application for Android tablets with stylus support.

## Project Structure

```
cad_app/
├── app/                          # Main Flutter application
│   ├── lib/
│   │   ├── main.dart            # App entry point
│   │   └── src/
│   │       ├── app.dart         # Root widget with providers
│   │       ├── core/            # Shared utilities
│   │       │   ├── logger.dart
│   │       │   ├── router/      # GoRouter configuration
│   │       │   └── theme/       # Material 3 theming
│   │       ├── features/        # Feature modules
│   │       │   ├── project/     # Project management
│   │       │   ├── viewer/      # 3D viewport
│   │       │   ├── sketch/      # 2D sketch editing
│   │       │   └── settings/    # App settings
│   │       └── services/        # Business logic
│   │           ├── kernel/      # OCCT bridge
│   │           ├── sketch/      # Constraint solver
│   │           └── input/       # Stylus input
│   ├── test/                    # Unit and widget tests
│   └── android/                 # Android-specific config
│
└── packages/
    ├── cad_kernel_plugin/       # FFI bindings for OCCT + ShapeOp
    │   ├── lib/src/
    │   │   ├── occt_bindings.dart
    │   │   ├── shapeop_bindings.dart
    │   │   └── ffi_helpers.dart
    │   └── android/
    │       ├── CMakeLists.txt
    │       └── src/main/cpp/    # Native C++ wrappers
    │
    └── cad_input_plugin/        # Raw stylus MotionEvent handling
        ├── lib/
        │   └── cad_input_plugin.dart
        └── android/
            └── src/main/kotlin/ # Kotlin platform code
```

## Getting Started

### Prerequisites

- Flutter SDK >= 3.22.0
- Dart SDK >= 3.4.0
- Android SDK with NDK
- For kernel plugin: OCCT and ShapeOp libraries

### Setup

1. Install dependencies:
```bash
cd app
flutter pub get
```

2. Run tests:
```bash
flutter test
```

3. Run the app:
```bash
flutter run
```

### Building for Release

```bash
flutter build apk --release
```

## Architecture

### State Management

Uses **Riverpod** for state management with:
- StateNotifierProvider for complex state
- StateProvider for simple values
- FutureProvider for async operations

### Navigation

Uses **GoRouter** for declarative routing:
- `/projects` - Project selection
- `/viewer` - 3D viewport
- `/sketch` - 2D sketch editor
- `/settings` - App settings

### Native Plugins

#### cad_kernel_plugin (FFI)

Provides Dart bindings to:
- **OCCT** (OpenCASCADE): B-rep modeling kernel
  - Primitives (box, cylinder, sphere)
  - Boolean operations (union, cut, intersect)
  - Feature operations (fillet, chamfer, extrude)
  - Tessellation for rendering

- **ShapeOp**: Geometric constraint solver
  - Point and segment constraints
  - Distance, horizontal, vertical constraints
  - Equal length constraints

#### cad_input_plugin (Platform Views)

Captures raw Android `MotionEvent` for:
- Stylus position (x, y)
- Pressure (0.0 - 1.0)
- Tilt angles
- Historical points for smooth strokes
- Stylus-only mode support

## Next Steps for Development

1. **Integrate OCCT**: Add actual OCCT libraries and implement C++ wrappers
2. **Implement flutter_gpu**: Replace viewport placeholder with GPU rendering
3. **Connect stylus input**: Wire platform view to sketch canvas
4. **Persistent storage**: Implement file-based project repository
5. **Export formats**: Add STEP, STL, OBJ export

## Testing

Run all tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
```

## License

See LICENSE file in the root directory.
