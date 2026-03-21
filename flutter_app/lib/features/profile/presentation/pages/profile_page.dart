import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showComingSoon(BuildContext context, String title) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                const Text(
                  'This screen is kept as frontend stub and will be connected with backend data later.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent ? const Color(0xFFCCFBF1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: accent ? AppColors.primaryDark : AppColors.textSecondary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentRoute: AppRouter.profile),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF06B6D4)],
              ),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text('👤', style: TextStyle(fontSize: 28)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PetFit Member',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Set up your account details',
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(height: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x44FFFFFF),
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            'Account Ready',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '12',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text('Orders'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '28',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text('Favorites'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '3',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text('Reviews'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  _menuTile(
                    context,
                    title: 'Edit Profile',
                    icon: Icons.person_outline_rounded,
                    accent: true,
                    onTap: () => _showComingSoon(context, 'Edit Profile'),
                  ),
                  _menuTile(
                    context,
                    title: 'Addresses',
                    icon: Icons.location_on_outlined,
                    accent: true,
                    onTap: () => _showComingSoon(context, 'Addresses'),
                  ),
                  _menuTile(
                    context,
                    title: 'Payment Methods',
                    icon: Icons.credit_card_outlined,
                    accent: true,
                    onTap: () => _showComingSoon(context, 'Payment Methods'),
                  ),
                  _menuTile(
                    context,
                    title: 'Notifications',
                    icon: Icons.notifications_none_rounded,
                    accent: true,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.notifications),
                  ),
                  _menuTile(
                    context,
                    title: 'My Closet',
                    icon: Icons.checkroom_outlined,
                    accent: true,
                    onTap: () => Navigator.pushNamed(context, AppRouter.closet),
                  ),
                  _menuTile(
                    context,
                    title: 'Saved Looks',
                    icon: Icons.bookmarks_outlined,
                    accent: true,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.savedLooks),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  _menuTile(
                    context,
                    title: 'Help Center',
                    icon: Icons.help_outline_rounded,
                    onTap: () => _showComingSoon(context, 'Help Center'),
                  ),
                  _menuTile(
                    context,
                    title: 'Privacy Policy',
                    icon: Icons.verified_user_outlined,
                    onTap: () => _showComingSoon(context, 'Privacy Policy'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.splash,
                (route) => false,
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log Out'),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('PetFit AI v1.0.0', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
