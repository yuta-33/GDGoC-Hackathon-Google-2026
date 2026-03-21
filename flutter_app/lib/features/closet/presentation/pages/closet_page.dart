import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/application/local_identity_service.dart';
import '../../../../core/models/closet_item.dart';
import '../../../../core/widgets/app_async_state_view.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../pet_profile/application/pet_profile_provider.dart';
import '../../../saved_looks/application/saved_looks_service.dart';
import '../../application/closet_service.dart';

class ClosetPage extends ConsumerStatefulWidget {
  const ClosetPage({super.key});

  @override
  ConsumerState<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends ConsumerState<ClosetPage> {
  static const _seasonOptions = [
    'spring',
    'summer',
    'autumn',
    'winter',
    'casual',
    'outdoor',
  ];

  Future<String?> _resolvePetId() async {
    final localPetId = ref.read(petProfileProvider).id;
    if (localPetId.startsWith('pet_')) {
      return localPetId;
    }
    return null;
  }

  Future<void> _saveLookFromItem(ClosetItem item) async {
    try {
      final petId = await _resolvePetId();
      if (petId == null || petId.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Save a pet profile to the backend before saving looks.',
            ),
          ),
        );
        return;
      }

      await ref
          .read(savedLooksServiceProvider)
          .createSavedLook(
            petId: petId,
            clothingIds: [item.id],
            memo: '${item.name} look',
          );
      ref.invalidate(savedLooksProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved look created.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save look: $error')));
    }
  }

  Future<void> _showAddItemSheet() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final colorController = TextEditingController(text: 'blue');
    final brandController = TextEditingController(text: 'PetFit');
    var category = 'Hoodie';
    var size = 'M';
    var seasons = <String>['casual'];
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (isSubmitting || !formKey.currentState!.validate()) {
                return;
              }

              setModalState(() => isSubmitting = true);
              try {
                await ref
                    .read(closetServiceProvider)
                    .createClosetItem(
                      ownerId: ref
                          .read(localIdentityServiceProvider)
                          .getOwnerId(),
                      name: nameController.text.trim(),
                      category: category,
                      color: colorController.text.trim(),
                      size: size,
                      brand: brandController.text.trim(),
                      seasonTags: seasons,
                    );
                ref.invalidate(closetItemsProvider);
                if (!mounted || !context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Closet item added.')),
                );
              } catch (error) {
                setModalState(() => isSubmitting = false);
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Failed to add closet item: $error')),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Closet Item',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Enter item name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Top', child: Text('Top')),
                          DropdownMenuItem(
                            value: 'Hoodie',
                            child: Text('Hoodie'),
                          ),
                          DropdownMenuItem(value: 'Coat', child: Text('Coat')),
                          DropdownMenuItem(
                            value: 'Accessories',
                            child: Text('Accessories'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() => category = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: colorController,
                              decoration: const InputDecoration(
                                labelText: 'Color',
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'Enter color'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: size,
                              decoration: const InputDecoration(
                                labelText: 'Size',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'XS',
                                  child: Text('XS'),
                                ),
                                DropdownMenuItem(value: 'S', child: Text('S')),
                                DropdownMenuItem(value: 'M', child: Text('M')),
                                DropdownMenuItem(value: 'L', child: Text('L')),
                                DropdownMenuItem(
                                  value: 'XL',
                                  child: Text('XL'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setModalState(() => size = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: brandController,
                        decoration: const InputDecoration(labelText: 'Brand'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Enter brand'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Season Tags',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _seasonOptions.map((tag) {
                          final selected = seasons.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            onSelected: (selectedNow) {
                              setModalState(() {
                                if (selectedNow) {
                                  seasons = [...seasons, tag];
                                } else {
                                  seasons = seasons
                                      .where((item) => item != tag)
                                      .toList();
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isSubmitting ? null : submit,
                          child: Text(
                            isSubmitting ? 'Saving...' : 'Add Closet Item',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    colorController.dispose();
    brandController.dispose();
  }

  Widget _buildClosetCard(ClosetItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: item.imageUrl == null || item.imageUrl!.isEmpty
                      ? Container(
                          width: 78,
                          height: 78,
                          color: const Color(0xFFF1F5F9),
                          alignment: Alignment.center,
                          child: const Icon(Icons.checkroom_rounded, size: 28),
                        )
                      : AppNetworkImage(
                          imageUrl: item.imageUrl!,
                          width: 78,
                          height: 78,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${item.brand} • ${item.category}'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text(
                              item.size,
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(
                              item.color,
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          for (final tag in item.seasonTags.take(2))
                            Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 12),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _saveLookFromItem(item),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save Look'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final closetAsync = ref.watch(closetItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Closet'),
        actions: [
          IconButton(
            onPressed: _showAddItemSheet,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: AppAsyncStateView<List<ClosetItem>>(
        value: closetAsync,
        onRetry: () => ref.invalidate(closetItemsProvider),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateView(
              title: 'No closet items yet',
              description:
                  'Add your dog\'s clothes so they can be reused in try-on and saved looks.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildClosetCard(items[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemSheet,
        icon: const Icon(Icons.checkroom_rounded),
        label: const Text('Add Item'),
      ),
    );
  }
}
