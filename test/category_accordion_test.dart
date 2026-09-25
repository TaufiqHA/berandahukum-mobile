import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berandahukum_mobile/core/theme.dart';
import 'package:berandahukum_mobile/models/models.dart';
import 'package:berandahukum_mobile/widgets/site_widgets.dart';

void main() {
  testWidgets('kategori dapat di-expand untuk menampilkan sub-kategori', (tester) async {
    final categories = [
      Category(
        id: 1,
        name: 'Pengantar Ilmu Hukum',
        uri: 'pengantar-ilmu-hukum',
        subs: [
          Category(id: 2, name: 'Dasar-dasar Hukum', uri: 'dasar-dasar-hukum'),
        ],
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategoryAccordion(categories: categories, onArticle: (_) {}),
        ),
      ),
    ));

    // Kartu kategori memakai latar abu rokok cerah.
    expect(
      find.byWidgetPredicate((w) =>
          w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == AppTheme.ash),
      findsOneWidget,
    );

    // Tertutup secara default.
    expect(find.text('Dasar-dasar Hukum'), findsNothing);

    // Tap header kategori -> terbuka.
    await tester.tap(find.text('Pengantar Ilmu Hukum'));
    await tester.pumpAndSettle();
    expect(find.text('Dasar-dasar Hukum'), findsOneWidget);

    // Tap lagi -> tertutup.
    await tester.tap(find.text('Pengantar Ilmu Hukum'));
    await tester.pumpAndSettle();
    expect(find.text('Dasar-dasar Hukum'), findsNothing);
  });

  testWidgets('iklan disisipkan di antara kategori (bergilir)', (tester) async {
    final categories = [
      Category(id: 1, name: 'A', uri: 'a'),
      Category(id: 2, name: 'B', uri: 'b'),
      Category(id: 3, name: 'C', uri: 'c'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategoryAccordion(
            categories: categories,
            onArticle: (_) {},
            ads: [AdBanner(image: '')],
          ),
        ),
      ),
    ));

    // 3 kategori -> 2 celah -> 2 iklan, tidak ada iklan setelah kategori terakhir.
    expect(find.byType(AdBannerView), findsNWidgets(2));
  });

  testWidgets('iklan khusus hanya tampil setelah kategori yang dipilih', (tester) async {
    final categories = [
      Category(id: 11, name: 'A', uri: 'a'),
      Category(id: 22, name: 'B', uri: 'b'),
      Category(id: 33, name: 'C', uri: 'c'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategoryAccordion(
            categories: categories,
            onArticle: (_) {},
            ads: [AdBanner(image: '', categoryId: 22)],
          ),
        ),
      ),
    ));

    // Hanya satu iklan (setelah kategori B), bukan di setiap celah.
    expect(find.byType(AdBannerView), findsOneWidget);
  });
}
