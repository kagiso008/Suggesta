import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../../shared/widgets/bouncing_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait a bit for the splash screen to show
    await Future.delayed(const Duration(milliseconds: 1500));

    final session = ref.read(currentSessionProvider);

    if (session == null) {
      // No session, go to welcome screen
      if (mounted) {
        context.go('/welcome');
      }
    } else {
      // Has session, check if profile is complete
      final user = ref.read(currentUserProvider);
      if (user != null) {
        // TODO: Check if profile is complete
        // For now, go to home
        if (mounted) {
          context.go('/home');
        }
      } else {
        if (mounted) {
          context.go('/welcome');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouncing app logo
            BouncingLogo(
              imagePath: 'assets/images/app_logo.png',
              width: 120,
              height: 120,
              bounceDuration: const Duration(milliseconds: 800),
              bounceHeight: 0.25,
              shadowColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha((0.3 * 255).round()),
              shadowBlurRadius: 20,
            ),
            const SizedBox(height: 32),
            // App name
            Text(
              'Suggesta',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'Share ideas. Vote. Decide.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
