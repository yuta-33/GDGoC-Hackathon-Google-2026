import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/models/breed_baseline.dart';
import '../../../../core/models/pet_profile.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../pets/application/pets_service.dart';
import '../../application/breed_baseline_service.dart';
import '../../application/device_capability_service.dart';
import '../../application/pet_analysis_service.dart';
import '../../application/pet_photo_storage_service.dart';
import '../../application/pet_profile_provider.dart';

class PetProfilePage extends ConsumerStatefulWidget {
  const PetProfilePage({super.key});

  @override
  ConsumerState<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends ConsumerState<PetProfilePage> {
  static const _kgToLbFactor = 2.2046226218;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _neckController = TextEditingController();
  final _chestController = TextEditingController();
  final _backController = TextEditingController();

  final _breedFocus = FocusNode();
  final _imagePicker = ImagePicker();
  late final ProviderSubscription<PetProfile> _petProfileSubscription;
  bool _isSaving = false;
  String? _photoPath;
  String _unit = 'KG';

  @override
  void initState() {
    super.initState();
    _syncControllers(ref.read(petProfileProvider), updateState: false);
    _petProfileSubscription = ref.listenManual(petProfileProvider, (_, next) {
      if (_isSaving) {
        return;
      }
      _syncControllers(next);
    });
  }

  @override
  void dispose() {
    _petProfileSubscription.close();
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _neckController.dispose();
    _chestController.dispose();
    _backController.dispose();
    _breedFocus.dispose();
    super.dispose();
  }

  void _syncControllers(PetProfile profile, {bool updateState = true}) {
    final nextUnit = profile.weightUnit;
    final nextWeight = _toDisplayWeight(profile.weight, nextUnit);
    _nameController.text = profile.name;
    _breedController.text = profile.breed;
    _weightController.text = _formatDecimal(nextWeight);
    _neckController.text = _formatDecimal(profile.neckGirth);
    _chestController.text = _formatDecimal(profile.chestGirth);
    _backController.text = _formatDecimal(profile.backLength);
    _photoPath = profile.photoPath;

    if (updateState && mounted) {
      setState(() => _unit = nextUnit);
    } else {
      _unit = nextUnit;
    }
  }

  String _formatDecimal(double value) {
    return value.toStringAsFixed(1);
  }

  double _toDisplayWeight(double kilograms, String unit) {
    if (unit == 'LB') {
      return kilograms * _kgToLbFactor;
    }
    return kilograms;
  }

  double _toStoredWeight(double displayWeight) {
    if (_unit == 'LB') {
      return displayWeight / _kgToLbFactor;
    }
    return displayWeight;
  }

  void _handleUnitChange(String nextUnit) {
    if (nextUnit == _unit) {
      return;
    }

    final currentValue = double.tryParse(_weightController.text.trim());
    if (currentValue != null) {
      final convertedValue = nextUnit == 'LB'
          ? currentValue * _kgToLbFactor
          : currentValue / _kgToLbFactor;
      _weightController.text = _formatDecimal(convertedValue);
    }

    setState(() => _unit = nextUnit);
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final displayWeight = double.tryParse(_weightController.text.trim()) ?? 0;

    final next = PetProfile(
      id: '1',
      name: _nameController.text.trim(),
      breed: _breedController.text.trim(),
      weight: _toStoredWeight(displayWeight),
      weightUnit: _unit,
      neckGirth: double.tryParse(_neckController.text.trim()) ?? 0,
      chestGirth: double.tryParse(_chestController.text.trim()) ?? 0,
      backLength: double.tryParse(_backController.text.trim()) ?? 0,
      photoPath: _photoPath,
    );

    final messenger = ScaffoldMessenger.of(context);
    var persistedProfile = next;
    setState(() => _isSaving = true);

    try {
      persistedProfile = await ref.read(petsServiceProvider).savePet(next);
      ref.invalidate(petsProvider);
    } catch (error) {
      debugPrint('Pet save request failed: $error');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cloud save failed. Continuing with local profile.'),
        ),
      );
    }

    await ref.read(petProfileProvider.notifier).saveProfile(persistedProfile);

