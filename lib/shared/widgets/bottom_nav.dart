import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithBottomNav extends StatefulWidget {
  final Widget child;

  const ScaffoldWithBottomNav({super.key, required this.child});

  @override
  State<ScaffoldWithBottomNav> createState() => _ScaffoldWithBottomNavState();
}

class _ScaffoldWithBottomNavState extends State<ScaffoldWithBottomNav> {
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    // Find the first route that matches the start of the location
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) {
        return i;
      }
    }
    return 0;
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.local_fire_department_outlined),
      activeIcon: Icon(Icons.local_fire_department),
      label: 'Trending',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_outlined),
      activeIcon: Icon(Icons.chat),
      label: 'Chats',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  final List<String> _routes = [
    '/home/feed',
    '/home/trending',
    '/home/chats',
    '/home/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // Always replace the stack for smooth tab navigation
          context.go(_routes[index]);
        },
        items: _navItems,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}
