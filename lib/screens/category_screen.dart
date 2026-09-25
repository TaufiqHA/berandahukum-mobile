import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/widgets.dart';
import 'home_screen.dart' show openArticle;

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
