import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:berandahukum_mobile/main.dart';
import 'package:berandahukum_mobile/state/admin_auth.dart';
import 'package:berandahukum_mobile/state/bookmarks.dart';

void main() {
  testWidgets('start-up tanpa jaringan tidak melontarkan exception', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('id');
    tester.binding.platformDispatcher.localesTestValue = const [Locale('id')];
    addTearDown(() {
      tester.binding.platformDispatcher.clearLocaleTestValue();
      tester.binding.platformDispatcher.clearLocalesTestValue();
    });

    SharedPreferences.setMockInitialValues({});
    final bookmarks = Bookmarks();
    final adminAuth = AdminAuth();
    await bookmarks.load();
    await adminAuth.load();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<Bookmarks>.value(value: bookmarks),
        ChangeNotifierProvider<AdminAuth>.value(value: adminAuth),
      ],
      child: const BerandaHukumApp(),
    ));

    await tester.pump(const Duration(seconds: 1));

    final ex = tester.takeException();
    expect(ex, isNull, reason: 'Exception saat start-up: $ex');
  });
}
