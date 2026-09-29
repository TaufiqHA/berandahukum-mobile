package com.berandahukum.belajarhukum

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import io.flutter.plugins.googlemobileads.NativeAdFactory

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Daftarkan factory iklan AdMob native (in-feed) untuk aplikasi.
        val factory: NativeAdFactory = FeedAdFactory(layoutInflater)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, FEED_AD_FACTORY_ID, factory)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, FEED_AD_FACTORY_ID)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private companion object {
        // Harus sama dengan kAdMobNativeFactoryId di lib/widgets/admob_view.dart.
        const val FEED_AD_FACTORY_ID = "feedAdFactory"
    }
}
