import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/theme.dart';

/// ID factory native yang didaftarkan pada platform (lihat
/// `MainActivity.kt` dan `FeedAdFactory.kt` di Android).
const String kAdMobNativeFactoryId = 'feedAdFactory';

/// Tampilkan kotak pesan error iklan di layar (untuk diagnosis).
///
/// - `true`  → kotak error tampil di **semua** mode (termasuk release).
/// - `false` → kotak error hanya tampil di mode debug (perilaku produksi).
///
/// Catatan: kotak ini hanya muncul saat iklan GAGAL; tidak memengaruhi
/// keberhasilan pemuatan iklan. Set `false` sebelum rilis produksi.
const bool kShowAdErrors = false;

/// Pembatas permintaan iklan agar app tidak menembak Ad Unit yang sama secara
/// beruntun (penyebab error SDK `code=1`
/// "Too many recently failed requests for ad unit ID ... You must wait a few
/// seconds before making another ad request").
///
/// Satu Ad Unit hanya boleh diminta **sekali per [cooldown]**. Setelah jeda itu,
/// unit boleh diminta lagi — berbeda dengan "sekali per sesi" yang membuat
/// iklan tak pernah muncul lagi begitu satu permintaan gagal (termasuk saat
/// masih kena throttle SDK atau NO_FILL).
///
/// Untuk kembali ke perilaku "sekali per sesi", set [cooldown] sangat besar
/// (mis. `Duration(days: 36500)`). Untuk menonaktifkan, set ke `Duration.zero`.
class AdMobRequestThrottle {
  AdMobRequestThrottle._();

  /// Jeda minimum antar permintaan untuk unit yang sama.
  static const Duration cooldown = Duration(seconds: 60);

  static final Map<String, DateTime> _lastRequest = <String, DateTime>{};

  /// Kembalikan `true` bila [adUnitId] boleh diminta sekarang, lalu catat
  /// waktunya. Kembalikan `false` bila masih dalam masa cooldown.
  static bool allow(String adUnitId) {
    if (adUnitId.isEmpty) return true; // unit kosong ditangani di tempat lain.
    if (cooldown == Duration.zero) return true;
    final DateTime now = DateTime.now();
    final DateTime? last = _lastRequest[adUnitId];
    if (last != null && now.difference(last) < cooldown) return false;
    _lastRequest[adUnitId] = now;
    return true;
  }
}

/// Cache iklan yang **sudah dimuat**, per Ad Unit ID.
///
/// Widget iklan bisa dibuat ulang saat di-scroll jauh dari viewport atau saat
/// halaman di-refresh. Tanpa cache, iklan yang sudah dimuat ikut dibuang dan
/// permintaan baru diblokir cooldown, sehingga iklan "hilang". Dengan cache,
/// widget baru memakai ulang iklan yang sama tanpa mengirim permintaan baru.
///
/// Hanya satu widget yang memegang satu iklan pada satu waktu (`take`/`store`).
class AdMobAdCache {
  AdMobAdCache._();

  static final Map<String, Ad> _cache = <String, Ad>{};

  /// Ambil (dan hapus dari cache) iklan untuk [adUnitId], bila ada.
  static Ad? take(String adUnitId) => _cache.remove(adUnitId);

  /// Simpan iklan ke cache agar bisa dipakai ulang.
  static void store(String adUnitId, Ad ad) => _cache[adUnitId] = ad;

  /// Buang iklan dari cache (dan dispose) untuk [adUnitId].
  static void drop(String adUnitId) => _cache.remove(adUnitId)?.dispose();
}

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

