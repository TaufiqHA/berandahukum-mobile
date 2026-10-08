import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Mengelola iklan AdMob full-screen: interstitial, app open, dan reward.
///
/// Iklan inline (native/banner/gambar) dirender langsung oleh widget di
/// `site_widgets.dart`/`admob_view.dart`. Service ini hanya menangani format
/// yang memenuhi layar dan dipicu oleh navigasi/aksi pengguna.
class AdManager {
  AdManager._();

  /// Instance tunggal aplikasi.
  static final AdManager instance = AdManager._();

  static bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ---- Konfigurasi Ad Unit (berasal dari data beranda) ----
  String? _interstitialUnit;
  String? _appOpenUnit;
  String? _rewardUnit;

  // ---- Iklan yang sudah dimuat ----
  InterstitialAd? _interstitial;
  AppOpenAd? _appOpen;
  RewardedAd? _reward;

  bool _loadingInterstitial = false;
  bool _loadingAppOpen = false;
  bool _loadingReward = false;

  /// True saat configure pertama (cold start): app open ditampilkan begitu
  /// selesai dimuat.
  bool _configuredOnce = false;
  bool _showAppOpenWhenReady = false;

  // ---- Pengaturan frekuensi ----
  int _articleOpens = 0;
  DateTime? _lastInterstitial;
  DateTime? _lastAppOpen;

  /// Interstitial ditampilkan tiap sekian pembukaan artikel.
  static const int _interstitialEvery = 3;

  /// Jeda minimum antar interstitial.
  static const Duration _interstitialCooldown = Duration(minutes: 2);

  /// Jeda minimum antar app open.
  static const Duration _appOpenCooldown = Duration(minutes: 4);

  static const String _prefLastAppOpen = 'admob_last_app_open_ms';

  /// Terapkan konfigurasi dari data beranda. Dipanggil setiap kali beranda
  /// selesai dimuat; aman dipanggil berulang.
  void configure(HomeData data) {
    if (!_supported) return;

    _interstitialUnit = _unitOf(data.adsInterstitial);
    _appOpenUnit = _unitOf(data.adsAppOpen);
    _rewardUnit = _unitOf(data.adsReward);

    if (!_configuredOnce) {
      _configuredOnce = true;
      _showAppOpenWhenReady = true;
    }

    _loadInterstitial();
    _loadAppOpen();
  }

  String? _unitOf(AdBanner? ad) {
    if (ad == null || !ad.isFullScreen) return null;
    final unit = ad.admobUnit;
    return (unit == null || unit.isEmpty) ? null : unit;
  }

  // ---------------------------------------------------------------------------
  // Interstitial — tampil saat membuka artikel.
  // ---------------------------------------------------------------------------

  void _loadInterstitial() {
    final unit = _interstitialUnit;
    if (unit == null || _interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          debugPrint('AdMob: gagal memuat interstitial. ${error.code}: ${error.message}');
        },
      ),
    );
  }

  /// Panggil saat pengguna membuka artikel. Menampilkan interstitial secara
  /// berkala (tiap [_interstitialEvery] pembukaan, dengan jeda
  /// [_interstitialCooldown]).
  void maybeShowInterstitial() {
    if (!_supported) return;
    _articleOpens++;

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    if (_articleOpens < _interstitialEvery) return;
    if (_lastInterstitial != null &&
        DateTime.now().difference(_lastInterstitial!) < _interstitialCooldown) {
      return;
    }

    _articleOpens = 0;
    _lastInterstitial = DateTime.now();
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob: gagal menampilkan interstitial. ${error.code}: ${error.message}');
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }

  // ---------------------------------------------------------------------------
  // App open — tampil saat aplikasi dibuka/dikembalikan dari background.
  // ---------------------------------------------------------------------------

  void _loadAppOpen() {
    final unit = _appOpenUnit;
    if (unit == null || _appOpen != null || _loadingAppOpen) return;
    _loadingAppOpen = true;
    AppOpenAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingAppOpen = false;
          _appOpen = ad;
          if (_showAppOpenWhenReady) {
            _showAppOpenWhenReady = false;
            maybeShowAppOpen();
          }
        },
        onAdFailedToLoad: (error) {
          _loadingAppOpen = false;
          debugPrint('AdMob: gagal memuat app open. ${error.code}: ${error.message}');
        },
      ),
    );
  }

  /// Tampilkan app open bila tersedia dan jeda sudah lewat. Dipanggil saat
  /// aplikasi diluncurkan atau kembali ke foreground.
  Future<void> maybeShowAppOpen() async {
    if (!_supported) return;
    final ad = _appOpen;
    if (ad == null) {
      _loadAppOpen();
      return;
    }

    final last = _lastAppOpen ?? await _readLastAppOpen();
    if (last != null && DateTime.now().difference(last) < _appOpenCooldown) {
      return;
    }

    _lastAppOpen = DateTime.now();
    _appOpen = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob: gagal menampilkan app open. ${error.code}: ${error.message}');
        ad.dispose();
        _loadAppOpen();
      },
    );
    ad.show();
    _persistLastAppOpen(_lastAppOpen!);
  }

  Future<DateTime?> _readLastAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_prefLastAppOpen);
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  void _persistLastAppOpen(DateTime t) {
    SharedPreferences.getInstance()
        .then((p) => p.setInt(_prefLastAppOpen, t.millisecondsSinceEpoch))
        .catchError((Object _) => false);
  }

  // ---------------------------------------------------------------------------
  // Reward — ditampilkan atas aksi pengguna.
  // ---------------------------------------------------------------------------

  /// True bila ada Ad Unit reward yang dikonfigurasi.
  bool get hasReward => _rewardUnit != null;

  /// Muat (bila perlu) lalu tampilkan iklan reward. [onReward] dipanggil bila
  /// pengguna menonton sampai selesai.
  Future<void> showReward({VoidCallback? onReward}) async {
    if (!_supported) return;
    final unit = _rewardUnit;
    if (unit == null) return;

    final loaded = _reward;
    if (loaded != null) {
      _presentReward(loaded, onReward);
      return;
    }
    if (_loadingReward) return;

    _loadingReward = true;
    RewardedAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingReward = false;
          _presentReward(ad, onReward);
        },
        onAdFailedToLoad: (error) {
          _loadingReward = false;
          debugPrint('AdMob: gagal memuat reward. ${error.code}: ${error.message}');
        },
      ),
    );
  }

  void _presentReward(RewardedAd ad, VoidCallback? onReward) {
    _reward = null;
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (earned) onReward?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob: gagal menampilkan reward. ${error.code}: ${error.message}');
        ad.dispose();
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) {
      earned = true;
    });
  }
}
