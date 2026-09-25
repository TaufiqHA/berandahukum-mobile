/// Utilitas untuk membersihkan HTML dari CMS sebelum dirender dengan
/// `flutter_widget_from_html`.
///
/// Editor CMS (TinyMCE) sering menyimpan tinggi tetap dalam piksel pada
/// `<table>`/`<tr>`/`<td>`, misalnya `height: 44.79px`. Nilai tersebut
/// mengikuti tinggi konten *saat dibuat*, sehingga saat dibaca di layar
/// sempit konten jauh lebih tinggi daripada kotaknya. Akibatnya muncul
/// error "BOTTOM OVERFLOWED BY ... PIXELS" dan teks saling tumpang tindih.
///
/// Fungsi ini membuang deklarasi `height` / `max-height` (baik lewat
/// `style` maupun atribut) agar tinggi elemen mengikuti isinya.
library;

/// `height`/`max-height` di dalam atribut `style`. Negative lookbehind
/// mencegah `line-height` dan `min-height` ikut terhapus.
final RegExp _heightInStyle = RegExp(
  r'''(?<![\w-])(?:max-)?height\s*:\s*[^;"']+;?''',
  caseSensitive: false,
);

/// Atribut `height="…"` / `height='…'` pada tag HTML.
final RegExp _heightAttribute = RegExp(
  r'''\s+height\s*=\s*(?:"[^"]*"|'[^']*')''',
  caseSensitive: false,
);

/// Mengembalikan HTML tanpa tinggi tetap yang berpotensi menyebabkan overflow.
String sanitizeCmsHtml(String? html) {
  if (html == null || html.isEmpty) return '';
  return html
      .replaceAll(_heightInStyle, '')
      .replaceAll(_heightAttribute, '');
}

/// Mengambil URI artikel internal dari sebuah tautan di dalam konten CMS.
///
/// Tautan ke artikel lain bisa disimpan TinyMCE sebagai URL relatif
/// (mis. `../../../a/judul-artikel`) atau absolut ke host situs. Fungsi ini
/// menyelesaikan tautan relatif terhadap [baseUrl] lalu memeriksa apakah
/// path-nya berbentuk `/a/<uri>` atau `/article/<uri>`.
///
/// Mengembalikan `null` bila tautan bukan artikel internal: anchor (`#...`),
/// tautan eksternal, atau URL yang tidak bisa diurai.
String? internalArticleUri(String url, {String baseUrl = ''}) {
  final trimmed = url.trim();
  if (trimmed.isEmpty || trimmed.startsWith('#')) return null;

  var uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  final base = baseUrl.isEmpty ? null : Uri.tryParse(baseUrl);
  final baseHost = base?.host ?? '';

  if (!uri.hasScheme) {
    if (base == null) return null;
    uri = base.resolveUri(uri);
  }

  // Tautan absolut hanya dianggap internal bila host-nya sama dengan situs.
  if (uri.host.isNotEmpty && (baseHost.isEmpty || uri.host != baseHost)) {
    return null;
  }

  final segments = uri.pathSegments;
  if (segments.length >= 2 && (segments[0] == 'a' || segments[0] == 'article')) {
    return segments[1];
  }
  return null;
}
