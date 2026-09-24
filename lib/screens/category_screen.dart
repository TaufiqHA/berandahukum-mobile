import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/widgets.dart';
import 'home_screen.dart' show openArticle;

/// Daftar seluruh kategori (dengan sub-kategori).
class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});
  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late Future<List<Category>> _future;
  @override
  void initState() {
    super.initState();
    _future = Api.categories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori', style: TextStyle(fontFamily: 'serif'))),
      body: FutureBuilder<List<Category>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.brand));
          }
          if (snap.hasError) return Center(child: Text(snap.error.toString()));
          // Seperti versi web: sembunyikan kategori placeholder yang hanya
          // punya 0-1 sub-kategori (mis. "Kategori Hide", "Jangan Publikasi").
          final cats = snap.data!.where((c) => c.subs.length > 1).toList();
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 700
                      ? 3
                      : 2;
              final cols = _distribute(cats, columns);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < cols[c].length; i++) ...[
                              _categoryColumn(context, cols[c][i]),
                              if (i != cols[c].length - 1) const SizedBox(height: 28),
                            ],
                          ],
                        ),
                      ),
                      if (c != columns - 1) const SizedBox(width: 20),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Bagi kategori ke beberapa kolom dan seimbangkan tingginya agar tidak ada
  /// ruang kosong panjang di bawah kolom yang pendek.
  List<List<Category>> _distribute(List<Category> cats, int columns) {
    final cols = List.generate(columns, (_) => <Category>[]);
    // Perkiraan tinggi tiap blok: judul + jumlah sub-kategori.
    final heights = [for (final c in cats) 34 + c.subs.length * 38];
    final totals = List.filled(columns, 0);
    for (var i = 0; i < cats.length; i++) {
      var shortest = 0;
      for (var c = 1; c < columns; c++) {
        if (totals[c] < totals[shortest]) shortest = c;
      }
      cols[shortest].add(cats[i]);
      totals[shortest] += heights[i];
    }
    return cols;
  }

  void _open(BuildContext context, String name, String uri, String kind) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(name: name, uri: uri, kind: kind)));
  }

  Widget _categoryColumn(BuildContext context, Category c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _open(context, c.name, c.uri, 'categories'),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              c.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .8, fontSize: 12, color: AppTheme.ink, height: 1.2),
            ),
          ),
        ),
        for (final s in c.subs)
          InkWell(
            onTap: () => _open(context, s.name, s.uri, 'subcategories'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.line)),
              ),
              child: Text(
                s.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppTheme.ink600, height: 1.2),
              ),
            ),
          ),
      ],
    );
  }
}

/// Daftar artikel untuk sebuah kategori/sub-kategori/label (dengan paginasi).
class CategoryDetailScreen extends StatefulWidget {
  final String name;
  final String uri;
  final String kind; // categories | subcategories | labels
  const CategoryDetailScreen({super.key, required this.name, required this.uri, this.kind = 'categories'});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final _items = <Article>[];
  final _scroll = ScrollController();
  int _page = 1;
  int _lastPage = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
  }

  Future<void> _loadMore() async {
    if (_loading || _page > _lastPage) return;
    setState(() => _loading = true);
    try {
      final p = await Api.taxonomyArticles(widget.kind, widget.uri, _page);
      setState(() {
        _items.addAll(p.data);
        _lastPage = p.lastPage;
        _page++;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'serif'))),
      body: _items.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
          : _items.isEmpty && _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  itemCount: _items.length + (_page <= _lastPage ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= _items.length) {
                      return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: AppTheme.brand)));
                    }
                    final a = _items[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: StoryCard(a: a, onTap: () => openArticle(context, a)),
                    );
                  },
                ),
    );
  }
}
