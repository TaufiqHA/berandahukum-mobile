import 'dart:io';

import 'package:flutter/foundation.dart';
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

  /// Pesan kegagalan terakhir (hanya ditampilkan saat mode debug) agar
  /// penyebab iklan tak muncul bisa dilihat langsung tanpa membuka logcat.
  String? _error;

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
    if (widget.adUnitId.isEmpty) {
      debugPrint('AdMob: Ad Unit ID kosong, iklan dilewati.');
      return;
    }

    try {
      final ad = NativeAd(
        adUnitId: widget.adUnitId,
        factoryId: kAdMobNativeFactoryId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint('AdMob: native ad dimuat (${widget.adUnitId}).');
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _ad = ad as NativeAd;
              _loaded = true;
              _error = null;
            });
          },
          onAdFailedToLoad: (ad, error) {
            // Kode pesan penting: 0 = internal, 1 = invalid request,
            // 2 = network, 3 = no fill (tidak ada iklan untuk ditayangkan).
            debugPrint(
              'AdMob: gagal memuat native ad. '
              'code=${error.code} domain=${error.domain} '
              'message=${error.message}',
            );
            ad.dispose();
            if (mounted) {
              setState(() {
                _ad = null;
                _loaded = false;
                _error = '${error.code}: ${error.message}';
              });
            }
          },
        ),
      );
      _ad = ad;
      ad.load();
    } catch (e, s) {
      // Jangan biarkan kegagalan iklan menutup aplikasi.
      debugPrint('AdMob: gagal memuat iklan native: $e\n$s');
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) {
      // Di mode debug, tampilkan kotak kecil berisi kode error supaya penyebab
      // iklan tak muncul langsung terlihat di layar (bukan cuma di logcat).
      if (kDebugMode && _error != null) {
        return Padding(
          padding: widget.padding,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              border: Border.all(color: const Color(0xFFE0B4B4)),
            ),
            child: Text(
              'AdMob gagal memuat (debug): $_error',
              style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 11),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }
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
