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

/// How the ad's parts are laid out in its slot.
enum AdLayout {
  /// The icon, the text beside it, and the call-to-action button at the end
  /// of the row (default). A banner: 64 points high on a phone, 90 on a
  /// tablet.
  row,

  /// The icon and the text beside it, and the call-to-action button on its
  /// own line under them, as wide as the ad. 122 points high on a phone, 164
  /// on a tablet. The icon grows or shrinks with the height (the height left
  /// over the button).
  stacked,
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
    this.layout = AdLayout.row,
    this.padding = EdgeInsets.zero,
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

  /// How the ad's parts are laid out: [AdLayout.row] (the button beside the
  /// text) or [AdLayout.stacked] (the button on its own line under it).
  /// Changing it reloads the ad.
  final AdLayout layout;

  /// Space between the edges of the background ([backgroundColor]) and the
  /// ad's own view, inside [height]. The AdChoices icon sits in the corner of
  /// the ad's view, so with a [borderRadius] it would stick out of the
  /// rounded corner. Give about 6 for a radius of 16: the icon is a 15-point
  /// square with corners rounded by about 3, and with 6 its corner keeps about
  /// 3 points clear of the curve (measured on an iPhone). With 4 it stays
  /// inside but its corner touches the curve (0.2 points).
  final EdgeInsetsGeometry padding;

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
