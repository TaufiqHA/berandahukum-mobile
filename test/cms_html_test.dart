import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:belajarhukum/core/html_utils.dart';
import 'package:belajarhukum/widgets/cms_html.dart';

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

  testWidgets('hasil pencarian disorot dengan warna aktif dan biasa', (tester) async {
    final result = highlightCmsHits('<p>Hukum dan hukum.</p>', 'hukum');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CmsHtml(result.html)),
    ));
    await tester.pumpAndSettle();

    final highlights = <String, Color?>{};
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text != null && span.style?.background != null) {
          highlights[span.text!] = span.style!.background!.color;
        }
        return true;
      });
    }

    expect(highlights['Hukum']?.toARGB32(), 0xFFC1121F);
    expect(highlights['hukum']?.toARGB32(), 0xFFFDE68A);
  });
}
