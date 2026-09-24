import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/hero_slider.dart';
import '../widgets/widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(children: [
          Image.asset('assets/logo.png', height: 30, errorBuilder: (_, _, _) => const Text('BERANDA HUKUM', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700))),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.brand, height: 3),
        ),
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
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
              children: [
                // Banner full-bleed: gambar menyentuh tepi, teks tetap di margin.
                HeroSlider(items: data.slider, onTap: (a) => openArticle(context, a), inset: 20),
                const SizedBox(height: 28),
                _pad(const SectionHeader(number: '01', title: 'Terbaru')),
                _pad(_grid(context, data.latest)),
                const SizedBox(height: 28),
                if (data.headline.isNotEmpty) ...[
                  _pad(const SectionHeader(number: '02', title: 'Headline')),
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: data.headline.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => SizedBox(width: 260, child: StoryCard(a: data.headline[i], onTap: () => openArticle(context, data.headline[i]))),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                if ([...data.pilihanAtas, ...data.pilihanBawah].isNotEmpty) ...[
                  _pad(const SectionHeader(number: '03', title: 'Pilihan Editor')),
                  _pad(_grid(context, [...data.pilihanAtas, ...data.pilihanBawah])),
                  const SizedBox(height: 28),
                ],
                _pad(const SectionHeader(title: 'Jelajahi Kategori')),
                _pad(Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.categories
                      .map((c) => ActionChip(
                            backgroundColor: AppTheme.tint,
                            side: BorderSide.none,
                            label: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(name: c.name, uri: c.uri))),
                          ))
                      .toList(),
                )),
                const SizedBox(height: 28),
                if (data.labels.isNotEmpty) ...[
                  _pad(const SectionHeader(title: 'Label')),
                  _pad(Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.labels
                        .where((l) => l.count > 0)
                        .map((l) => ActionChip(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppTheme.line),
                              label: Text('${l.name} (${l.count})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(name: l.name, uri: l.uri, kind: 'labels'))),
                            ))
                        .toList(),
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Padding horizontal standar agar konten sejajar, dipakai saat ListView
  /// tidak lagi memakai padding horizontal (agar hero bisa full width).
  Widget _pad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);

  Widget _grid(BuildContext context, List<Article> items) {
    if (items.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Belum ada artikel.', style: TextStyle(color: AppTheme.ink500)));
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: StoryCard(a: items[i], onTap: () => openArticle(context, items[i]))),
              const SizedBox(width: 16),
              Expanded(
                child: i + 1 < items.length
                    ? StoryCard(a: items[i + 1], onTap: () => openArticle(context, items[i + 1]))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }
}
