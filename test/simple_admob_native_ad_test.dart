import 'package:flutter_test/flutter_test.dart';
import 'package:simple_admob_native_ad/simple_admob_native_ad_platform_interface.dart';
import 'package:simple_admob_native_ad/simple_admob_native_ad_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSimpleAdmobNativeAdPlatform
    with MockPlatformInterfaceMixin
    implements SimpleAdmobNativeAdPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SimpleAdmobNativeAdPlatform initialPlatform = SimpleAdmobNativeAdPlatform.instance;

  test('$MethodChannelSimpleAdmobNativeAd is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSimpleAdmobNativeAd>());
  });

  test('getPlatformVersion', () async {
    MockSimpleAdmobNativeAdPlatform fakePlatform = MockSimpleAdmobNativeAdPlatform();
    SimpleAdmobNativeAdPlatform.instance = fakePlatform;

    expect(await SimpleAdmobNativeAdPlatform.instance.getPlatformVersion(), '42');
  });
}
