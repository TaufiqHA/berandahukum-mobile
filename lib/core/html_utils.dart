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
