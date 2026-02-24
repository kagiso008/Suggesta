import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class SuggestaApp extends ConsumerStatefulWidget {
  const SuggestaApp({super.key});

  @override
  ConsumerState<SuggestaApp> createState() => _SuggestaAppState();
}

class _SuggestaAppState extends ConsumerState<SuggestaApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = ref.read(routerProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Suggesta',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
