import 'package:flutter_test/flutter_test.dart';

import 'package:berandahukum_mobile/core/html_utils.dart';

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
}
