import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_ui.dart';

/// Pengaturan artikel slider/sorotan beranda (tbl_pilihan posisi "top").
class AdminSliderScreen extends StatefulWidget {
  const AdminSliderScreen({super.key});
  @override
  State<AdminSliderScreen> createState() => _AdminSliderScreenState();
}

class _AdminSliderScreenState extends State<AdminSliderScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await AdminApi.slider();
    final rows = ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
    _rows = List.of(rows);
    return rows;
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _remove(Map<String, dynamic> row) async {
    if (!await adminConfirm(context, 'Hapus "${row['title']}" dari slider?')) return;
    try {
      await AdminApi.deleteSlider(row['id'] as int);
      if (mounted) adminSnack(context, 'Artikel dihapus dari slider.');
      await _reload();
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _rows.removeAt(oldIndex);
      _rows.insert(newIndex, item);
    });
    try {
      await AdminApi.saveSliderOrder(_rows.map((r) => r['id'] as int).toList());
      if (mounted) adminSnack(context, 'Urutan slider disimpan.');
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
      await _reload();
    }
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final search = TextEditingController();
    int? articleId = row?['article_id'] as int?;
    String? selectedTitle = row?['title'] as String?;
    var results = <Map<String, dynamic>>[];
    var searching = false;
    Timer? debounce;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) {
          void doSearch(String value) {
            debounce?.cancel();
            debounce = Timer(const Duration(milliseconds: 350), () async {
              setDialog(() => searching = true);
              try {
                final r = await AdminApi.sliderArticles(value.trim());
                setDialog(() {
                  results = r;
                  searching = false;
                });
              } catch (_) {
                setDialog(() => searching = false);
              }
            });
          }

          return AlertDialog(
            title: Text(row == null ? 'Tambah Artikel Slider' : 'Ubah Artikel Slider',
                style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 18)),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  AdminField(
                    label: 'Cari Artikel',
                    child: TextField(
                      controller: search,
                      onChanged: doSearch,
                      decoration: adminInputDecoration('Ketik judul artikel…'),
                    ),
                  ),
                  if (selectedTitle != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppTheme.tint, border: Border.all(color: AppTheme.line)),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: AppTheme.brand, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(selectedTitle!,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink))),
                      ]),
                    ),
                  if (searching)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator(color: AppTheme.brand)),
                  for (final r in results)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(r['title'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                      onTap: () => setDialog(() {
                        articleId = r['id'] as int;
                        selectedTitle = r['title'].toString();
                      }),
                    ),
                  if (results.isEmpty && !searching && search.text.trim().length >= 2)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Tidak ada artikel.', style: TextStyle(color: AppTheme.ink500))),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              FilledButton(
                onPressed: () async {
                  if (articleId == null) return;
                  try {
                    await AdminApi.saveSlider(id: row?['id'] as int?, articleId: articleId!);
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (context.mounted) adminSnack(context, e.toString(), error: true);
                  }
                },
                child: const Text('SIMPAN'),
              ),
            ],
          );
        },
      ),
    );

    debounce?.cancel();
    search.dispose();
    if (saved == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const AdminLoading();
          if (snap.hasError) return AdminErrorView(message: snap.error.toString(), onRetry: _reload);
          if (_rows.isEmpty) {
            return const AdminEmpty(message: 'Belum ada artikel di slider.\nTekan tombol + untuk menambah.');
          }
          return Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppTheme.tint,
              child: const Text('Seret ikon di kanan untuk mengubah urutan slider.',
                  style: TextStyle(fontSize: 12, color: AppTheme.ink600)),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: _rows.length,
                // ignore: deprecated_member_use
                onReorder: _onReorder,
                itemBuilder: (context, i) {
                  final row = _rows[i];
                  return ListTile(
                    key: ValueKey(row['id']),
                    contentPadding: EdgeInsets.zero,
                    leading: Text('${i + 1}',
                        style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, color: AppTheme.brand, fontSize: 17)),
                    title: Text(row['title'].toString(),
                        style: const TextStyle(fontFamily: 'serif', fontSize: 15.5, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openForm(row)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.brand), onPressed: () => _remove(row)),
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.drag_handle, color: AppTheme.ink500)),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}
