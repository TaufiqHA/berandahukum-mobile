import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_article_order_screen.dart';
import 'admin_ui.dart';

/// Pengaturan urutan sub-kategori di dalam satu kategori.
/// Ketuk sebuah sub-kategori untuk mengatur urutan artikelnya.
class AdminSubCategoryOrderScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  const AdminSubCategoryOrderScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  State<AdminSubCategoryOrderScreen> createState() => _AdminSubCategoryOrderScreenState();
}

class _AdminSubCategoryOrderScreenState extends State<AdminSubCategoryOrderScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await AdminApi.subCategories();
    final all = ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final rows = all.where((r) => r['category_id'] == widget.categoryId).toList();
    _rows = List.of(rows);
    return rows;
  }

  Future<void> _reload() async {
    setState(() { _future = _load(); });
    await _future;
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _rows.removeAt(oldIndex);
      _rows.insert(newIndex, item);
    });
    try {
      await AdminApi.saveSubCategoryOrder(_rows.map((r) => r['id'] as int).toList());
      if (mounted) adminSnack(context, 'Urutan sub kategori disimpan.');
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
      await _reload();
    }
  }

  void _openArticles(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminArticleOrderScreen(
          subCategoryId: row['id'] as int,
          subCategoryName: row['name'].toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName, style: const TextStyle(fontFamily: 'serif'))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const AdminLoading();
          if (snap.hasError) return AdminErrorView(message: snap.error.toString(), onRetry: _reload);
          if (_rows.isEmpty) return const AdminEmpty(message: 'Belum ada sub-kategori pada kategori ini.');
          return Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppTheme.tint,
              child: const Text(
                'Seret ikon di kanan untuk mengubah urutan sub-kategori. Ketuk sub-kategori untuk mengatur urutan artikel.',
                style: TextStyle(fontSize: 12, color: AppTheme.ink600),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.brand,
                onRefresh: _reload,
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: _rows.length,
                  // ignore: deprecated_member_use
                  onReorder: _onReorder,
                  itemBuilder: (context, i) {
                    final row = _rows[i];
                    final showOn = row['show'] == true;
                    return ListTile(
                      key: ValueKey(row['id']),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _openArticles(row),
                      leading: Text('${i + 1}',
                          style: const TextStyle(
                              fontFamily: 'serif', fontWeight: FontWeight.w700, color: AppTheme.brand, fontSize: 17)),
                      title: Text(row['name'].toString(),
                          style: const TextStyle(fontFamily: 'serif', fontSize: 15.5, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                      subtitle: Text(
                        '${showOn ? 'Tampil' : 'Disembunyikan'} · ketuk: urut artikel',
                        style: TextStyle(fontSize: 12, color: showOn ? AppTheme.ink500 : AppTheme.brand),
                      ),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.format_list_numbered, size: 20, color: AppTheme.ink500),
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                              padding: EdgeInsets.only(left: 8), child: Icon(Icons.drag_handle, color: AppTheme.ink500)),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