class _AdMobNativeViewState extends State<AdMobNativeView>
    with AutomaticKeepAliveClientMixin {
  NativeAd? _ad;
  bool _loaded = false;

  /// True bila unit iklan ini sudah diminta di widget lain pada sesi ini,
  /// sehingga widget ini tidak menampilkan apa pun.
  bool _skipped = false;

  /// Pesan kegagalan terakhir (hanya ditampilkan saat mode debug) agar
  /// penyebab iklan tak muncul bisa dilihat langsung tanpa membuka logcat.
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pakai ulang iklan yang sudah dimuat untuk unit ini bila ada (mis. widget
    // ini dibuat ulang setelah di-scroll jauh atau halaman di-refresh).
    final Ad? cached = AdMobAdCache.take(widget.adUnitId);
    if (cached is NativeAd) {
      _ad = cached;
      _loaded = true;
      return;
    }
    if (cached != null) cached.dispose();

    // Hindari menembak unit yang sama beruntun (lihat AdMobRequestThrottle).
    if (!AdMobRequestThrottle.allow(widget.adUnitId)) {
      _skipped = true;
      debugPrint('AdMob: native unit ${widget.adUnitId} DILEWATI '
          '(unit ini sudah diminta/duplikat dalam ${AdMobRequestThrottle.cooldown.inSeconds}s).');
      return;
    }
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
    // Simpan iklan yang sudah dimuat ke cache agar bisa dipakai ulang oleh
    // widget berikutnya (widget ini bisa dibuat ulang saat scroll/refresh).
    if (_loaded && _ad != null) {
      AdMobAdCache.store(widget.adUnitId, _ad!);
    } else {
      _ad?.dispose();
    }
    super.dispose();
  }

  /// Tinggi tetap slot iklan native (logical px).
  ///
  /// `AdWidget` di Android memakai platform view (`PlatformViewLink`).
  /// Kalau tinggi item di dalam `ListView` berubah dari 0 (placeholder
  /// `SizedBox.shrink`) menjadi tinggi iklan tepat saat platform view dipasang,
  /// `RenderSliverList` menghitung koreksi scroll secara re-entrant dan memicu
  /// assertion `'!_debugDoingThisLayout'` yang membuat seluruh layar putih.
  ///
  /// Dengan mereservasi tinggi yang sama sejak sebelum iklan dimuat, geometri
  /// item tidak pernah berubah sehingga masalah itu terhindar.
  ///
  /// Nilai ini kira-kira setinggi layout `admob_native_ad.xml` (MediaView 180dp
  /// + judul/isi/tombol + padding). Sesuaikan bila iklan terlihat terpotong.
  static const double _nativeAdHeight = 380;

  // Supaya widget iklan tidak dibuang saat di-scroll jauh dari viewport.
  // Tanpa ini, iklan dimuat ulang tiap kali masuk viewport lagi dan memicu
  // throttle ("DILEWATI") serta potensi iklan hilang.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib untuk AutomaticKeepAliveClientMixin.
    // Hanya Android/iOS yang menampilkan iklan. Di platform lain (Linux
    // desktop, web, atau lingkungan tes) tidak menampilkan apa pun dan tidak
    // mereservasi ruang.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    if (_skipped) return const SizedBox.shrink();

    final bool ready = _loaded && _ad != null;

    // Gagal memuat: tampilkan kotak pesan error supaya penyebab iklan tak
    // muncul langsung terlihat di layar (lihat [kShowAdErrors]).
    if (!ready && _error != null) {
      if (!kShowAdErrors && !kDebugMode) return const SizedBox.shrink();
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
            'AdMob gagal memuat: $_error',
            style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 11),
          ),
        ),
      );
    }

    // Sedang dimuat maupun sudah dimuat memakai tinggi yang sama persis, agar
    // tinggi item di ListView tidak berubah saat platform view dipasang.
    return Padding(
      padding: widget.padding,
      child: SizedBox(
        height: _nativeAdHeight,
        child: ready
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.line),
                ),
                child: AdWidget(ad: _ad!),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// UJI SEMENTARA ukuran banner AdMob.
///
/// - `true`  → `AdSize.fluid` (fitur Ad Manager; AdMob mungkin tidak melayani
///   sehingga tetap NO_FILL / HTTP 403).
/// - `false` → anchored adaptive (default, direkomendasikan Google untuk
///   in-feed).
///
/// Set kembali ke `false` setelah pengujian.
const bool _kTestFluidBanner = false;

/// Iklan AdMob format banner (in-feed). Hanya aktif di Android/iOS.
class AdMobBannerView extends StatefulWidget {
  /// Ad Unit ID dari panel admin.
  final String adUnitId;
  final EdgeInsets padding;

