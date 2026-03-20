import '../../../../core/models/pet_profile.dart';

const defaultPetPhotoAssetPath = 'assets/images/demo_pet.png';

const defaultPetProfile = PetProfile(
  id: '1',
  name: 'Buddy',
  breed: 'Golden Retriever',
  weight: 28.5,
  weightUnit: 'KG',
  neckGirth: 42,
  chestGirth: 68,
  backLength: 55,
  photoPath: defaultPetPhotoAssetPath,
);
