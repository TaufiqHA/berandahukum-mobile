# =============================================================================
# Aturan R8/ProGuard untuk build release.
#
# Sejak Flutter 3.4x, gradle plugin Flutter mengaktifkan R8 (minify +
# shrinkResources) secara default pada build release. Tanpa aturan keep di
# bawah, sebagian library yang memakai refleksi ikut terhapus/ter-obfuscate dan
# aplikasi crash saat start-up (sebelum UI tampil).
# =============================================================================

# --- Room / WorkManager ------------------------------------------------------
# WorkManager tidak dipakai langsung oleh kode Dart, tetapi ditarik oleh AdMob
# (google_mobile_ads). Saat start-up, WorkManagerInitializer membuat database
# internalnya lewat Room, yang mencari kelas generated secara refleksi:
#   Class.forName("androidx.work.impl.WorkDatabase_Impl")
#         .getDeclaredConstructor().newInstance()
# R8 tidak dapat melihat pemakaian refleksi ini sehingga menghapus konstruktor
# no-arg WorkDatabase_Impl. Akibatnya proses Android crash dengan pesan:
#   "Failed to create an instance of androidx.work.impl.WorkDatabase"
# Jaga seluruh subclass RoomDatabase beserta konstruktor no-arg-nya.
-keep class * extends androidx.room.RoomDatabase { <init>(); }

# Jaga Worker kustom (kalau nanti ada) dari penghapusan.
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

-dontwarn androidx.room.paging.**

# --- Google Mobile Ads / AdMob ----------------------------------------------
# Sebagian jalur native ad (aset iklan, template, dan kelas Dynamite yang
# dimuat lewat refleksi) bisa tidak terlihat oleh R8 sehingga terhapus dan
# membuat aplikasi crash hanya ketika iklan nyata berhasil dimuat. Jaga kelas
# SDK iklan, plugin Flutter-nya, serta factory native milik aplikasi.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }
-keep class * implements io.flutter.plugins.googlemobileads.NativeAdFactory { *; }

# Kelas milik aplikasi (MainActivity & FeedAdFactory) diakses dari manifest dan
# plugin, jaga agar tidak ter-obfuscate.
-keep class com.berandahukum.belajarhukum.** { *; }
