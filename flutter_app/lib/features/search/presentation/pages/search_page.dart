import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/app_async_state_view.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../catalog/application/catalog_providers.dart';
import '../../../catalog/presentation/widgets/product_grid_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  final List<String> _recent = const ['Tuxedo', 'Fleece Vest', 'Winter Coat'];
  final List<String> _trending = const [
    'Emerald Velvet',
    'Denim Vest',
    'Nordic Jumper',
    'Pearl Harness',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    ref.read(searchQueryProvider.notifier).state = value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final query = ref.watch(searchQueryProvider);
    final result = ref.watch(searchProductsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search luxury pet fashion',
            border: InputBorder.none,
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    onPressed: () => _setQuery(''),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: _setQuery,
        ),
      ),
      body: AppAsyncStateView(
        value: productsAsync,
        onRetry: () => ref.invalidate(productsProvider),
        data: (_) {
          if (query.trim().isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.l),
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._recent.map(
                  (text) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded),
                    title: Text(text),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _setQuery(text),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Trending Searches',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _trending
                      .map(
                        (text) => ActionChip(
                          label: Text(text),
                          onPressed: () => _setQuery(text),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          }
          if (result.isEmpty) {
            return EmptyStateView(
              title: 'No results found',
              description: 'No products matched "$query".',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: result.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final product = result[index];
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