    try {
      final analysis = await ref
          .read(petAnalysisServiceProvider)
          .analyzePet(persistedProfile);
      debugPrint(
        'Pet analysis result: petType=${analysis.petType}, '
        'furColor=${analysis.furColor}, bodySize=${analysis.bodySize}, '
        'styleTags=${analysis.styleTags.join(',')}',
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${persistedProfile.name}. AI analyzed ${analysis.petType} / '
            '${analysis.furColor} / ${analysis.bodySize}',
          ),
        ),
      );
    } catch (error) {
      debugPrint('Pet analysis request failed: $error');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('AI analysis failed. Continuing with local profile.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, AppRouter.home);
  }

  void _showImageSourceSheet({required bool cameraAvailable}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cameraAvailable)
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: const Text('Take photo'),
                    subtitle: const Text('Use your device camera'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickPetPhoto(ImageSource.camera);
                    },
                  )
                else
                  const ListTile(
                    leading: Icon(Icons.camera_alt_outlined),
                    title: Text('Take photo'),
                    subtitle: Text(
                      'Camera is unavailable on simulator. Use gallery instead.',
                    ),
                    enabled: false,
                  ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  subtitle: const Text('Pick an existing dog photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickPetPhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPetPhoto(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (pickedFile == null) {
        return;
      }

      final savedPath = await ref
          .read(petPhotoStorageServiceProvider)
          .savePhoto(
            sourceFile: File(pickedFile.path),
            previousPhotoPath: _photoPath,
          );

      if (!mounted) {
        return;
      }

      setState(() => _photoPath = savedPath);
      debugPrint('Pet photo saved to: $savedPath');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pet photo saved to local pet_photos folder.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      debugPrint('Pet photo pick failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick pet photo.')),
      );
    }
  }

  void _applyBreedBaseline(BreedBaseline baseline) {
    _breedController.text = baseline.displayName;
    _breedController.selection = TextSelection.collapsed(
      offset: baseline.displayName.length,
    );
    _weightController.text = _formatDecimal(
      _toDisplayWeight(baseline.weightKg, _unit),
    );
    _neckController.text = baseline.neckGirthCm.toStringAsFixed(1);
    _chestController.text = baseline.chestGirthCm.toStringAsFixed(1);
    _backController.text = baseline.backLengthCm.toStringAsFixed(1);
  }

  Widget _buildPetPhotoAvatar() {
    final photoPath = _photoPath;
    if (photoPath == null || photoPath.isEmpty) {
      return const CircleAvatar(
        radius: 48,
        backgroundColor: Color(0xFFCCFBF1),
        child: Text('🐾', style: TextStyle(fontSize: 40)),
      );
    }

    final imageProvider = photoPath.startsWith('assets/')
        ? AssetImage(photoPath)
        : FileImage(File(photoPath)) as ImageProvider<Object>;

    return CircleAvatar(
      radius: 48,
      backgroundColor: const Color(0xFFCCFBF1),
      backgroundImage: imageProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraAvailable =
        ref.watch(cameraAvailableProvider).valueOrNull ?? false;
    final breedBaselines =
        ref.watch(breedBaselinesProvider).valueOrNull ??
        const <BreedBaseline>[];
    final typedBreed = _breedController.text.trim().toLowerCase();
    final suggestions = typedBreed.isEmpty
        ? breedBaselines.take(5).toList()
        : breedBaselines
              .where((b) => b.displayName.toLowerCase().contains(typedBreed))
              .take(5)
              .toList();
    final showSuggestions = _breedFocus.hasFocus && suggestions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Pet Profile')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: PrimaryButton(
          label: _isSaving ? 'Analyzing...' : 'Save Profile',
          icon: Icons.arrow_forward_rounded,
          onPressed: _isSaving ? null : _saveProfile,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.l),
            children: [
              const Text('Step 1 of 2'),
              const SizedBox(height: 4),
              const Text(
                'Tell us about your friend',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Provide accurate info for a perfect AI-powered fit.'),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    _buildPetPhotoAvatar(),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: () => _showImageSourceSheet(
                          cameraAvailable: cameraAvailable,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    _showImageSourceSheet(cameraAvailable: cameraAvailable),
                icon: const Icon(Icons.upload_rounded),
                label: Text(
                  _photoPath == null ? 'Upload Pet Photo' : 'Change Pet Photo',
                ),
              ),
              Text(
                cameraAvailable
                    ? 'Photos are stored locally on this device first.'
                    : 'Simulator cannot open the real camera. Import from gallery instead.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Pet Name',
                  hintText: 'e.g. Buddy',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Pet name is required'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _breedController,
                focusNode: _breedFocus,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  hintText: 'e.g. Golden Retriever',
                  suffixIcon: Icon(Icons.search_rounded),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Breed is required'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              if (showSuggestions)
                Card(
                  margin: const EdgeInsets.only(top: 6),
                  child: Column(
                    children: suggestions
                        .map(
                          (breed) => ListTile(
                            dense: true,
                            title: Text(breed.displayName),
                            subtitle: Text(
                              'Std: ${breed.weightKg.toStringAsFixed(1)}kg / '
                              '${breed.neckGirthCm.toStringAsFixed(0)}-${breed.chestGirthCm.toStringAsFixed(0)}-${breed.backLengthCm.toStringAsFixed(0)}cm',
                            ),
                            onTap: () {
                              setState(() {
                                _applyBreedBaseline(breed);
                              });
                              _breedFocus.unfocus();
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        hintText: '0.0',
                      ),
                      validator: (value) {
                        final n = double.tryParse(value ?? '');
                        if (n == null || n <= 0) {
                          return 'Valid weight is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<String>(
                    selected: {_unit},
                    onSelectionChanged: (set) => _handleUnitChange(set.first),
                    segments: const [
                      ButtonSegment(value: 'KG', label: Text('KG')),
                      ButtonSegment(value: 'LB', label: Text('LB')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(AppRadius.l),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Measurements',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRouter.sizeGuide),
                          icon: const Icon(Icons.help_outline_rounded),
                        ),
                      ],
                    ),
                    const Text(
                      'Accurate measurements help us find the best fit.',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _neckController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Neck Girth (cm)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _chestController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Chest Girth (cm)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _backController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Back Length (cm)',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF111827),
                    child: Icon(Icons.straighten_rounded, color: Colors.white),
                  ),
                  title: const Text(
                    'Not sure how to measure?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text('View visual guide'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRouter.sizeGuide),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
