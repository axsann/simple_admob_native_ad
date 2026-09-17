// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "simple_admob_native_ad",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        // The library name is hyphen separated because Swift Package Manager uses it as the
        // CFBundleIdentifier when linked dynamically, and that cannot contain underscores.
        .library(name: "simple-admob-native-ad", targets: ["simple_admob_native_ad"])
    ],
    dependencies: [
        .package(name: "google_mobile_ads", path: "../google_mobile_ads"),
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        // Swift Package Manager cannot mix Swift and Objective-C in one target, so the
        // native ad factory (Objective-C, owns the .xib) lives in its own target.
        .target(
            name: "simple_admob_native_ad_objc",
            dependencies: [
                .product(name: "google-mobile-ads", package: "google_mobile_ads")
            ],
            resources: [
                .process("Resources")
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include/simple_admob_native_ad_objc")
            ]
        ),
        .target(
            name: "simple_admob_native_ad",
            dependencies: [
                "simple_admob_native_ad_objc",
                .product(name: "google-mobile-ads", package: "google_mobile_ads"),
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ]
        ),
    ]
)
