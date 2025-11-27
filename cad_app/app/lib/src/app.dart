import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class CadApp extends StatelessWidget {
  const CadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: const _CadAppContent(),
    );
  }
}

class _CadAppContent extends ConsumerWidget {
  const _CadAppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'CAD App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