  const AdMobBannerView({
    super.key,
    required this.adUnitId,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  @override
  State<AdMobBannerView> createState() => _AdMobBannerViewState();
}

class _AdMobBannerViewState extends State<AdMobBannerView>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _ad;
  bool _loaded = false;
  bool _started = false;

  /// True bila unit iklan ini sudah diminta di widget lain pada sesi ini.
  bool _skipped = false;

  String? _error;

  /// Ukuran banner yang diminta (dihitung sebelum `load()`). Dipakai untuk
  /// mereservasi tinggi slot sejak sebelum iklan dimuat. Lihat catatan pada
  /// `_nativeAdHeight` di `_AdMobNativeViewState`.
  AdSize? _size;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Pakai ulang iklan banner yang sudah dimuat untuk unit ini bila ada.
    final Ad? cached = AdMobAdCache.take(widget.adUnitId);
    if (cached is BannerAd) {
      _ad = cached;
      _size = cached.size;
      _loaded = true;
      return;
    }
    if (cached != null) cached.dispose();

    // Hindari menembak unit yang sama beruntun (lihat AdMobRequestThrottle).
    if (!AdMobRequestThrottle.allow(widget.adUnitId)) {
      _skipped = true;
      debugPrint('AdMob: banner unit ${widget.adUnitId} DILEWATI '
          '(unit ini sudah diminta/duplikat dalam ${AdMobRequestThrottle.cooldown.inSeconds}s).');
      return;
    }
    // Lebar untuk banner adaptif HARUS sama dengan lebar container iklan
    // (bukan lebar layar penuh), karena ada padding horizontal. Google
    // menyarankan lebar permintaan = lebar view tempat iklan dirender; kalau
    // berbeda, iklan bisa tampak melar/terpotong.
    final double width =
        MediaQuery.sizeOf(context).width - widget.padding.horizontal;
    // Dimuat setelah frame pertama agar tidak menghambat start-up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(width.truncate());
    });
  }

  Future<void> _load(int width) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    if (widget.adUnitId.isEmpty) {
      debugPrint('AdMob: Ad Unit ID banner kosong, iklan dilewati.');
      return;
    }

    // Ukuran banner.
    AdSize size;
    if (_kTestFluidBanner) {
      // UJI: fluid (fitur Ad Manager). Tinggi/lebar sebenarnya tidak dipakai
      // untuk request; widget dirender dalam slot berukuran tetap (lihat build).
      size = AdSize.fluid;
    } else {
      // Adaptive: lebar permintaan = lebar container (lihat didChangeDependencies).
      size = AdSize.banner;
      try {
        size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ?? AdSize.banner;
      } catch (_) {
        size = AdSize.banner;
      }
    }
    if (!mounted) return;

    // Simpan ukuran yang diminta lebih dulu supaya slot bisa mereservasi tinggi
    // sebelum platform view iklan dipasang.
    setState(() => _size = size);

    try {
      final ad = BannerAd(
        adUnitId: widget.adUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('AdMob: banner dimuat (${widget.adUnitId}).');
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _ad = ad as BannerAd;
              _loaded = true;
              _error = null;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              'AdMob: gagal memuat banner. '
              'code=${error.code} domain=${error.domain} message=${error.message}',
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
      debugPrint('AdMob: gagal memuat banner: $e\n$s');
    }
  }

  @override
  void dispose() {
    // Simpan iklan yang sudah dimuat ke cache agar bisa dipakai ulang oleh
    // widget berikutnya (widget ini bisa dibuat ulang saat scroll/refresh).
    if (_loaded && _ad != null) {
      AdMobAdCache.store(widget.adUnitId, _ad!);
    } else {
      _ad?.dispose();
    }
    super.dispose();
  }

  // Supaya widget banner tidak dibuang saat di-scroll jauh dari viewport.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib untuk AutomaticKeepAliveClientMixin.
    // Hanya Android/iOS yang menampilkan iklan.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    if (_skipped) return const SizedBox.shrink();

    // Ukuran reservasi slot, dihitung sejak sebelum dimuat supaya tinggi item
    // di ListView tidak berubah saat platform view AdWidget dipasang (mencegah
    // assertion '!_debugDoingThisLayout').
    //
    // `AdSize.fluid` bernilai -3 (lebar/tinggi tidak valid), jadi hanya pakai
    // nilai positif; kalau tidak ada, pakai default.
    final int? knownHeight = _size?.height ?? _ad?.size.height;
    final int? knownWidth = _size?.width ?? _ad?.size.width;
    final double reservedHeight =
        (knownHeight != null && knownHeight > 0) ? knownHeight.toDouble() : 100.0;
    final double adWidth = (knownWidth != null && knownWidth > 0)
        ? knownWidth.toDouble()
        : double.infinity;

    if (!_loaded || _ad == null) {
      if (_error != null) {
        if (!kShowAdErrors && !kDebugMode) return const SizedBox.shrink();
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
              'AdMob banner gagal memuat: $_error',
              style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 11),
            ),
          ),
        );
      }
      // Masih memuat: reservasi ruang setinggi banner.
      return Padding(
        padding: widget.padding,
        child: SizedBox(height: reservedHeight, width: double.infinity),
      );
    }
    return Padding(
      padding: widget.padding,
      child: Center(
        child: SizedBox(
          width: adWidth,
          height: reservedHeight,
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
