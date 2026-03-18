import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/app_async_state_view.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../catalog/application/catalog_providers.dart';
import '../../../catalog/presentation/widgets/product_grid_card.dart';

class BrandPage extends ConsumerWidget {
  const BrandPage({super.key, required this.brandId});

  final String brandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(brandsProvider);
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: AppAsyncStateView(
          value: brands,
          data: (value) => Text(
            value.where((b) => b.id == brandId).firstOrNull?.name ?? 'Brand',
          ),
        ),
      ),
      body: AppAsyncStateView(
        value: products,
        onRetry: () => ref.invalidate(productsProvider),
        data: (_) {
          final list = ref.watch(productsByBrandIdProvider(brandId));
          if (list.isEmpty) {
            return const EmptyStateView(
              title: 'No items for this brand',
              description: 'Try other brands from Home.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final product = list[index];
              return ProductGridCard(
                product: product,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.productDetail,
                  arguments: {'productId': product.id},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
