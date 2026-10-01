import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/theme.dart';

/// ID factory native yang didaftarkan pada platform (lihat
/// `MainActivity.kt` dan `FeedAdFactory.kt` di Android).
const String kAdMobNativeFactoryId = 'feedAdFactory';

/// Iklan AdMob format native (in-feed) untuk aplikasi mobile.
///
/// Hanya aktif di Android/iOS; di platform lain (mis. Linux desktop)
/// widget tidak menampilkan apa pun.
class AdMobNativeView extends StatefulWidget {
  /// Ad Unit ID dari panel admin.
  final String adUnitId;
  final EdgeInsets padding;

  const AdMobNativeView({
    super.key,
    required this.adUnitId,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  @override
  State<AdMobNativeView> createState() => _AdMobNativeViewState();
}

class _AdMobNativeViewState extends State<AdMobNativeView> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Tunda pemuatan iklan sampai frame pertama selesai agar pembuatan/pemuatan
    // iklan (yang menyentuh Google Play Services) tidak menghambat start-up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _load() {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    if (widget.adUnitId.isEmpty) return;

    try {
      final ad = NativeAd(
        adUnitId: widget.adUnitId,
        factoryId: kAdMobNativeFactoryId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _ad = ad as NativeAd;
              _loaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (mounted) {
              setState(() {
                _ad = null;
                _loaded = false;
              });
            }
          },
        ),
      );
      _ad = ad;
      ad.load();
    } catch (e, s) {
      // Jangan biarkan kegagalan iklan menutup aplikasi.
      debugPrint('Gagal memuat iklan native: $e\n$s');
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Padding(
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.line),
        ),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
