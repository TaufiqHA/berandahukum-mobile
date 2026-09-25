import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berandahukum_mobile/models/models.dart';
import 'package:berandahukum_mobile/widgets/hero_slider.dart';
import 'package:berandahukum_mobile/widgets/widgets.dart';

void main() {
  testWidgets('gambar hero mengisi lebar layar', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
          children: [
            HeroSlider(
              items: [Article(id: 1, uri: 'x', title: 'Judul', image: null)],
              onTap: (_) {},
              inset: 20,
            ),
          ],
        ),
      ),
    ));

    final size = tester.getSize(find.byType(MagazineImage));
    expect(size.width, 400);
  });

  testWidgets('caption slider tidak overflow untuk judul & penulis panjang', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HeroSlider(
          items: [
            Article(
              id: 1,
              uri: 'x',
              title: 'Perbedaan Hukum Pidana dan Hukum Perdata (Dari Sudut Hukum Bisnis)',
              author: 'Estimid FD Simatupang SH MH',
              image: null,
            ),
          ],
          onTap: (_) {},
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
  });
}
