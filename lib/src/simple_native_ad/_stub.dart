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

  @override
  State<SimpleNativeAd> createState() => _SimpleNativeAdState();
}

class _SimpleNativeAdState extends State<SimpleNativeAd> {
  @override
  void didUpdateWidget(SimpleNativeAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No-op for stub implementation
  }

  @override
  Widget build(BuildContext context) {
    // Desktop platforms (macOS, Windows, Linux) do not support native ads, so return an empty widget
    return const SizedBox.shrink();
  }
}
