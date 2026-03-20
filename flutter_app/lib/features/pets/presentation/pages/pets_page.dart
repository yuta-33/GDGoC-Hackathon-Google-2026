import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/models/pet_profile.dart';
import '../../../../core/widgets/app_async_state_view.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../pet_profile/application/pet_profile_provider.dart';
import '../../application/pets_service.dart';

class PetsPage extends ConsumerWidget {
  const PetsPage({super.key});

  static const _kgToLbFactor = 2.2046226218;

  Widget _buildPetAvatar(String? photoPathOrUrl) {
    if (photoPathOrUrl == null || photoPathOrUrl.isEmpty) {
      return const CircleAvatar(
        radius: 28,
        child: Text('🐕', style: TextStyle(fontSize: 26)),
      );
    }

    final uri = Uri.tryParse(photoPathOrUrl);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(photoPathOrUrl),
      );
    }

    if (photoPathOrUrl.startsWith('assets/')) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: AssetImage(photoPathOrUrl),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundImage: FileImage(File(photoPathOrUrl)),
    );
  }

  Widget _buildPetCard(BuildContext context, PetProfile pet) {
    final displayWeight = pet.weightUnit == 'LB'
        ? pet.weight * _kgToLbFactor
        : pet.weight;

    return Card(
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
                        '${displayWeight.toStringAsFixed(1)} ${pet.weightUnit.toLowerCase()}',
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localPet = ref.watch(petProfileProvider);
    final petsAsync = ref.watch(petsProvider);

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
      body: AppAsyncStateView<List<PetProfile>>(
        value: petsAsync,
        onRetry: () => ref.invalidate(petsProvider),
        loading: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPetCard(context, localPet),
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
        data: (backendPets) {
          final pets = backendPets.isEmpty ? [localPet] : backendPets;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var index = 0; index < pets.length; index++) ...[
                _buildPetCard(context, pets[index]),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.petProfile),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Another Pet'),
              ),
            ],
          );
        },
      ),
    );
  }
}
