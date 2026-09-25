import 'package:flutter/foundation.dart';

/// Sinyal global agar beranda memuat ulang datanya.
///
/// Dipakai mis. setelah iklan antar-kategori diubah di panel admin, supaya
/// iklan langsung tampil di beranda tanpa perlu menutup aplikasi.
final ValueNotifier<int> homeReloadSignal = ValueNotifier<int>(0);

/// Minta beranda memuat ulang.
void requestHomeReload() => homeReloadSignal.value++;
