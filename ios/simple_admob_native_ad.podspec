#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_admob_native_banner.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'simple_admob_native_ad'
  s.version          = '0.0.1'
  s.summary          = 'A simple, compact Flutter plugin for displaying Google AdMob native ads as banners.'
  s.description      = <<-DESC
A simple, compact Flutter plugin for displaying Google AdMob native ads as banners with auto-refresh and lifecycle management.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,swift}'
  s.resources = 'Classes/**/*.xib'
  s.dependency 'Flutter'
  s.dependency 'google_mobile_ads'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'simple_admob_native_ad_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
