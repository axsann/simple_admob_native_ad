package com.example.simple_admob_native_ad

import android.view.LayoutInflater
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/** SimpleAdmobNativeAdPlugin */
class SimpleAdmobNativeAdPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "simple_admob_native_ad")
        channel.setMethodCallHandler(this)

        // Register NativeAdFactory automatically
        val context = flutterPluginBinding.applicationContext
        val layoutInflater = LayoutInflater.from(context)
        val nativeAdFactory = SimpleNativeAdFactory(layoutInflater, context)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterPluginBinding.flutterEngine,
            "simpleAdmobNativeAdFactory",
            nativeAdFactory
        )
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
