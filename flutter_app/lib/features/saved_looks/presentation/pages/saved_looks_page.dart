import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/models/saved_look.dart';
import '../../../../core/widgets/app_async_state_view.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../application/saved_looks_service.dart';

class SavedLooksPage extends ConsumerWidget {
  const SavedLooksPage({super.key});

  Widget _buildLookCard(SavedLook look) {
    final thumbnailUrl = look.thumbnailUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: thumbnailUrl == null || thumbnailUrl.isEmpty
                  ? Container(
                      width: 84,
                      height: 84,
                      color: const Color(0xFFF1F5F9),
                      alignment: Alignment.center,
                      child: const Icon(Icons.auto_awesome_rounded, size: 28),
                    )
                  : AppNetworkImage(
                      imageUrl: thumbnailUrl,
                      width: 84,
                      height: 84,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    look.memo?.isNotEmpty == true
                        ? look.memo!
                        : 'Saved Look ${look.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${look.itemCount} items • Pet ${look.petId}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: look.items
                        .map(
                          (item) => Chip(
                            label: Text(
                              item.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLooksAsync = ref.watch(savedLooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Looks')),
      body: AppAsyncStateView<List<SavedLook>>(
        value: savedLooksAsync,
        onRetry: () => ref.invalidate(savedLooksProvider),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateView(
              title: 'No saved looks yet',
              description:
                  'Save favorite outfits from the closet or try-on flow to reopen them later.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildLookCard(items[index]),
          );
        },
      ),
    );
  }
}
