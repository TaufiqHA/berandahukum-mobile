import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/hero_slider.dart';
import '../widgets/site_widgets.dart';
import 'admin/admin_gate.dart';
import 'article_screen.dart';
import 'category_screen.dart';
import 'info_screen.dart';

void openArticle(BuildContext context, Article a) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleScreen(uri: a.uri, initialTitle: a.title)));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.home();
  }

  Future<void> _refresh() async {
    setState(() => _future = Api.home());
    await _future;
  }

  /// Buka artikel dari banner di dalam aplikasi (bukan browser).
  void _openAdArticle(String uri) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleScreen(uri: uri)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(children: [
          Image.asset('assets/logo.png', height: 30,
              errorBuilder: (_, _, _) => const Text('BERANDA HUKUM',
                  style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700))),
        ]),
        actions: [
          IconButton(
            tooltip: 'Panel Admin',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGate())),
          ),
          IconButton(
            tooltip: 'Informasi',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoListScreen())),
          ),
        ],
      ),
      body: FutureBuilder<HomeData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.brand));
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off, size: 40, color: AppTheme.ink500),
                  const SizedBox(height: 12),
                  Text(snap.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _refresh, child: const Text('COBA LAGI')),
                ]),
              ),
            );
          }
          final data = snap.data!;
          return RefreshIndicator(
            color: AppTheme.brand,
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Banner atas
                if (data.adsTop != null) ...[
                  const SizedBox(height: 14),
                  AdBannerView(ad: data.adsTop!, onArticle: _openAdArticle),
                  const SizedBox(height: 14),
                ],

                // Carousel sorotan (judul + penulis)
                HeroSlider(items: data.slider, onTap: (a) => openArticle(context, a)),

                // Pembatas #
                const HashDivider(),

                // Banner setelah pembatas # (mis. "Setidak-tidaknya ada …")
                if (data.adsMiddle != null) ...[
                  AdBannerView(ad: data.adsMiddle!, onArticle: _openAdArticle),
                  const SizedBox(height: 14),
                ],

                // Tile banner (mis. PENGANTAR ILMU HUKUM, dst.)
                for (final b in data.banners) ...[
                  AdBannerView(ad: b, onArticle: _openAdArticle),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 4),

                // Kartu kategori accordion
                CategoryAccordion(
                  categories: data.categories,
                  onCategory: (c) => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => CategoryDetailScreen(name: c.name, uri: c.uri))),
                  onSub: (c, s) => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => CategoryDetailScreen(name: s.name, uri: s.uri, kind: 'subcategories'))),
                ),

                // Iklan sebelum footer
                if (data.adsBottom != null) ...[
                  const SizedBox(height: 8),
                  AdBannerView(ad: data.adsBottom!, onArticle: _openAdArticle),
                ],

                // Footer situs
                SiteFooter(
                  onInfo: (id, name) => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => InfoDetailScreen(id: id, name: name))),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
