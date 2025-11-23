import Flutter
import UIKit
import google_mobile_ads

public class SimpleAdmobNativeAdPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "simple_admob_native_ad", binaryMessenger: registrar.messenger())
    let instance = SimpleAdmobNativeAdPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Helper method for AppDelegate registration

  /// Registers the SimpleNativeAdFactory with Google Mobile Ads.
  /// Call this method in your AppDelegate's didFinishLaunchingWithOptions.
  ///
  /// - Parameter registry: The FlutterPluginRegistry (typically your AppDelegate)
  ///
  /// Example usage:
  /// ```swift
  /// import simple_admob_native_ad
  ///
  /// override func application(
  ///   _ application: UIApplication,
  ///   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  /// ) -> Bool {
  ///   GeneratedPluginRegistrant.register(with: self)
  ///   SimpleAdmobNativeAdPlugin.registerNativeAdFactory(registry: self)
  ///   return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  /// }
  /// ```
  public static func registerNativeAdFactory(registry: FlutterPluginRegistry) {
    let nativeAdFactory = SimpleNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      registry,
      factoryId: "simpleAdmobNativeAdFactory",
      nativeAdFactory: nativeAdFactory
    )
  }
}
