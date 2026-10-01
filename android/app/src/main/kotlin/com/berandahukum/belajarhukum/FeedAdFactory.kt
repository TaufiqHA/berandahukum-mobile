package com.berandahukum.belajarhukum

import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

/**
 * Menampilkan iklan AdMob native (in-feed) memakai layout `admob_native_ad`.
 * Dipanggil dari Dart lewat factoryId "feedAdFactory".
 */
class FeedAdFactory(private val layoutInflater: LayoutInflater) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.admob_native_ad, null) as NativeAdView

        // `createNativeAd()` dipanggil dari callback main thread AdMob. Exception
        // yang lolos dari sini akan menutup proses aplikasi ("aplikasi berhenti").
        // Semua pengisian dibungkus try/catch: bila ada aset iklan yang tak
        // terduga, cukup lewati iklan ini alih-alih mematikan aplikasi.
        try {
            adView.mediaView = adView.findViewById<MediaView>(R.id.ad_media)
            adView.headlineView = adView.findViewById(R.id.ad_headline)
            adView.bodyView = adView.findViewById(R.id.ad_body)
            adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
            adView.iconView = adView.findViewById(R.id.ad_app_icon)
            adView.priceView = adView.findViewById(R.id.ad_price)
            adView.starRatingView = adView.findViewById(R.id.ad_stars)
            adView.storeView = adView.findViewById(R.id.ad_store)
            adView.advertiserView = adView.findViewById(R.id.ad_advertiser)

            // Headline & media selalu tersedia pada setiap NativeAd.
            (adView.headlineView as TextView).text = nativeAd.headline
            adView.mediaView?.mediaContent = nativeAd.mediaContent

            nativeAd.body?.let {
                (adView.bodyView as TextView).text = it
                adView.bodyView?.visibility = View.VISIBLE
            } ?: run { adView.bodyView?.visibility = View.INVISIBLE }

            nativeAd.callToAction?.let {
                (adView.callToActionView as Button).text = it
                adView.callToActionView?.visibility = View.VISIBLE
            } ?: run { adView.callToActionView?.visibility = View.INVISIBLE }

            nativeAd.icon?.let {
                (adView.iconView as ImageView).setImageDrawable(it.drawable)
                adView.iconView?.visibility = View.VISIBLE
            } ?: run { adView.iconView?.visibility = View.GONE }

            nativeAd.price?.let {
                (adView.priceView as TextView).text = it
                adView.priceView?.visibility = View.VISIBLE
            } ?: run { adView.priceView?.visibility = View.INVISIBLE }

            nativeAd.store?.let {
                (adView.storeView as TextView).text = it
                adView.storeView?.visibility = View.VISIBLE
            } ?: run { adView.storeView?.visibility = View.INVISIBLE }

            nativeAd.starRating?.let {
                (adView.starRatingView as RatingBar).rating = it.toFloat()
                adView.starRatingView?.visibility = View.VISIBLE
            } ?: run { adView.starRatingView?.visibility = View.INVISIBLE }

            nativeAd.advertiser?.let {
                (adView.advertiserView as TextView).text = it
                adView.advertiserView?.visibility = View.VISIBLE
            } ?: run { adView.advertiserView?.visibility = View.INVISIBLE }

            // Tandai bahwa view sudah diisi dengan iklan ini.
            adView.setNativeAd(nativeAd)
        } catch (t: Throwable) {
            Log.e(TAG, "Gagal mengisi iklan native AdMob; iklan dilewati.", t)
        }

        return adView
    }

    private companion object {
        const val TAG = "FeedAdFactory"
    }
}
