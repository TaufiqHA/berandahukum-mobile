import 'package:flutter_test/flutter_test.dart';

import 'package:berandahukum_mobile/widgets/site_widgets.dart';

void main() {
  test('articleUri mengekstrak uri artikel dari tautan banner', () {
    expect(AdBannerView.articleUri('https://berandahukum.com/a/Pengantar-Ilmu-Hukum'), 'Pengantar-Ilmu-Hukum');
    expect(
      AdBannerView.articleUri('http://localhost:8000/a/Kumpulan-Yurisprudensi-Mahkamah-Agung'),
      'Kumpulan-Yurisprudensi-Mahkamah-Agung',
    );
    expect(AdBannerView.articleUri('https://berandahukum.com/article/foo'), 'foo');
    expect(AdBannerView.articleUri('https://example.com/promo'), isNull);
    expect(AdBannerView.articleUri(null), isNull);
  });
}
