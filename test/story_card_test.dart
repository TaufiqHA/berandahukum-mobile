import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berandahukum_mobile/models/models.dart';
import 'package:berandahukum_mobile/widgets/widgets.dart';

void main() {
  testWidgets('StoryCard compact menampilkan judul + tanggal tanpa thumbnail', (tester) async {
    final a = Article(
      id: 1,
      uri: 'artikel',
      title: 'Kumpulan Materi Teori Hukum',
      image: 'uploads/img/contoh.jpg',
      date: '2026-09-24T00:00:00Z',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StoryCard(a: a, compact: true, onTap: () {})),
    ));

    expect(find.text('Kumpulan Materi Teori Hukum'), findsOneWidget);
    expect(find.text('24 September 2026'), findsOneWidget);
    expect(find.byType(MagazineImage), findsNothing);
  });
}
