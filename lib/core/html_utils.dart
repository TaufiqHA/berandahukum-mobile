/// Utilitas untuk membersihkan HTML dari CMS sebelum dirender dengan
/// `flutter_widget_from_html`.
///
/// Editor CMS (TinyMCE) menyimpan artikel sebagai tabel dengan ukuran tetap
/// dalam piksel, misalnya `height: 44.79px` dan `width: 1641.27px`. Nilai
/// tersebut mengikuti ukuran saat dibuat sehingga merusak tata letak di layar
/// ponsel (overflow vertikal dan kolom yang sangat lebar).
///
/// Selain itu, renderer Flutter membagi lebar sel yang memakai `colspan`
/// secara merata ke seluruh kolom yang dicakupnya. Untuk baris teks panjang
/// (mis. "a. pemeriksaan Tersangka;") hal ini melebarkan kolom penanda
/// (`(1)`, `a.`) sehingga tampilan jadi berantakan, berbeda dengan website.
///
/// Untuk itu HTML dinormalkan:
///  * tinggi tetap dibuang dari semua elemen;
///  * tabel "tata letak" (tanpa `<th>`) dirapikan: sel kosong di ujung dibuang,
///    `colspan` diset 1, dan baris berisi satu sel penuh (judul/pasal)
///    dikeluarkan dari tabel menjadi blok biasa.
library;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// `height`/`max-height`/`min-height` di dalam atribut `style`. Negative
/// lookbehind mencegah `line-height` ikut terhapus.
final RegExp _heightInStyle = RegExp(
  r'''(?<![\w-])(?:max-|min-)?height\s*:\s*[^;"']+;?''',
  caseSensitive: false,
);

/// `width`/`max-width`/`min-width` di dalam atribut `style`.
final RegExp _widthInStyle = RegExp(
  r'''(?<![\w-])(?:max-|min-)?width\s*:\s*[^;"']+;?''',
  caseSensitive: false,
);

/// Tag tabel yang lebar kolomnya harus dilepas agar menyesuaikan layar.
const _tableTags = {
  'table',
  'thead',
  'tbody',
  'tfoot',
  'tr',
  'td',
  'th',
  'col',
  'colgroup',
};

/// Mengembalikan HTML yang siap dirender: ukuran tetap dibuang dan tabel tata
/// letak dinormalkan agar tidak berantakan di layar kecil.
String sanitizeCmsHtml(String? html) {
  if (html == null || html.isEmpty) return '';

  final fragment = html_parser.parseFragment(html);
  _normalizeLayoutTables(fragment);
  for (final element in fragment.querySelectorAll('*')) {
    _stripFixedSize(element);
  }
  return fragment.outerHtml;
}

/// Rapikan tabel tata letak (tanpa `<th>`) agar kolom penanda tetap sempit.
void _normalizeLayoutTables(dom.DocumentFragment fragment) {
  final tables = fragment
      .querySelectorAll('table')
      .where((t) => t.querySelector('th') == null)
      .toList();

  for (final table in tables.reversed) {
    if (_closestTable(table.parent) != null) continue; // biarkan tabel bersarang
    _normalizeTable(table);
  }
}

void _normalizeTable(dom.Element table) {
  final replacement = dom.DocumentFragment();
  final pendingRows = <dom.Element>[];

  void flushRows() {
    if (pendingRows.isEmpty) return;
    final newTable = dom.Element.tag('table');
    final tbody = dom.Element.tag('tbody');
    for (final tr in pendingRows) {
      tbody.nodes.add(tr);
    }
    newTable.nodes.add(tbody);
    replacement.nodes.add(newTable);
    pendingRows.clear();
  }

  for (final tr in table.querySelectorAll('tr')) {
    if (_closestTable(tr) != table) continue; // baris milik tabel bersarang

    final cells = tr.children
        .where((e) => e.localName == 'td' || e.localName == 'th')
        .toList();

    // Buang sel kosong di awal/akhir (kolom penjaga dari TinyMCE).
    while (cells.isNotEmpty && _isBlankCell(cells.first)) {
      cells.removeAt(0);
    }
    while (cells.isNotEmpty && _isBlankCell(cells.last)) {
      cells.removeLast();
    }
    if (cells.isEmpty) continue;

    if (cells.length == 1) {
      // Baris satu sel penuh (judul/pasal): jadikan blok biasa agar teksnya
      // bisa memakai lebar penuh dan tetap terpusat.
      flushRows();
      for (final node in cells.first.nodes.toList()) {
        replacement.nodes.add(node.clone(true));
      }
    } else {
      tr.nodes
        ..clear()
        ..addAll(cells);
      for (final cell in cells) {
        cell.attributes['colspan'] = '1';
      }
      pendingRows.add(tr);
    }
  }
  flushRows();

  table.replaceWith(replacement);
}

bool _isBlankCell(dom.Element cell) =>
    cell.text.replaceAll('\u00a0', ' ').trim().isEmpty;

dom.Element? _closestTable(dom.Node? node) {
  for (var n = node; n != null; n = n.parent) {
    if (n is dom.Element && n.localName == 'table') return n;
  }
  return null;
}

void _stripFixedSize(dom.Element element) {
  final isTable = _tableTags.contains(element.localName);

  // Atribut `height="…"` selalu dibuang; `width="…"` hanya pada tabel.
  element.attributes.remove('height');
  if (isTable) {
    element.attributes.remove('width');
  }

  final style = element.attributes['style'];
  if (style == null || style.isEmpty) return;

  var next = style.replaceAll(_heightInStyle, '');
  if (isTable) {
    next = next.replaceAll(_widthInStyle, '');
  }
  next = _tidyStyle(next);

  if (next == style) return;
  if (next.isEmpty) {
    element.attributes.remove('style');
  } else {
    element.attributes['style'] = next;
  }
}

/// Rapikan sisa `;` ganda atau `;` di ujung setelah deklarasi dibuang.
String _tidyStyle(String style) {
  var s = style.replaceAll(RegExp(r';\s*;'), ';').trim();
  while (s.startsWith(';')) {
    s = s.substring(1).trim();
  }
  while (s.endsWith(';')) {
    s = s.substring(0, s.length - 1).trim();
  }
  return s;
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
