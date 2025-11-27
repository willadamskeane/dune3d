import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/project/presentation/project_selector_screen.dart';
import '../../features/viewer/presentation/viewer_screen.dart';
import '../../features/sketch/presentation/sketch_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/projects',
    routes: [
      GoRoute(
        path: '/projects',
        name: 'projects',
        builder: (context, state) => const ProjectSelectorScreen(),
      ),
      GoRoute(
        path: '/viewer',
        name: 'viewer',
        builder: (context, state) => const ViewerScreen(),
      ),
      GoRoute(
        path: '/sketch',
        name: 'sketch',
        builder: (context, state) => const SketchScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
