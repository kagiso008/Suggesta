import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/setup_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/topics/presentation/screens/home_feed_screen.dart';
import '../../features/topics/presentation/screens/topic_detail_screen.dart';
import '../../features/topics/presentation/screens/create_topic_screen.dart';
import '../../features/topics/presentation/screens/search_screen.dart';
import '../../features/trending/presentation/screens/trending_screen.dart';
import '../../features/chat/presentation/screens/chat_inbox_screen.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../shared/widgets/bottom_nav.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/setup-profile',
        name: 'setup-profile',
        builder: (context, state) => const SetupProfileScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child);
        },
        routes: [
          // Home feed
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeFeedScreen(),
            routes: [
              // Nested routes under home
              GoRoute(
                path: 'feed',
                name: 'feed',
                builder: (context, state) => const HomeFeedScreen(),
              ),
              GoRoute(
                path: 'trending',
                name: 'trending',
                builder: (context, state) => const TrendingScreen(),
              ),
              GoRoute(
                path: 'create',
                name: 'create',
                builder: (context, state) => const CreateTopicScreen(),
              ),
              GoRoute(
                path: 'chats',
                name: 'chats',
                builder: (context, state) => const ChatInboxScreen(),
                routes: [
                  GoRoute(
                    path: ':conversationId',
                    name: 'chat-room',
                    builder: (context, state) {
                      final conversationId =
                          state.pathParameters['conversationId']!;
                      return ChatRoomScreen(conversationId: conversationId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (context, state) {
                  final userId = state.uri.queryParameters['userId'];
                  return ProfileScreen(userId: userId);
                },
              ),
            ],
          ),
        ],
      ),

      // Standalone routes (no bottom nav)
      GoRoute(
        path: '/topic/:topicId',
        name: 'topic-detail',
        builder: (context, state) {
          final topicId = state.pathParameters['topicId']!;
          return TopicDetailScreen(topicId: topicId);
        },
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'profile-detail',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    redirect: (context, state) {
      // TODO: Add authentication redirect logic
      // For now, just allow all routes
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
