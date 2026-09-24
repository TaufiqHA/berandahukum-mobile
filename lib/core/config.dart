/// Konfigurasi aplikasi.
/// Base URL bisa di-override saat build/run:
///   flutter run --dart-define=API_BASE=http://192.168.1.10:8000
class AppConfig {
  /// Host Laravel. Default 10.0.2.2 = localhost host dari Android emulator.
  static const String host = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://taufiqha.online',
  );

  static String get apiRoot => '$host/api/v1';

  /// URL absolut untuk media (path relatif dari API seperti "uploads/img/x.jpg").
  static String media(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$host/$path';
  }
}
