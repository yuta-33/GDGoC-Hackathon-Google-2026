import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../pet_profile/application/pet_profile_provider.dart';

class PetsPage extends ConsumerWidget {
  const PetsPage({super.key});

  Widget _buildPetAvatar(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return const CircleAvatar(
        radius: 28,
        child: Text('🐕', style: TextStyle(fontSize: 26)),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundImage: FileImage(File(photoPath)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(petProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRouter.petProfile),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: AppRouter.pets),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildPetAvatar(pet.photoPath),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(pet.breed),
                            Text(
                              '${pet.weight} kg',
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRouter.petProfile),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRouter.tryOn),
                          child: const Text('Virtual Try-On'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRouter.sizeGuide),
                          child: const Text('Size Guide'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRouter.petProfile),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Another Pet'),
          ),
        ],
      ),
    );
  }
}
