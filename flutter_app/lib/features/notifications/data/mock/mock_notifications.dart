import 'package:flutter/material.dart';

import '../../../../core/models/app_notification.dart';

const mockNotifications = <AppNotification>[
  AppNotification(
    id: '1',
    title: 'Order Shipped',
    message: 'Your London Trench Coat is on its way!',
    time: '2 hours ago',
    icon: Icons.shopping_bag,
    iconColor: Color(0xFF0D9488),
    backgroundColor: Color(0xFFCCFBF1),
    unread: true,
  ),
  AppNotification(
    id: '2',
    title: 'New AI Recommendation',
    message: 'We found 5 new items with a strong match for your pet profile',
    time: '5 hours ago',
    icon: Icons.auto_awesome,
    iconColor: Color(0xFF7C3AED),
    backgroundColor: Color(0xFFEDE9FE),
    unread: true,
  ),
  AppNotification(
    id: '3',
    title: 'Flash Sale Alert',
    message: '30% off all Barkberry items for the next 24 hours',
    time: '1 day ago',
    icon: Icons.local_offer,
    iconColor: Color(0xFFDC2626),
    backgroundColor: Color(0xFFFEE2E2),
  ),
];
