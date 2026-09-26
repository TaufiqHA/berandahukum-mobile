import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_ui.dart';

/// Pengaturan urutan artikel terbit di dalam sebuah sub-kategori.
class AdminArticleOrderScreen extends StatefulWidget {
  final int subCategoryId;
  final String subCategoryName;
  const AdminArticleOrderScreen({super.key, required this.subCategoryId, required this.subCategoryName});

  @override
  State<AdminArticleOrderScreen> createState() => _AdminArticleOrderScreenState();
}

class _AdminArticleOrderScreenState extends State<AdminArticleOrderScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await AdminApi.subCategoryArticles(widget.subCategoryId);
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
      await AdminApi.saveSubCategoryArticleOrder(
          widget.subCategoryId, _rows.map((r) => r['id'] as int).toList());
      if (mounted) adminSnack(context, 'Urutan artikel disimpan.');
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subCategoryName, style: const TextStyle(fontFamily: 'serif'))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const AdminLoading();
          if (snap.hasError) return AdminErrorView(message: snap.error.toString(), onRetry: _reload);
          if (_rows.isEmpty) {
            return const AdminEmpty(message: 'Belum ada artikel terbit pada sub-kategori ini.');
          }
          return Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppTheme.tint,
              child: const Text('Seret ikon di kanan untuk mengubah urutan artikel.',
                  style: TextStyle(fontSize: 12, color: AppTheme.ink600)),
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
                    return ListTile(
                      key: ValueKey(row['id']),
                      contentPadding: EdgeInsets.zero,
                      leading: Text('${i + 1}',
                          style: const TextStyle(
                              fontFamily: 'serif', fontWeight: FontWeight.w700, color: AppTheme.brand, fontSize: 17)),
                      title: Text(row['title'].toString(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                      subtitle: Text('${row['date'] ?? ''}',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.ink500)),
                      trailing: ReorderableDragStartListener(
                        index: i,
                        child: const Icon(Icons.drag_handle, color: AppTheme.ink500),
                      ),
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
