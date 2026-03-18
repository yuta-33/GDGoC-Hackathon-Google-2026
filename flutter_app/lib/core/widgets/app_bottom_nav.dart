import 'package:flutter/material.dart';

import '../../app/router/app_router.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      const _NavItem(
        label: 'Home',
        icon: Icons.home_rounded,
        route: AppRouter.home,
      ),
      const _NavItem(
        label: 'Shop',
        icon: Icons.shopping_bag_rounded,
        route: AppRouter.shop,
      ),
      const _NavItem(
        label: 'Try-On',
        icon: Icons.auto_awesome_rounded,
        route: AppRouter.tryOn,
      ),
      const _NavItem(
        label: 'Pets',
        icon: Icons.pets_rounded,
        route: AppRouter.pets,
      ),
      const _NavItem(
        label: 'Profile',
        icon: Icons.person_rounded,
        route: AppRouter.profile,
      ),
    ];

    final index = items.indexWhere((item) => item.route == currentRoute);

    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (selected) {
        final route = items[selected].route;
        if (route == currentRoute) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacementNamed(route);
        });
      },
      destinations: [
        for (final item in items)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
