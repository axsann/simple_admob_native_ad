import Flutter
import UIKit
import simple_admob_native_ad

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    SimpleAdmobNativeAdPlugin.registerNativeAdFactory(registry: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
