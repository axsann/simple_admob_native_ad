import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'simple_admob_native_ad_platform_interface.dart';

/// An implementation of [SimpleAdmobNativeAdPlatform] that uses method channels.
class MethodChannelSimpleAdmobNativeAd extends SimpleAdmobNativeAdPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('simple_admob_native_ad');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
