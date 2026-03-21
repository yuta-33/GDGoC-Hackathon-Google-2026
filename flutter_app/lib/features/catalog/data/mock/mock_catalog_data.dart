import 'package:flutter/material.dart';

import '../../../../core/models/brand.dart';
import '../../../../core/models/product.dart';

const mockBrands = <Brand>[
  Brand(id: '1', name: 'Pawsace', logo: '🐾', color: Color(0xFFFFE4E1)),
  Brand(id: '2', name: 'Barkberry', logo: '🎩', color: Color(0xFF2C1810)),
  Brand(id: '3', name: 'Pupreme', logo: '👑', color: Color(0xFFF5E6D3)),
  Brand(id: '4', name: 'Tiffany & Co', logo: '💎', color: Color(0xFF1A1A1A)),
];

const mockProducts = <Product>[
  Product(
    id: '1',
    name: 'London Trench Coat',
    brand: 'Barkberry',
    price: 129,
    image:
        'https://images.unsplash.com/photo-1766211697934-07f0b9410426?auto=format&fit=crop&w=1080&q=80',
    category: 'Outerwear',
    tags: ['newest', 'trending'],
    description: 'Luxury waterproof trench coat with signature check lining',
    sizes: ['XS', 'S', 'M', 'L'],
    colors: ['Beige', 'Black', 'Navy'],
    matchPercentage: 98,
  ),
  Product(
    id: '2',
    name: 'Nordic Wool Jumper',
    brand: 'Scandipup',
    price: 65,
    image:
        'https://images.unsplash.com/photo-1604722603390-3b2b2fb446c9?auto=format&fit=crop&w=1080&q=80',
    category: 'Knitwear',
    tags: ['popular'],
    description: 'Soft merino wool jumper with Nordic patterns',
    sizes: ['XS', 'S', 'M', 'L'],
    colors: ['Red', 'White', 'Blue'],
    matchPercentage: 92,
  ),
  Product(
    id: '3',
    name: 'Downtown Denim Vest',
    brand: 'Pupreme',
    price: 89.99,
    image:
        'https://images.unsplash.com/photo-1650132392503-76a6bdade430?auto=format&fit=crop&w=1080&q=80',
    category: 'Casual',
    tags: ['trending'],
    description: 'Premium denim vest with adjustable straps',
    sizes: ['XS', 'S', 'M', 'L'],
    colors: ['Dark Denim', 'Light Denim'],
    matchPercentage: 95,
  ),
  Product(
    id: '4',
    name: 'Gala Pearl Harness',
    brand: 'Pawvinci',
    price: 210,
    image:
        'https://images.unsplash.com/photo-1621978197690-6a2371618799?auto=format&fit=crop&w=1080&q=80',
    category: 'Accessories',
    tags: ['newest'],
    description: 'Hand-crafted pearl-embellished leather harness',
    sizes: ['XS', 'S', 'M'],
    colors: ['Cream', 'Blush'],
    matchPercentage: 88,
  ),
  Product(
    id: '5',
    name: 'The Emerald Velvet Tuxedo',
    brand: 'Barkberry',
    price: 185,
    image:
        'https://images.unsplash.com/photo-1703721025121-26d64508482b?auto=format&fit=crop&w=1080&q=80',
    category: 'Formal',
    tags: ['featured'],
    description:
        'Tailored fit with a polished silhouette for special occasions',
    sizes: ['S', 'M', 'L'],
    colors: ['Emerald', 'Navy', 'Burgundy'],
    matchPercentage: 98,
  ),
  Product(
    id: '6',
    name: 'Fleece Vest',
    brand: 'Pawsace',
    price: 42,
    image:
        'https://images.unsplash.com/photo-1630438994394-3deff7a591bf?auto=format&fit=crop&w=1080&q=80',
    category: 'Knitwear',
    tags: ['popular', 'sale'],
    description: 'Cozy ribbed fleece vest in premium cotton',
    sizes: ['XS', 'S', 'M', 'L', 'XL'],
    colors: ['Teal', 'Cream', 'Gray'],
    matchPercentage: 98,
  ),
  Product(
    id: '7',
    name: 'Arch Hoodie',
    brand: 'Pupreme',
    price: 55,
    image:
        'https://images.unsplash.com/photo-1767503306234-c0e2dd3410f8?auto=format&fit=crop&w=1080&q=80',
    category: 'Casual',
    tags: ['popular'],
    description: 'Soft cotton hoodie with adjustable drawstrings',
    sizes: ['XS', 'S', 'M', 'L'],
    colors: ['White', 'Gray', 'Black'],
    matchPercentage: 90,
  ),
  Product(
    id: '8',
    name: 'Quilted Winter Coat',
    brand: 'Barkberry',
    price: 145,
    image:
        'https://images.unsplash.com/photo-1764022122207-54f8154d52d9?auto=format&fit=crop&w=1080&q=80',
    category: 'Outerwear',
    tags: ['newest', 'winter'],
    description: 'Insulated quilted coat with faux fur trim',
    sizes: ['XS', 'S', 'M'],
    colors: ['Camel', 'Black', 'Olive'],
    matchPercentage: 94,
  ),
];
