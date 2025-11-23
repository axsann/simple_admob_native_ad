import 'package:flutter/material.dart';
import 'package:simple_admob_native_ad/simple_admob_native_ad.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SimpleAdmobNativeAd Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _timerController = SimpleNativeAdTimerController();

  @override
  void dispose() {
    _timerController.stopTimer?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('SimpleAdmobNativeAd Example'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Item $index'),
                  subtitle: Text('This is item number $index'),
                );
              },
            ),
          ),
          // Native Ad Banner
          SafeArea(
            child: SimpleNativeAd(
              // Use test ad unit IDs from ad_util.dart
              iosAdUnitId: testNativeAdUnitIdIOS,
              androidAdUnitId: testNativeAdUnitIdAndroid,
              timerController: _timerController,
              showBorderTop: true,
            ),
          ),
        ],
      ),
    );
  }
}
