import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berandahukum_mobile/widgets/cms_html.dart';

void main() {
  testWidgets('mengetuk tautan artikel internal memanggil onArticle', (tester) async {
    String? tapped;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CmsHtml(
          '<p><a href="../../../a/judul-artikel">artikel ini</a></p>',
          onArticle: (uri) => tapped = uri,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tapOnText(find.textRange.ofSubstring('artikel ini'));
    await tester.pumpAndSettle();

    expect(tapped, 'judul-artikel');
  });
}
