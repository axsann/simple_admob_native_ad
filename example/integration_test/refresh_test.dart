// The refresh, with Google's test ads (2.4.0): the ad on show stays until the
// next one has loaded and cross-fades into it (no placeholder in between), the
// one it replaced is disposed, and pauseRefresh holds it.
//
//   cd example && flutter test integration_test/refresh_test.dart -d <device>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// To see whether an ad was disposed (its id is gone).
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:integration_test/integration_test.dart';
import 'package:simple_admob_native_ad/simple_admob_native_ad.dart';

const placeholder = Key('placeholder');

/// The ads whose views are in the tree, the one on show last.
List<NativeAd> shown(WidgetTester tester) => [
  for (final widget in tester.widgetList<AdWidget>(find.byType(AdWidget)))
    widget.ad as NativeAd,
];

/// Pumps frames for [duration], failing if the placeholder shows.
Future<void> watch(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(placeholder), findsNothing);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a refresh cross-fades, disposes the ad before, and pauses', (
    tester,
  ) async {
    await MobileAds.instance.initialize();
    final timer = SimpleNativeAdTimerController();
    final pause = ValueNotifier(false);
    var failed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ValueListenableBuilder(
              valueListenable: pause,
              builder: (context, paused, _) => SimpleNativeAd(
                iosAdUnitId: testNativeAdUnitIdIOS,
                androidAdUnitId: testNativeAdUnitIdAndroid,
                timerController: timer,
                refreshInterval: const Duration(seconds: 5),
                pauseRefresh: paused,
                placeholder: const ColoredBox(
                  key: placeholder,
                  color: Colors.grey,
                ),
                onAdFailedToLoad: () => failed++,
              ),
            ),
          ),
        ),
      ),
    );

    // The first ad (the SDK starting can take a while on an emulator).
    final end = DateTime.now().add(const Duration(seconds: 90));
    while (shown(tester).isEmpty && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(shown(tester), hasLength(1));
    final first = shown(tester).single;

    // Refreshed: never the placeholder, at most the two cross-fading, then the
    // next one alone, and the first disposed.
    var most = 0;
    final until = DateTime.now().add(const Duration(seconds: 12));
    while (DateTime.now().isBefore(until)) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(placeholder), findsNothing);
      most = shown(tester).length > most ? shown(tester).length : most;
      if (shown(tester).length == 1 &&
          !identical(shown(tester).single, first)) {
        break;
      }
    }
    expect(most, 2, reason: 'the two cross-fade');
    await watch(tester, const Duration(seconds: 1));
    final second = shown(tester).single;
    expect(identical(second, first), isFalse);
    expect(instanceManager.adIdFor(first), isNull, reason: 'disposed');
    expect(instanceManager.adIdFor(second), isNotNull);

    // Paused: the same ad past two intervals.
    pause.value = true;
    await watch(tester, const Duration(seconds: 12));
    expect(identical(shown(tester).single, second), isTrue);

    // Going on again: the next refresh comes.
    pause.value = false;
    final again = DateTime.now().add(const Duration(seconds: 15));
    while (identical(shown(tester).last, second) &&
        DateTime.now().isBefore(again)) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(placeholder), findsNothing);
    }
    expect(identical(shown(tester).last, second), isFalse);
    await watch(tester, const Duration(seconds: 1));
    expect(instanceManager.adIdFor(second), isNull, reason: 'disposed');
    expect(failed, 0);

    // Gone: every ad disposed.
    final last = shown(tester).single;
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(instanceManager.adIdFor(last), isNull);
  });
}
