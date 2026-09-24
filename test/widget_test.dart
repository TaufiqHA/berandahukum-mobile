import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:berandahukum_mobile/core/theme.dart';

void main() {
  testWidgets('Tema aplikasi dapat dipakai untuk me-render widget dasar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Text('Beranda Hukum')),
      ),
    );
    expect(find.text('Beranda Hukum'), findsOneWidget);
  });
}
