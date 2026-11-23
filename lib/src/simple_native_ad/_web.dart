import 'package:flutter/material.dart';
import '../simple_native_ad_timer_controller.dart';

enum AdColorMode {
  /// Automatically follows system theme (default)
  auto,

  /// Force light mode colors
  light,

  /// Force dark mode colors
  dark,
}

class SimpleNativeAd extends StatefulWidget {
  const SimpleNativeAd({
    required this.iosAdUnitId,
    required this.androidAdUnitId,
    required this.timerController,
    this.placeholder,
    this.height,
    this.refreshInterval = const Duration(minutes: 5),
    this.animationDuration = const Duration(milliseconds: 300),
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.showBorderTop = false,
    this.borderTopWidth = 1.0,
    this.borderTopColor,
    this.showBorderBottom = false,
    this.borderBottomWidth = 1.0,
    this.borderBottomColor,
    this.forceColorMode = AdColorMode.auto,
    this.backgroundColor,
    this.leftPadding,
    this.rightPadding,
    this.adChoicesPlacement,
    this.adLabel,
    this.primaryTextColor,
    this.secondaryTextColor,
    this.ctaBackgroundColor,
    this.ctaTextColor,
    this.ctaBorderColor,
    this.borderRadius = 0,
    this.pauseRefresh = false,
    super.key,
  });

  final String iosAdUnitId;
  final String androidAdUnitId;
  final SimpleNativeAdTimerController timerController;
  final Widget? placeholder;
  final double? height;
  final Duration refreshInterval;
  final Duration animationDuration;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;
  final bool showBorderTop;
  final double borderTopWidth;
  final Color? borderTopColor;
  final bool showBorderBottom;
  final double borderBottomWidth;
  final Color? borderBottomColor;
  final AdColorMode forceColorMode;
  final Color? backgroundColor;
  final double? leftPadding;
  final double? rightPadding;
  final Object? adChoicesPlacement;

  /// The text of the ad attribution badge ("Ad" when null). Give it in your
  /// app's language (for example "広告"): AdMob accepts a translation.
  final String? adLabel;

  /// The headline's color, in place of [forceColorMode]'s.
  final Color? primaryTextColor;

  /// The body's color, in place of [forceColorMode]'s.
  final Color? secondaryTextColor;

  /// The call-to-action button's fill, in place of [forceColorMode]'s blue.
  final Color? ctaBackgroundColor;

  /// The call-to-action button's text color, in place of [forceColorMode]'s
  /// white.
  final Color? ctaTextColor;

  /// A hairline around the call-to-action button (none when null).
  final Color? ctaBorderColor;

  /// Rounds the corners of the ad's background ([backgroundColor]). Not drawn
  /// with [showBorderTop] or [showBorderBottom], which stay square.
  final double borderRadius;

  /// Holds the refresh while true (no ads on this platform).
  final bool pauseRefresh;

  @override
  State<SimpleNativeAd> createState() => _SimpleNativeAdState();
}

class _SimpleNativeAdState extends State<SimpleNativeAd> {
  @override
  void didUpdateWidget(SimpleNativeAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No-op for web implementation
  }

  @override
  Widget build(BuildContext context) {
    // Web platform does not support native ads, so return an empty widget
    return const SizedBox.shrink();
  }
}
