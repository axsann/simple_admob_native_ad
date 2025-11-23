import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  SimpleNativeAdState createState() => SimpleNativeAdState();
}

class SimpleNativeAdState extends State<SimpleNativeAd> {
  late final AppLifecycleListener _lifecycleListener;
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  bool _showAdWithOpacity = false;
  Timer? _timer;
  int _counter = 0;
  late final int _maxCount;

  late final _adUnitId = _getAdUnitId();

  @override
  void initState() {
    super.initState();

    _maxCount = widget.refreshInterval.inSeconds;

    widget.timerController.startTimer = startTimer;
    widget.timerController.stopTimer = stopTimer;

    _lifecycleListener = AppLifecycleListener(
      // Resume timer when app returns from background
      onResume: () {
        startTimer();
      },
      // Stop timer when app goes to background
      onPause: () {
        stopTimer();
      },
    );
    startTimer();

    _loadAd();
  }

  @override
  void didUpdateWidget(SimpleNativeAd oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload ad if forceColorMode changes
    // This ensures the new color scheme is applied
    if (oldWidget.forceColorMode != widget.forceColorMode) {
      // Dispose old ad
      _nativeAd?.dispose();
      _nativeAdIsLoaded = false;
      _showAdWithOpacity = false;

      // Load new ad with updated color mode
      _loadAd();
    }
  }

  String? _getAdUnitId() {
    if (Platform.isIOS) {
      return widget.iosAdUnitId;
    } else if (Platform.isAndroid) {
      return widget.androidAdUnitId;
    } else {
      return null;
    }
  }

  /// Loads a native ad.
  void _loadAd() {
    final adUnitId = _adUnitId;
    if (adUnitId == null) {
      return;
    }

    setState(() {
      _nativeAdIsLoaded = false;
      _showAdWithOpacity = false;
    });

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId:
          'simpleAdmobNativeAdFactory', // Factory ID implemented in native code
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('$NativeAd loaded.');
          }
          setState(() {
            _nativeAdIsLoaded = true;
          });
          // Trigger opacity animation after a frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _showAdWithOpacity = true;
              });
            }
          });
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            print('$NativeAd failedToLoad: $error');
          }
          ad.dispose();
          widget.onAdFailedToLoad?.call();
        },
        onAdClicked: (ad) {},
        onAdImpression: (ad) {},
        onAdClosed: (ad) {},
        onAdOpened: (ad) {},
        onAdWillDismissScreen: (ad) {},
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
      ),
      request: const AdRequest(),
      customOptions: {
        'colorMode': widget.forceColorMode.name,
      },
    )..load();
  }

  void startTimer() {
    if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_counter == _maxCount) {
          // Reload ad when counter reaches maxCount
          _loadAd();
          // Reset counter
          setState(() {
            _counter = 0;
          });
        } else {
          setState(() {
            _counter++;
          });
        }
      });
    }
  }

  void stopTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    stopTimer();
    _lifecycleListener.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  /// Returns the recommended height based on device type.
  /// iPad: 90.0 (optimized for tablet banner ads)
  /// iPhone: 64.0 (optimized for phone banner ads)
  double _getRecommendedHeight(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    // iPad has shortest side >= 600
    return shortestSide >= 600 ? 90.0 : 64.0;
  }

  @override
  Widget build(BuildContext context) {
    final adHeight = widget.height ?? _getRecommendedHeight(context);
    final hasBorder = widget.showBorderTop || widget.showBorderBottom;

    // Default border color based on theme
    final defaultBorderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade300;

    // Default background color based on theme (if not specified)
    final defaultBackgroundColor =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surface;

    if (_nativeAdIsLoaded && _nativeAd != null) {
      return AnimatedOpacity(
        opacity: _showAdWithOpacity ? 1.0 : 0.0,
        duration: widget.animationDuration,
        child: Container(
          height: adHeight,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: defaultBackgroundColor,
            border: hasBorder
                ? Border(
                    top: widget.showBorderTop
                        ? BorderSide(
                            color: widget.borderTopColor ?? defaultBorderColor,
                            width: widget.borderTopWidth,
                          )
                        : BorderSide.none,
                    bottom: widget.showBorderBottom
                        ? BorderSide(
                            color:
                                widget.borderBottomColor ?? defaultBorderColor,
                            width: widget.borderBottomWidth,
                          )
                        : BorderSide.none,
                  )
                : null,
          ),
          child: AdWidget(
            key: ValueKey('${_nativeAd.hashCode}_${widget.forceColorMode.name}'),
            ad: _nativeAd!,
          ),
        ),
      );
    }

    if (widget.placeholder != null) {
      return SizedBox(
        height: adHeight,
        width: double.infinity,
        child: widget.placeholder,
      );
    }

    return const SizedBox.shrink();
  }
}
