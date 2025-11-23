import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'simple_admob_native_ad_method_channel.dart';

abstract class SimpleAdmobNativeAdPlatform extends PlatformInterface {
  /// Constructs a SimpleAdmobNativeAdPlatform.
  SimpleAdmobNativeAdPlatform() : super(token: _token);

  static final Object _token = Object();

  static SimpleAdmobNativeAdPlatform _instance = MethodChannelSimpleAdmobNativeAd();

  /// The default instance of [SimpleAdmobNativeAdPlatform] to use.
  ///
  /// Defaults to [MethodChannelSimpleAdmobNativeAd].
  static SimpleAdmobNativeAdPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SimpleAdmobNativeAdPlatform] when
  /// they register themselves.
  static set instance(SimpleAdmobNativeAdPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
