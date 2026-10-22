import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;

import 'package:belajarhukum/core/html_utils.dart';

void main() {
  test('removes fixed height from style and attributes', () {
    const input =
        '<table style="border-collapse: collapse; width: 100%; height: 44.7916px; background-color: #bfedd2;" border="1">'
        '<tr style="height: 22.3958px;"><td style="width: 99.3%; height: 22.3958px;">'
        '<h3 style="line-height: 1.2; font-size: 32px !important;">Judul</h3>'
        '</td></tr></table><img src="x" height="100" /><p style="max-height: 5px">A</p>';

    final out = sanitizeCmsHtml(input);

    expect(out.contains('height: 44.7916px'), isFalse);
    expect(out.contains('height: 22.3958px'), isFalse);
    expect(out.contains('height="100"'), isFalse);
    expect(out.contains('max-height: 5px'), isFalse);
    // Must not touch line-height, min-height, width or other styling.
    expect(out.contains('line-height: 1.2'), isTrue);
    expect(out.contains('width: 100%'), isTrue);
    expect(out.contains('font-size: 32px !important'), isTrue);
  });

  test('handles null and empty input', () {
    expect(sanitizeCmsHtml(null), '');
    expect(sanitizeCmsHtml(''), '');
  });

  group('internalArticleUri', () {
    const base = 'https://taufiqha.online';

    test('resolves relative links from TinyMCE', () {
      expect(
        internalArticleUri('../../../a/judul-artikel', baseUrl: base),
        'judul-artikel',
      );
      expect(
        internalArticleUri('/a/judul-artikel', baseUrl: base),
        'judul-artikel',
      );
      expect(
        internalArticleUri('a/judul-artikel', baseUrl: base),
        'judul-artikel',
      );
      expect(
        internalArticleUri('/article/judul-artikel', baseUrl: base),
        'judul-artikel',
      );
    });

    test('accepts absolute links on the same host', () {
      expect(
        internalArticleUri('$base/a/judul-artikel', baseUrl: base),
        'judul-artikel',
      );
    });

    test('rejects anchors, external links and other paths', () {
      expect(internalArticleUri('#bagian', baseUrl: base), isNull);
      expect(
        internalArticleUri('https://other.com/a/judul', baseUrl: base),
        isNull,
      );
      expect(
        internalArticleUri('https://other.com/berita', baseUrl: base),
        isNull,
      );
      expect(internalArticleUri('/kategori/hukum', baseUrl: base), isNull);
      expect(internalArticleUri('', baseUrl: base), isNull);
    });
  });

  group('highlightCmsHits', () {
    test('menyorot semua kecocokan tanpa membedakan huruf besar/kecil', () {
      final result = highlightCmsHits('<p>Hukum dan hukum.</p>', 'hukum');

      expect(result.count, 2);
      final marks = html_parser
          .parseFragment(result.html)
          .querySelectorAll('mark');
      expect(marks, hasLength(2));
      expect(marks[0].attributes['id'], 'cms-hit-0');
      expect(marks[1].attributes['id'], 'cms-hit-1');
      expect(marks[0].text, 'Hukum');
      expect(marks[1].text, 'hukum');
    });

    test('hanya hasil aktif yang diberi data-active', () {
      final result = highlightCmsHits(
        '<p>pasal satu, pasal dua</p>',
        'pasal',
        activeIndex: 1,
      );

      expect(result.count, 2);
      final marks = html_parser
          .parseFragment(result.html)
          .querySelectorAll('mark');
      expect(marks[0].attributes.containsKey('data-active'), isFalse);
      expect(marks[1].attributes['data-active'], '1');
      expect(marks[1].attributes['style'], contains('#c1121f'));
    });

    test('aman untuk karakter khusus regex', () {
      final result = highlightCmsHits('<p>Pasal (1) dan 1.2</p>', '(1)');

      expect(result.count, 1);
      expect(
        html_parser
            .parseFragment(result.html)
            .querySelectorAll('mark')
            .single
            .text,
        '(1)',
      );
    });

    test('mengabaikan isi script/style dan kata kosong', () {
      final result = highlightCmsHits(
        '<script>var hukum = 1;</script><style>.hukum {}</style><p>hukum</p>',
        'hukum',
      );

      expect(result.count, 1);
      expect(highlightCmsHits('<p>hukum</p>', '   ').count, 0);
      expect(highlightCmsHits(null, 'hukum').html, '');
    });
  });
}
