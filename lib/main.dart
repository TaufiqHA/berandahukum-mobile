import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/home_screen.dart';
import 'screens/questions_screen.dart';
import 'screens/search_screen.dart';
import 'state/admin_auth.dart';
import 'state/bookmarks.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tampilkan pesan kesalahan alih-alih layar putih bila ada error render.
  ErrorWidget.builder = (details) => Container(
        color: Colors.white,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          'Terjadi kesalahan:\n\n${details.exceptionAsString()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      );

  final bookmarks = Bookmarks();
  final adminAuth = AdminAuth();

  // Inisialisasi penyimpanan lokal tidak boleh menggagalkan start-up.
  try {
    await Future.wait([bookmarks.load(), adminAuth.load()]).timeout(const Duration(seconds: 6));
  } catch (e, s) {
    debugPrint('Inisialisasi lokal gagal: $e\n$s');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Bookmarks>.value(value: bookmarks),
        ChangeNotifierProvider<AdminAuth>.value(value: adminAuth),
      ],
      child: const BerandaHukumApp(),
    ),
  );
}

class BerandaHukumApp extends StatelessWidget {
  const BerandaHukumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beranda Hukum',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id'), Locale('en')],
      theme: AppTheme.light(),
      home: const RootShell(),
    );
  }
}

/// Memungkinkan daftar/karousel digeser dengan mouse/trackpad (desktop & web),
/// bukan hanya sentuhan.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    SearchScreen(),
    QuestionsScreen(),
    BookmarksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.search), activeIcon: Icon(Icons.search), label: 'Cari'),
            BottomNavigationBarItem(icon: Icon(Icons.help_outline), activeIcon: Icon(Icons.help), label: 'Tanya'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), activeIcon: Icon(Icons.bookmark), label: 'Disimpan'),
          ],
        ),
      ),
    );
  }
}
