import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceCapabilityServiceProvider = Provider<DeviceCapabilityService>((_) {
  return DeviceCapabilityService();
});

final cameraAvailableProvider = FutureProvider<bool>((ref) {
  return ref.read(deviceCapabilityServiceProvider).isCameraAvailable();
});

class DeviceCapabilityService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<bool> isCameraAvailable() async {
    if (kIsWeb) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        final info = await _deviceInfoPlugin.iosInfo;
        return info.isPhysicalDevice;
      case TargetPlatform.android:
        final info = await _deviceInfoPlugin.androidInfo;
        return info.isPhysicalDevice;
      default:
        return false;
    }
  }
}
