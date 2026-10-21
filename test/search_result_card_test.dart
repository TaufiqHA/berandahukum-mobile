import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:belajarhukum/models/models.dart';
import 'package:belajarhukum/widgets/widgets.dart';

void main() {
  testWidgets('SearchResultCard tanpa gambar dan menyorot kata kunci', (tester) async {
    final a = Article(
      id: 1,
      uri: 'putusan-1074',
      title: 'Harus ada kesepakatan harga bila jaminan tanah diganti',
      date: '2022-10-02T08:28:00Z',
      author: 'Admin',
      excerpt: 'No. 1074 K/PDT/1995 Tanggal 18 Mei 1996',
      excerptSegments: const [
        ExcerptSegment(text: 'No. '),
        ExcerptSegment(text: '1074', highlight: true),
        ExcerptSegment(text: ' K/PDT/1995 Tanggal 18 Mei 1996'),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SearchResultCard(a: a, onTap: () {})),
    ));

    expect(find.byType(MagazineImage), findsNothing);
    expect(find.text('Harus ada kesepakatan harga bila jaminan tanah diganti'), findsOneWidget);

    final rich = tester.widget<Text>(
      find.byWidgetPredicate((widget) => widget is Text && widget.textSpan != null),
    );
    final spans = (rich.textSpan as TextSpan).children!.cast<TextSpan>();

    expect(spans, hasLength(3));
    expect(spans[1].text, '1074');
    expect(spans[1].style?.backgroundColor, const Color(0xFFFDE68A));
  });
}
