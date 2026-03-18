import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/app_async_state_view.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../catalog/application/catalog_providers.dart';
import '../../../catalog/presentation/widgets/product_grid_card.dart';

class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  static const _categories = <String>[
    'all',
    'Outerwear',
    'Knitwear',
    'Casual',
    'Formal',
    'Accessories',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filtered = ref.watch(shopProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      bottomNavigationBar: const AppBottomNav(currentRoute: AppRouter.shop),
      body: AppAsyncStateView(
        value: products,
        onRetry: () => ref.invalidate(productsProvider),
        data: (_) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: TextField(
                readOnly: true,
                onTap: () => Navigator.pushNamed(context, AppRouter.search),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.tune_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == selectedCategory;
                  return ChoiceChip(
                    label: Text(category == 'all' ? 'All' : category),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(selectedCategoryProvider.notifier).state =
                            category,
                  );
                },
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyStateView(
                      title: 'No products found',
                      description:
                          'Try a different category or set DemoState to normal.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        return ProductGridCard(
                          product: p,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.productDetail,
                            arguments: {'productId': p.id},
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
