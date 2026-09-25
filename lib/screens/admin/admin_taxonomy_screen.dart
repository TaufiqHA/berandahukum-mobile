import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/admin_api.dart';
import 'admin_ui.dart';

enum TaxonomyKind { label, category, subCategory }

class AdminTaxonomyScreen extends StatefulWidget {
  final TaxonomyKind kind;
  const AdminTaxonomyScreen({super.key, required this.kind});

  @override
  State<AdminTaxonomyScreen> createState() => _AdminTaxonomyScreenState();
}

class _AdminTaxonomyScreenState extends State<AdminTaxonomyScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  List<Map<String, dynamic>> _categories = const [];

  String get _title => switch (widget.kind) {
        TaxonomyKind.label => 'Label',
        TaxonomyKind.category => 'Kategori',
        TaxonomyKind.subCategory => 'Sub Kategori',
      };

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (widget.kind == TaxonomyKind.subCategory) {
      final cats = await AdminApi.categories();
      _categories = ((cats['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
      final res = await AdminApi.subCategories();
      return ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
    }
    final res = widget.kind == TaxonomyKind.label ? await AdminApi.labels() : await AdminApi.categories();
    return ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<void> _reload() async {
    setState(() { _future = _load(); });
    await _future;
  }

  Future<void> _remove(Map<String, dynamic> row) async {
    if (!await adminConfirm(context, 'Hapus $_title "${row['name']}"?')) return;
    try {
      final id = row['id'] as int;
      if (widget.kind == TaxonomyKind.label) {
        await AdminApi.deleteLabel(id);
      } else if (widget.kind == TaxonomyKind.category) {
        await AdminApi.deleteCategory(id);
      } else {
        await AdminApi.deleteSubCategory(id);
      }
      if (mounted) adminSnack(context, '$_title dihapus.');
      await _reload();
    } catch (e) {
      if (mounted) adminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: row?['name']?.toString() ?? '');
    var show = row?['show'] as bool? ?? true;
    var urutan = TextEditingController(text: '${row?['urutan'] ?? 0}');
    int? categoryId = row?['category_id'] as int? ?? (_categories.isNotEmpty ? _categories.first['id'] as int : null);

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text('${row == null ? 'Tambah' : 'Ubah'} $_title',
              style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.kind == TaxonomyKind.subCategory)
                AdminField(
                  label: 'Kategori',
                  child: DropdownButtonFormField<int>(
                    initialValue: categoryId,
                    isExpanded: true,
                    decoration: adminInputDecoration(),
                    items: [
                      for (final c in _categories) DropdownMenuItem(value: c['id'] as int, child: Text(c['name'].toString())),
                    ],
                    onChanged: (v) => setDialog(() => categoryId = v),
                  ),
                ),
              AdminField(label: 'Nama', child: TextField(controller: name, decoration: adminInputDecoration())),
              if (widget.kind != TaxonomyKind.category)
                AdminField(label: 'Urutan', child: TextField(controller: urutan, keyboardType: TextInputType.number, decoration: adminInputDecoration())),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tampilkan', style: TextStyle(fontSize: 14)),
                value: show,
                activeThumbColor: AppTheme.brand,
                onChanged: (v) => setDialog(() => show = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                try {
                  final id = row?['id'] as int?;
                  if (name.text.trim().isEmpty) return;
                  if (widget.kind == TaxonomyKind.label) {
                    await AdminApi.saveLabel(id: id, name: name.text.trim(), show: show, urutan: int.tryParse(urutan.text) ?? 0);
                  } else if (widget.kind == TaxonomyKind.category) {
                    await AdminApi.saveCategory(id: id, name: name.text.trim(), show: show);
                  } else {
                    if (categoryId == null) return;
                    await AdminApi.saveSubCategory(id: id, categoryId: categoryId!, name: name.text.trim(), show: show);
                  }
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (context.mounted) adminSnack(context, e.toString(), error: true);
                }
              },
              child: const Text('SIMPAN'),
            ),
          ],
        ),
      ),
    );
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
          final rows = snap.data!;
          if (rows.isEmpty) return const AdminEmpty();
          return RefreshIndicator(
            color: AppTheme.brand,
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final row = rows[i];
                final showOn = row['show'] == true;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(row['name'].toString(),
                      style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                  subtitle: Text(
                    [
                      if (widget.kind == TaxonomyKind.subCategory) row['category_name']?.toString() ?? '-',
                      showOn ? 'Tampil' : 'Disembunyikan',
                      if (widget.kind != TaxonomyKind.category && row['urutan'] != null) 'urutan ${row['urutan']}',
                    ].join(' · '),
                    style: TextStyle(fontSize: 12, color: showOn ? AppTheme.ink500 : AppTheme.brand),
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _openForm(row)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.brand), onPressed: () => _remove(row)),
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
