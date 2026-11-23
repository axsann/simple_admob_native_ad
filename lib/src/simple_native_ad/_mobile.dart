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
  final AdChoicesPlacement? adChoicesPlacement;

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

  /// Holds the refresh while true: the ad on show stays, and no new one is
  /// loaded until it's false again (the app coming back from the background
  /// doesn't start it either, nor does [SimpleNativeAdTimerController]). Set
  /// it while the ad can't be seen, scrolled away in a list or under the app's
  /// bars, say: an ad shouldn't be replaced where nobody sees it. The first ad
  /// still loads.
  final bool pauseRefresh;

  @override
  SimpleNativeAdState createState() => SimpleNativeAdState();
}

class SimpleNativeAdState extends State<SimpleNativeAd> {
  late final AppLifecycleListener _lifecycleListener;

  /// The ad on show (null until the first one loads).
  NativeAd? _nativeAd;

  /// The one it replaced, fading out under it, then disposed.
  NativeAd? _leaving;

  /// The next one, loading (the first, or a refresh's): the one on show stays
  /// meanwhile, and if it fails.
  NativeAd? _loading;

  /// The first ad has faded in (the whole ad, its background too).
  bool _showAdWithOpacity = false;

  /// The ad on show has faded in over the one it replaced.
  bool _arrived = true;

  Timer? _timer;
  Timer? _swap;

  /// Seconds since the last load. Not state: nothing shows it (it was set
  /// with setState every second, building the ad again for nothing).
  int _counter = 0;

  late final _adUnitId = _getAdUnitId();

  @override
  void initState() {
    super.initState();

    widget.timerController.startTimer = startTimer;
    widget.timerController.stopTimer = stopTimer;

    _lifecycleListener = AppLifecycleListener(
      // Resume timer when app returns from background
      onResume: startTimer,
      // Stop timer when app goes to background
      onPause: stopTimer,
    );
    startTimer();

    _loadAd();
  }

  @override
  void didUpdateWidget(SimpleNativeAd oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pauseRefresh != widget.pauseRefresh) {
      final resumed =
          WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      if (widget.pauseRefresh) {
        stopTimer();
      } else if (resumed) {
        startTimer();
      }
    }

