import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/app_async_state_view.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../catalog/application/catalog_providers.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  String selectedSize = 'M';
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      body: AppAsyncStateView(
        value: productsAsync,
        onRetry: () => ref.invalidate(productsProvider),
        data: (products) {
          final product = products
              .where((p) => p.id == widget.productId)
              .firstOrNull;
          if (product == null) {
            return const EmptyStateView(
              title: 'Product not found',
              description: 'The selected product could not be loaded.',
            );
          }

          selectedSize = product.sizes.contains(selectedSize)
              ? selectedSize
              : (product.sizes.isNotEmpty ? product.sizes.first : 'M');

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: AppNetworkImage(imageUrl: product.image),
                ),
                actions: [
                  IconButton(
                    onPressed: () => setState(() => isFavorite = !isFavorite),
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share sheet integration pending'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_rounded),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (product.matchPercentage != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${product.matchPercentage}% Match',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(product.description ?? 'No description'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text(
                            'Select Size',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRouter.sizeGuide,
                            ),
                            child: const Text('Size Guide'),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: product.sizes
                            .map(
                              (size) => ChoiceChip(
                                label: Text(size),
                                selected: selectedSize == size,
                                onSelected: (_) =>
                                    setState(() => selectedSize = size),
                              ),
                            )
                            .toList(),
                      ),
                      if (selectedSize == 'M' &&
                          product.matchPercentage != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '✓ AI recommends this size for the saved pet profile',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (product.colors.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Available Colors',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.colors
                              .map((color) => Chip(label: Text(color)))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.textPrimary,
                              ),
                              onPressed: () =>
                                  Navigator.pushNamed(context, AppRouter.tryOn),
                              child: const Text('Virtual Try-On'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text('Add to Cart'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
