import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/application/demo_state_provider.dart';
import '../../../../core/models/demo_state.dart';
import '../../../../core/widgets/app_async_state_view.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../catalog/application/catalog_providers.dart';
import '../../../catalog/presentation/widgets/product_grid_card.dart';
import '../../../pet_profile/application/pet_profile_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Chip(label: Text('Newest')),
                    Chip(label: Text('Popular')),
                    Chip(label: Text('Sale')),
                    Chip(label: Text('Outerwear')),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final brands = ref.watch(brandsProvider);
    final filtered = ref.watch(homeProductsProvider);
    final featured = ref.watch(featuredProductProvider);
    final tab = ref.watch(homeTabProvider);
    final pet = ref.watch(petProfileProvider);
    final hasPetName = pet.name.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: const AppBottomNav(currentRoute: AppRouter.home),
      body: SafeArea(
        child: AppAsyncStateView(
          value: products,
          onRetry: () => ref.invalidate(productsProvider),
          data: (_) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: Color(0xFFF59E0B),
                                child: Text(
                                  '🐕',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Good morning'),
                                    Text(
                                      hasPetName
                                          ? '${pet.name} & family'
                                          : 'Welcome to PetFit',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Stack(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.notifications,
                                    ),
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                    ),
                                  ),
                                  const Positioned(
                                    right: 10,
                                    top: 10,
                                    child: CircleAvatar(
                                      radius: 4,
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<DemoState>(
                                icon: const Icon(Icons.tune_rounded),
                                onSelected: (state) =>
                                    ref.read(demoStateProvider.notifier).state =
                                        state,
                                itemBuilder: (context) => DemoState.values
                                    .map(
                                      (state) => PopupMenuItem(
                                        value: state,
                                        child: Text(state.name),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  readOnly: true,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRouter.search,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Search luxury pet fashion',
                                    prefixIcon: Icon(Icons.search_rounded),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showFilterSheet(context),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.m,
                                ),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.m,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.tune_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (featured != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Text(
                                        'AI MATCH 98%',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      featured.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hasPetName
                                          ? 'Tailored for ${pet.name}\'s size and coat'
                                          : 'AI-picked style based on your saved pet profile',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.textPrimary,
                                      ),
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        AppRouter.tryOn,
                                      ),
                                      child: const Text('View Fit'),
                                    ),
                                  ],
                                ),
                              ),
                              AppNetworkImage(
                                imageUrl: featured.image,
                                width: 110,
                                height: 110,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trending Brands',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRouter.shop,
                          ),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 106,
                    child: AppAsyncStateView(
                      value: brands,
                      data: (items) => ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final brand = items[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.brand,
                              arguments: {'brandId': brand.id},
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: brand.color,
                                  child: Text(
                                    brand.logo,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  brand.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 14),
                        itemCount: items.length,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        const Text(
                          'Trending Outfits',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        SegmentedButton<String>(
                          selected: {tab},
                          onSelectionChanged: (set) =>
                              ref.read(homeTabProvider.notifier).state =
                                  set.first,
                          segments: const [
                            ButtonSegment(
                              value: 'newest',
                              label: Text('Newest'),
                            ),
                            ButtonSegment(
                              value: 'popular',
                              label: Text('Popular'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      title: 'No products in this tab',
                      description: 'Switch tab or set DemoState to normal.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid.builder(
                      itemCount: filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return ProductGridCard(
                          product: product,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.productDetail,
                            arguments: {'productId': product.id},
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
