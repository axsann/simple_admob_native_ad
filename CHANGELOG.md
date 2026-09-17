## 2.1.0

* **Swift Package Manager support on iOS.** The plugin now ships
  `ios/simple_admob_native_ad/Package.swift`, so it no longer conflicts with
  `google_mobile_ads` 9.x when Flutter builds with SPM (the default since Flutter 3.47).
  Apps can drop `enable-swift-package-manager: false` and the
  `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES` workaround that 2.0.0 required.
* SPM builds require **Flutter 3.47 or newer** (that is where the tooling learned to resolve
  a plugin's Swift package dependency on another plugin). On Flutter 3.38–3.46 keep
  `enable-swift-package-manager: false`, which is the default there anyway.
* CocoaPods keeps working — the podspec builds the same sources. Apps that still need
  CocoaPods (for example because another plugin has not adopted SPM) need no changes,
  but they do still need the `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES`
  flag, because that is a `google_mobile_ads` 9.x + CocoaPods issue.
* iOS sources moved from `ios/Classes/` to `ios/simple_admob_native_ad/Sources/`
  (SPM requires every source file to live inside the package directory), and Swift and
  Objective-C are split into two targets (`simple_admob_native_ad` /
  `simple_admob_native_ad_objc`) because SPM cannot mix languages in one target.
  The Swift module name is unchanged, so `import simple_admob_native_ad` in your
  `AppDelegate` keeps working. No Dart or Android changes.
* Fix `SimpleNativeAd.xib` lookup: under SPM the nib lives in the target's resource
  bundle, not next to the class, so the factory now resolves the bundle at runtime.

## 2.0.0

* **Breaking**: Require `google_mobile_ads: ^9.1.0` (was `^6.0.0`).
  Apps still on `google_mobile_ads` 6.x–8.x must stay on 1.2.1.
* **Breaking**: Raise minimum Flutter to 3.38.1, as required by `google_mobile_ads` 8.0.0.
* No Dart API changes. The Kotlin and Objective-C factory interfaces used by this plugin
  (`NativeAd`, `NativeAdListener`, `NativeAdOptions`,
  `GoogleMobileAdsPlugin.registerNativeAdFactory`,
  `FLTGoogleMobileAdsPlugin.registerNativeAdFactory`) are unchanged in
  `google_mobile_ads` 9.x; only the Android import path of `NativeAdFactory` moved
  (it is now a top-level type instead of nested in `GoogleMobileAdsPlugin`).
* **iOS setup changed.** `google_mobile_ads` 9.x ships a Swift Package, and Flutter 3.47
  enables Swift Package Manager by default. Because this plugin is still CocoaPods-only,
  apps must turn SPM off (`flutter: config: enable-swift-package-manager: false`) and set
  `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES` in their Podfile.
  See the iOS section of the README. Swift Package Manager adoption is tracked for a
  future release.

## 1.2.1

* Fix iOS native ad icon left padding
* Fix Android Ad label rounded corners

## 1.2.0

* Add `leftPadding` and `rightPadding` parameters for native ad layout customization
* Add `adChoicesPlacement` parameter to control AdChoices icon position

## 1.0.1

* Added screenshots to pub.dev listing

## 1.0.0

* Initial release
* Native ad banner support for iOS and Android
* Auto-refresh with configurable interval
* Automatic lifecycle management
* Dark/light mode support with `forceColorMode` parameter
* Customizable background color with `backgroundColor` parameter
* Customizable placeholder and borders
* Theme-aware color scheme
