import type { OutfitPreset } from "@/lib/types";

export const outfitPresets: OutfitPreset[] = [
  {
    id: "amazon-raincoat",
    name: "Reflective Rain Coat",
    category: "Outerwear",
    color: "Black",
    pattern: "solid",
    badge: "RAIN",
    description:
      "Lightweight rain coat with reflective sleeve accents for outdoor walks.",
    platform: "Amazon",
    sourceUrl: "https://amzn.asia/d/0a9xVPvR",
    material: "Polyester",
    thickness: "Light to medium",
    elasticity: "Low",
    fastener: "Velcro or snap",
    sizeRange: ["XS", "S", "M", "L", "XL"],
    thumbnailPath: "/outfits/raincoat.png"
  },
  {
    id: "amazon-security-hoodie",
    name: "Security Hoodie",
    category: "Hoodie",
    color: "Red",
    pattern: "solid",
    badge: "RED",
    description:
      "Playful red hoodie with a bold back print and relaxed casual shape.",
    platform: "Amazon",
    sourceUrl: "https://amzn.asia/d/00qqFaML",
    material: "Fleece",
    thickness: "Heavy",
    elasticity: "High",
    fastener: "Pullover",
    sizeRange: ["S", "L", "XL"],
    thumbnailPath: "/outfits/security_hoodie.png"
  },
  {
    id: "moncheri-panda-parka",
    name: "Panda Parka",
    category: "Hoodie",
    color: "Mocha",
    pattern: "solid",
    badge: "PANDA",
    description:
      "Soft panda-inspired parka from moncheri with plush texture and a cozy fit.",
    platform: "moncheri",
    sourceUrl: "https://moncheri.jp/products/muto252835",
    material: "Polyester",
    thickness: "Heavy",
    elasticity: "High",
    fastener: "Pullover",
    sizeRange: ["S", "M", "L", "XL"],
    thumbnailPath: "/outfits/Panda_Parka.png"
  },
  {
    id: "moncheri-ribbon-dress",
    name: "Ribbon Dress",
    category: "Dress",
    color: "Beige",
    pattern: "dots",
    badge: "RIBBON",
    description:
      "A soft ribbon-pattern dress with a large back bow and elegant silhouette.",
    platform: "moncheri",
    sourceUrl: "https://moncheri.jp/products/mgop252952",
    material: "Polyester, Cotton",
    thickness: "Medium",
    elasticity: "High",
    fastener: "Snap button",
    sizeRange: ["XXS", "XS", "S", "M"],
    thumbnailPath: "/outfits/Ribbon_Dress.png"
  },
  {
    id: "amazon-carrot-vest",
    name: "Carrot Vest",
    category: "Vest",
    color: "Orange",
    pattern: "solid",
    badge: "CARROT",
    description: "Warm carrot-themed fleece vest with a playful seasonal look.",
    platform: "Amazon",
    sourceUrl: "https://amzn.asia/d/04Vx8pbI",
    material: "Boa, Fleece",
    thickness: "Heavy",
    elasticity: "Low to medium",
    fastener: "Pullover",
    sizeRange: ["XS", "M", "L", "XL"],
    thumbnailPath: "/outfits/Carrot_Vest.png"
  }
];