    // Reload ad if forceColorMode, the layout or the style changes
    // This ensures the new color scheme is applied
    if (oldWidget.forceColorMode != widget.forceColorMode ||
        oldWidget.layout != widget.layout ||
        !mapEquals(_styleOptions(oldWidget), _styleOptions(widget))) {
      // Dispose old ads
      _disposeAds();
      _showAdWithOpacity = false;
      _arrived = true;

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

  /// Loads a native ad: the first, or the next one. The one on show stays
  /// until the next has loaded, then fades into it ([_show]); until 2.4.0 it
  /// went at once and the placeholder showed while the next loaded (a blink
  /// every refresh), and it was never disposed.
  void _loadAd() {
    final adUnitId = _adUnitId;
    if (adUnitId == null || _loading != null) {
      return;
    }

    _loading = NativeAd(
      adUnitId: adUnitId,
      factoryId:
          'simpleAdmobNativeAdFactory', // Factory ID implemented in native code
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('$NativeAd loaded.');
          }
          if (!mounted || !identical(ad, _loading)) {
            return;
          }
          _loading = null;
          _show(ad as NativeAd);
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            print('$NativeAd failedToLoad: $error');
          }
          ad.dispose();
          if (!mounted || !identical(ad, _loading)) {
            return;
          }
          _loading = null;
          // A refresh that failed keeps the ad on show: nothing to tell.
          if (_nativeAd == null) {
            widget.onAdFailedToLoad?.call();
          }
        },
        onAdClicked: (ad) {},
        onAdImpression: (ad) {},
        onAdClosed: (ad) {},
        onAdOpened: (ad) {},
        onAdWillDismissScreen: (ad) {},
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
      ),
      request: const AdRequest(),
      nativeAdOptions: widget.adChoicesPlacement != null
          ? NativeAdOptions(adChoicesPlacement: widget.adChoicesPlacement)
          : null,
      customOptions: {
        'colorMode': widget.forceColorMode.name,
        'layout': widget.layout.name,
        if (widget.leftPadding != null) 'leftPadding': widget.leftPadding!,
        if (widget.rightPadding != null) 'rightPadding': widget.rightPadding!,
        ..._styleOptions(widget),
      },
    )..load();
  }

  /// Puts [ad] on show: the first fades in, a later one fades in over the one
  /// before, which fades out and is disposed once it's out of the tree.
  void _show(NativeAd ad) {
    final before = _nativeAd;
    // One still leaving from a refresh before (no time to finish): gone now.
    _dropLeaving();
    setState(() {
      _nativeAd = ad;
      _leaving = before;
      _arrived = before == null;
    });
    // After a frame, with its view in place (transparent).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_nativeAd, ad)) {
        return;
      }
      setState(() {
        _showAdWithOpacity = true;
        _arrived = true;
      });
    });
    if (before != null) {
      _swap = Timer(
        widget.animationDuration + const Duration(milliseconds: 100),
        () {
          if (mounted) {
            setState(_dropLeaving);
          }
        },
      );
    }
  }

  /// Takes the leaving ad out, and disposes it once its view is out of the
  /// tree (after the frame).
  void _dropLeaving() {
    _swap?.cancel();
    _swap = null;
    final leaving = _leaving;
    if (leaving == null) {
      return;
    }
    _leaving = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => leaving.dispose());
  }

  void _disposeAds() {
    _swap?.cancel();
    _swap = null;
    _nativeAd?.dispose();
    _leaving?.dispose();
    _loading?.dispose();
    _nativeAd = null;
    _leaving = null;
    _loading = null;
  }

  /// The label and colors the native side draws with (colors as 0xAARRGGBB).
  static Map<String, Object> _styleOptions(SimpleNativeAd widget) => {
    if (widget.adLabel != null) 'adLabel': widget.adLabel!,
    if (widget.primaryTextColor != null)
      'primaryTextColor': widget.primaryTextColor!.toARGB32(),
    if (widget.secondaryTextColor != null)
      'secondaryTextColor': widget.secondaryTextColor!.toARGB32(),
    if (widget.ctaBackgroundColor != null)
      'ctaBackgroundColor': widget.ctaBackgroundColor!.toARGB32(),
    if (widget.ctaTextColor != null)
      'ctaTextColor': widget.ctaTextColor!.toARGB32(),
    if (widget.ctaBorderColor != null)
      'ctaBorderColor': widget.ctaBorderColor!.toARGB32(),
  };

  /// Starts the refresh (not while [SimpleNativeAd.pauseRefresh]).
  void startTimer() {
    if (!mounted || widget.pauseRefresh || (_timer?.isActive ?? false)) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _counter++;
      if (_counter >= widget.refreshInterval.inSeconds) {
        // Reload ad when the interval has passed
        _counter = 0;
        _loadAd();
      }
    });
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
    _disposeAds();
    super.dispose();
  }

  /// Returns the recommended height based on device type and layout, with
  /// the [SimpleNativeAd.padding] around the ad.
  /// Row: iPad 90.0 (optimized for tablet banner ads), iPhone 64.0
  /// (optimized for phone banner ads).
  /// Stacked: iPad 164.0, iPhone 122.0 (a 56-point icon over a 40-point
  /// button).
  double _getRecommendedHeight(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    // iPad has shortest side >= 600
    final tablet = shortestSide >= 600;
    final ad = switch (widget.layout) {
      AdLayout.row => tablet ? 90.0 : 64.0,
      AdLayout.stacked => tablet ? 164.0 : 122.0,
    };
    return ad + widget.padding.vertical;
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

    final nativeAd = _nativeAd;
    if (nativeAd != null) {
      final leaving = _leaving;
      return AnimatedOpacity(
        opacity: _showAdWithOpacity ? 1.0 : 0.0,
        duration: widget.animationDuration,
        child: LayoutBuilder(
          // As wide as the slot it's given (inset in a card, say), else the
          // screen.
          builder: (context, constraints) => Container(
            height: adHeight,
            width: constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: defaultBackgroundColor,
              borderRadius: !hasBorder && widget.borderRadius > 0
                  ? BorderRadius.circular(widget.borderRadius)
                  : null,
              border: hasBorder
                  ? Border(
                      top: widget.showBorderTop
                          ? BorderSide(
                              color:
                                  widget.borderTopColor ?? defaultBorderColor,
                              width: widget.borderTopWidth,
                            )
                          : BorderSide.none,
                      bottom: widget.showBorderBottom
                          ? BorderSide(
                              color:
                                  widget.borderBottomColor ??
                                  defaultBorderColor,
                              width: widget.borderBottomWidth,
                            )
                          : BorderSide.none,
                    )
                  : null,
            ),
            // Inset from the background's edges (the AdChoices icon in the
            // ad's corner stays inside a rounded one).
            padding: widget.padding,
            // The one before fades out as the new one fades in (a refresh).
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (leaving != null)
                  AnimatedOpacity(
                    key: ObjectKey(leaving),
                    opacity: _arrived ? 0.0 : 1.0,
                    duration: widget.animationDuration,
                    child: AdWidget(ad: leaving),
                  ),
                AnimatedOpacity(
                  key: ObjectKey(nativeAd),
                  opacity: _arrived ? 1.0 : 0.0,
                  duration: widget.animationDuration,
                  child: AdWidget(ad: nativeAd),
                ),
              ],
            ),
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
