import 'package:flutter/material.dart';

import '../../app/router/app_router.dart';
import '../../app/theme/app_tokens.dart';
import 'app_bottom_nav.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    required this.title,
    required this.description,
    this.currentRoute,
    this.showBackButton = true,
    super.key,
  });

  final String title;
  final String description;
  final String? currentRoute;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        title: Text(title),
      ),
      bottomNavigationBar: currentRoute == null
          ? null
          : AppBottomNav(currentRoute: currentRoute!),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    size: 42,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '$title is coming soon',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(description, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRouter.home, (route) => false),
                  child: const Text('Back To Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
