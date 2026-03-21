import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/models/pet_profile.dart';
import '../../../../core/models/tryon_preview.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../pet_profile/application/pet_profile_provider.dart';
import '../../application/tryon_service.dart';
import '../../data/mock/try_on_presets.dart';
import '../../domain/try_on_preset.dart';
import '../widgets/pet_tryon_preview.dart';

class TryOnPage extends ConsumerStatefulWidget {
  const TryOnPage({super.key});

  @override
  ConsumerState<TryOnPage> createState() => _TryOnPageState();
}

class _TryOnPageState extends ConsumerState<TryOnPage> {
  late final PageController _pageController;
  int _selectedPresetIndex = 0;
  int? _appliedPresetIndex;
  bool _isFavorite = false;
  bool _isGenerating = false;
  TryOnPreview? _currentPreview;
  final Map<String, TryOnPreview> _previewCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.84);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _presetColor(TryOnPreset preset) {
    switch (preset.color) {
      case 'Emerald':
        return const Color(0xFF10B981);
      case 'Blue':
        return const Color(0xFF3B82F6);
      case 'Yellow':
        return const Color(0xFFFACC15);
      case 'Red':
        return const Color(0xFFEF4444);
      case 'Teal':
        return const Color(0xFF14B8A6);
      case 'Navy':
        return const Color(0xFF1E3A8A);
      default:
        return AppColors.primary;
    }
  }

  Color _accentColor(TryOnPreset preset) {
    switch (preset.color) {
      case 'Emerald':
        return const Color(0xFF064E3B);
      case 'Blue':
        return const Color(0xFF1D4ED8);
      case 'Yellow':
        return const Color(0xFF92400E);
      case 'Red':
        return const Color(0xFF7F1D1D);
      case 'Teal':
        return const Color(0xFF115E59);
      case 'Navy':
        return const Color(0xFF93C5FD);
      default:
        return AppColors.primaryDark;
    }
  }

  String _previewKeyFor(PetProfile pet, TryOnPreset preset) {
    return '${pet.id}|${pet.photoPath}|${preset.id}';
  }

  bool _hasCachedPreview(PetProfile pet, TryOnPreset preset) {
    return _previewCache.containsKey(_previewKeyFor(pet, preset));
  }

  Future<void> _applyPreset(PetProfile pet, TryOnPreset preset) async {
    final messenger = ScaffoldMessenger.of(context);
    final previewKey = _previewKeyFor(pet, preset);
    final cachedPreview = _previewCache[previewKey];

    if (cachedPreview != null) {
      setState(() {
        _currentPreview = cachedPreview;
        _appliedPresetIndex = _selectedPresetIndex;
      });
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final preview = await ref
          .read(tryOnServiceProvider)
          .generatePreview(pet: pet, preset: preset);
      if (!mounted) {
        return;
      }
      setState(() {
        _previewCache[previewKey] = preview;
        _currentPreview = preview;
        _appliedPresetIndex = _selectedPresetIndex;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('AI try-on generation failed. Please retry.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petProfileProvider);
    final preset = tryOnPresets[_selectedPresetIndex];
    final appliedPreset = _appliedPresetIndex == null
        ? null
        : tryOnPresets[_appliedPresetIndex!];
    final isSelectedPresetApplied = _appliedPresetIndex == _selectedPresetIndex;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentRoute: AppRouter.tryOn),
      body: SafeArea(
        child: ListView(
          children: [
            Stack(
              children: [
                PetTryOnPreview(
                  photoPath: pet.photoPath,
                  preview: _currentPreview,
                  isLoading: _isGenerating,
                  loadingLabel: 'Fitting ${preset.name}...',
                  outfitThumbnailUrl: preset.thumbnailUrl,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sharing preset preview is pending'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 64,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'SWIPE TO SELECT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 270),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _isGenerating
                                ? 'Generating ${preset.name} with Vertex AI...'
                                : isSelectedPresetApplied &&
                                      _currentPreview?.previewMode == 'vertex'
                                ? 'Vertex AI rendered ${preset.name}'
                                : appliedPreset == null
                                ? 'Swipe styles, then tap the button to generate.'
                                : 'Preview shows ${appliedPreset.name}. Tap to try ${preset.name}.',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    onPressed: () => setState(() => _isFavorite = !_isFavorite),
                    child: Icon(
                      _isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Swipe To Choose',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Swiping only changes the selected outfit. Tap the button to run AI try-on.',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 320,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: tryOnPresets.length,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedPresetIndex = index;
                          _isFavorite = false;
                        });
                      },
                      itemBuilder: (context, index) {
                        final outfit = tryOnPresets[index];
                        final isSelected = index == _selectedPresetIndex;
                        final primary = _presetColor(outfit);
                        final accent = _accentColor(outfit);
                        return AnimatedScale(
                          scale: isSelected ? 1 : 0.95,
                          duration: const Duration(milliseconds: 180),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primary, accent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.22),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            outfit.badge,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(switch (outfit.pattern) {
                                          'check' => Icons.grid_4x4_rounded,
                                          'dots' => Icons.blur_on_rounded,
                                          'stripe' => Icons.reorder_rounded,
                                          _ => Icons.checkroom_rounded,
                                        }, color: Colors.white),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _OutfitThumbnailCard(
                                      preset: outfit,
                                      backgroundColor: Colors.white,
                                      compact: true,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      outfit.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      outfit.description,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _MetaChip(label: outfit.platform),
                                        _MetaChip(label: outfit.category),
                                        _MetaChip(
                                          label:
                                              '${outfit.sizeRange.length} sizes',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      tryOnPresets.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: index == _selectedPresetIndex ? 26 : 8,
                        decoration: BoxDecoration(
                          color: index == _selectedPresetIndex
                              ? AppColors.primary
                              : const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Selected Preset',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_selectedPresetIndex + 1}/${tryOnPresets.length}',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          preset.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${preset.platform} • ${preset.color} • ${preset.category}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OutfitThumbnailCard(preset: preset),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.description,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Material: ${preset.material}',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Thickness: ${preset.thickness} • Stretch: ${preset.elasticity}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final size in preset.sizeRange.take(5))
                              Chip(
                                label: Text(size),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasCachedPreview(pet, preset)
                              ? 'This look is cached on device and will reopen faster.'
                              : isSelectedPresetApplied
                              ? 'This look is already generated.'
                              : 'Tap the button below to generate this look.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.sizeOf(context).width - 32,
        child: FilledButton.icon(
          onPressed: _isGenerating ? null : () => _applyPreset(pet, preset),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(
            _isGenerating
                ? 'Generating...'
                : isSelectedPresetApplied
                ? 'Regenerate Outfit'
                : 'Try This Outfit',
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _OutfitThumbnailCard extends StatelessWidget {
  const _OutfitThumbnailCard({
    required this.preset,
    this.backgroundColor,
    this.compact = false,
  });

  final TryOnPreset preset;
  final Color? backgroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cardSize = compact ? 76.0 : 96.0;
    final card = Container(
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: preset.thumbnailUrl == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.98),
                    Colors.white.withValues(alpha: 0.74),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      switch (preset.category) {
                        'Outerwear' => Icons.umbrella_rounded,
                        'Hoodie' => Icons.checkroom_rounded,
                        'Vest' => Icons.style_rounded,
                        'Dress' => Icons.auto_awesome_mosaic_rounded,
                        _ => Icons.checkroom_rounded,
                      },
                      color: AppColors.primaryDark,
                      size: compact ? 24 : 28,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        preset.color,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 11 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : preset.thumbnailUrl!.startsWith('assets/')
          ? Image.asset(
              preset.thumbnailUrl!,
              width: cardSize,
              height: cardSize,
              fit: BoxFit.cover,
            )
          : AppNetworkImage(
              imageUrl: preset.thumbnailUrl!,
              width: cardSize,
              height: cardSize,
            ),
    );

    if (backgroundColor != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(18), child: card);
    }
    return card;
  }
}
