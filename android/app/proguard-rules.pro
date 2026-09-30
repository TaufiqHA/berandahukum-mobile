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
