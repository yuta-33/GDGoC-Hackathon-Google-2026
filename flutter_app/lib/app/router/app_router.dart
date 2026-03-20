import 'package:flutter/material.dart';

import '../../features/brand/presentation/pages/brand_page.dart';
import '../../features/closet/presentation/pages/closet_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/pet_profile/presentation/pages/pet_profile_page.dart';
import '../../features/pets/presentation/pages/pets_page.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/saved_looks/presentation/pages/saved_looks_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/shop/presentation/pages/shop_page.dart';
import '../../features/size_guide/presentation/pages/size_guide_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/try_on/presentation/pages/try_on_page.dart';

class AppRouter {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const petProfile = '/pet-profile';
  static const home = '/home';
  static const shop = '/shop';
  static const tryOn = '/try-on';
  static const pets = '/pets';
  static const profile = '/profile';
  static const closet = '/closet';
  static const savedLooks = '/saved-looks';
  static const search = '/search';
  static const productDetail = '/product';
  static const brand = '/brand';
  static const sizeGuide = '/size-guide';
  static const notifications = '/notifications';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _material(const SplashPage(), settings);
      case onboarding:
        return _material(const OnboardingPage(), settings);
      case petProfile:
        return _material(const PetProfilePage(), settings);
      case home:
        return _material(const HomePage(), settings);
      case shop:
        return _material(const ShopPage(), settings);
      case tryOn:
        return _material(const TryOnPage(), settings);
      case pets:
        return _material(const PetsPage(), settings);
      case profile:
        return _material(const ProfilePage(), settings);
      case closet:
        return _material(const ClosetPage(), settings);
      case savedLooks:
        return _material(const SavedLooksPage(), settings);
      case search:
        return _material(const SearchPage(), settings);
      case productDetail:
        final productArgs = settings.arguments as Map<String, dynamic>?;
        return _material(
          ProductDetailPage(productId: productArgs?['productId'] as String?),
          settings,
        );
      case brand:
        final brandArgs = settings.arguments as Map<String, dynamic>?;
        return _material(
          BrandPage(brandId: brandArgs?['brandId'] as String? ?? ''),
          settings,
        );
      case sizeGuide:
        return _material(const SizeGuidePage(), settings);
      case notifications:
        return _material(const NotificationsPage(), settings);
      default:
        return _material(
          Scaffold(
            appBar: AppBar(title: const Text('Not found')),
            body: Center(child: Text('Unknown route: ${settings.name}')),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _material(
    Widget child,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}
