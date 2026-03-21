export type PetProfile = {
  id: string;
  name: string;
  breed: string;
  weight: number;
  weightUnit: "KG" | "LB";
  neckGirth: number;
  chestGirth: number;
  backLength: number;
  photoDataUrl?: string;
};

export type TryOnPreview = {
  tryOnId: string;
  overlaySummary: string;
  previewMode: string;
  generatedImageBase64?: string;
  generatedImageMimeType?: string;
  resultImageUrl?: string;
};

export type OutfitPreset = {
  id: string;
  name: string;
  category: string;
  color: string;
  pattern: string;
  badge: string;
  description: string;
  platform: string;
  sourceUrl: string;
  material: string;
  thickness: string;
  elasticity: string;
  fastener: string;
  sizeRange: string[];
  thumbnailPath: string;
};
